import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/content_packs/content_pack.dart';
import '../../data/content_packs/keyboard_key_count.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cloud_mascot.dart';
import '../../services/user_service.dart';
import '../../services/tts_service.dart';
import '../../services/sound_service.dart';
import '../../services/progress/progress_repository.dart';

/// A localized instruction string can't live on a `const` [ContentPack]
/// (no `BuildContext` at compile time), so the mascot instruction is
/// derived from the stable `ContentPack.categoryId` at render time instead.
String _instructionFor(BuildContext context, String configId) {
  final t = AppLocalizations.of(context)!;
  switch (configId) {
    case 'numbers':
      return t.spellThisNumber;
    case 'colors':
      return t.spellThisColor;
    case 'fruits':
      return t.spellThisFruit;
    case 'animals':
      return t.spellThisAnimal;
    case 'food':
      return t.spellThisFood;
    default:
      return '';
  }
}

class GenericGameScreen extends StatefulWidget {
  const GenericGameScreen({super.key});

  @override
  State<GenericGameScreen> createState() => _GenericGameScreenState();
}

class _GenericGameScreenState extends State<GenericGameScreen> {
  ContentPack? _config;
  List<ContentItem> _questions = [];
  int _current = 0;

  /// Letters tapped so far for the current word (in order).
  List<String> _tapped = [];

  /// Letter tiles shown in the grid (size varies by progression stage).
  List<String> _grid = [];

  /// Grid tile currently flashing red (wrong tap).
  String? _flashWrong;

  bool _goodJobShown = false;
  final _rng = Random();

  // ─── Init ──────────────────────────────────────────────────────────────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_config == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is ContentPack) {
        _config = args;
        _initQuestions();
      }
    }
  }

  void _initQuestions() {
    final cfg = _config!;
    final count = cfg.questionCount.clamp(1, cfg.items.length);
    final list = orderItemsForSession(cfg, _rng);
    _questions = list.take(count).toList();
    _resetWord();
  }

  void _resetWord() {
    setState(() {
      _tapped = [];
      _flashWrong = null;
      _grid = _buildGrid(_questions[_current], _gridSize);
    });
    final capturedWord = _questions[_current].word;
    final locale = _config!.locale;
    Future.delayed(const Duration(milliseconds: 350), () {
      TtsService.instance.speak(capturedWord, locale: locale);
    });
  }

  // ─── Progressive difficulty ────────────────────────────────────────────────

  /// Grid tile count. When `_config!.answerDrivenKeyCount` is set
  /// (Russian's word categories), driven by the current answer's own
  /// unique-letter count via [keyCountFor] — see keyboard_key_count.dart
  /// for the exact mapping. Otherwise (every en/uz category, unchanged
  /// from before this existed): grows in three stages as the level
  /// progresses — first third → 6 tiles, middle third → 8, last third →
  /// 10 — clamped to be at least the current word's unique-letter count.
  int get _gridSize {
    final uniqueCount = _word.split('').toSet().length;
    if (_config!.answerDrivenKeyCount) return keyCountFor(uniqueCount);
    final total = _questions.length;
    final int target;
    if (_current < total ~/ 3) {
      target = 6;
    } else if (_current < (total * 2) ~/ 3) {
      target = 8;
    } else {
      target = 10;
    }
    return target.clamp(uniqueCount, 10);
  }

  /// [rng] is seeded from the item's own stable id when
  /// `answerDrivenKeyCount` is set, so the same item always shuffles the
  /// same way (a retry/relaunch shows the same board) — otherwise the
  /// screen's own shared, unseeded [_rng], unchanged from before this
  /// existed.
  List<String> _buildGrid(ContentItem item, int count) {
    final rng = _config!.answerDrivenKeyCount
        ? Random(stableHash(item.id))
        : _rng;
    final needed = item.word.split('').toSet().toList();
    final pool = _config!.alphabet.split('')..removeWhere(needed.contains);
    pool.shuffle(rng);
    final extras = pool.take((count - needed.length).clamp(0, 26)).toList();
    return ([...needed, ...extras]..shuffle(rng)).take(count).toList();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String get _word => _questions[_current].word;
  int get _letterIndex => _tapped.length;

  /// True when [letter] has been placed as many times as the word needs it.
  /// Distractor letters (needed == 0) are never "used up".
  bool _isUsedUp(String letter) {
    final needed = _word.split('').where((c) => c == letter).length;
    if (needed == 0) return false; // distractor — never mark green
    return _tapped.where((c) => c == letter).length >= needed;
  }

  // ─── Game logic ────────────────────────────────────────────────────────────

  void _onLetterTap(String letter) {
    if (_letterIndex >= _word.length) return;
    if (_isUsedUp(letter)) return;

    if (letter == _word[_letterIndex]) {
      UserService.recordAnswer(correct: true);
      SoundService.instance.playCorrect();
      final next = [..._tapped, letter];
      setState(() => _tapped = next);
      if (next.length >= _word.length) {
        TtsService.instance.speak(_word, locale: _config!.locale);
        Future.delayed(const Duration(milliseconds: 500), _advance);
      }
    } else {
      UserService.recordAnswer(correct: false);
      SoundService.instance.playWrong();
      setState(() => _flashWrong = letter);
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _flashWrong = null);
      });
    }
  }

  void _advance() {
    if (!mounted) return;
    final half = _questions.length ~/ 2;
    if (!_goodJobShown && _current == half - 1) {
      _goodJobShown = true;
      Navigator.pushNamed(context, '/good_job', arguments: {
        'onContinue': () {
          if (!mounted) return;
          setState(() => _current++);
          _resetWord();
        },
      });
      return;
    }
    if (_current >= _questions.length - 1) {
      _onComplete();
      return;
    }
    setState(() => _current++);
    _resetWord();
  }

  Future<void> _onComplete() async {
    final cfg = _config!;
    await UserService.addStars(cfg.starsReward);
    await UserService.completeLevel(cfg.categoryId);
    await UserService.addTimeSpent(5);
    ProgressRepository.instance
        .recordLevelCompleteAndSync(cfg.categoryId, stars: cfg.starsReward);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/level_complete',
        arguments: {'starsEarned': cfg.starsReward});
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_config == null || _questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final item = _questions[_current];
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.bgTop, AppTheme.bgBottom],
            stops: [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressBar(),
              SizedBox(height: _sectionGap),
              _buildMascotBubble(),
              SizedBox(height: _sectionGap),
              _buildQuestionCard(item),
              const Spacer(),
              _buildLetterGrid(),
              SizedBox(height: _bottomGap),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  /// [ContentPack.title] is an internal identifier, not display copy — the
  /// pack's locale governs the spelling *word*, but this header IS chrome (a
  /// screen title, not a word to spell), so it maps [ContentPack.categoryId]
  /// to the same localized level-title strings the level-select card
  /// (levels_screen.dart) already uses.
  String _localizedTitle(AppLocalizations t) {
    switch (_config!.categoryId) {
      case 'numbers':
        return t.levelTitleNumbers;
      case 'colors':
        return t.levelTitleColors;
      case 'fruits':
        return t.levelTitleFruits;
      case 'animals':
        return t.levelTitleAnimals;
      case 'food':
        return t.levelTitleFood;
      default:
        return _config!.title;
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: AppTheme.textDark),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _localizedTitle(AppLocalizations.of(context)!),
            style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark),
          ),
          const Spacer(),
          Text(
            '${_current + 1} / ${_questions.length}',
            style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: (_current + 1) / _questions.length,
          minHeight: 8,
          backgroundColor: Colors.white.withValues(alpha: 0.5),
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
        ),
      ),
    );
  }

  // ─── Mascot bubble ─────────────────────────────────────────────────────────

  Widget _buildMascotBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            child: const CloudMascot(size: 80, animate: true),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                _instructionFor(context, _config!.categoryId),
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Question card ─────────────────────────────────────────────────────────

  Widget _buildQuestionCard(ContentItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
            vertical: _useWideKeyLayout ? 12 : 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            // Wrapped in FittedBox so the enlarged hint (swatch/digit/emoji)
            // can never overflow on a narrow screen — it only ever scales
            // down, never up past its natural size.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHint(item),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => TtsService.instance
                        .speak(item.word, locale: _config!.locale),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: _useWideKeyLayout ? 10 : 18),
            _buildWordBoxes(item.word),
          ],
        ),
      ),
    );
  }

  Widget _buildHint(ContentItem item) {
    // ── Color swatch ──
    if (item.tileColor != null) {
      return Container(
        width: 124,
        height: 88,
        decoration: BoxDecoration(
          color: item.tileColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: item.tileColor!.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            )
          ],
        ),
      );
    }
    // ── Number digit (display contains only digit characters) ──
    final isDigit = item.display.codeUnits.every((c) => c >= 48 && c <= 57);
    if (isDigit) {
      // Shrunk for wide-key (Russian) layouts only — reclaims vertical
      // room a 3-row keyboard needs; en/uz keep the original 124x112.
      final tileHeight = _useWideKeyLayout ? 86.0 : 112.0;
      final tileWidth = _useWideKeyLayout ? 108.0 : 124.0;
      return Container(
        width: tileWidth,
        height: tileHeight,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Center(
          child: Text(
            item.display,
            style: GoogleFonts.nunito(
              fontSize: item.display.length == 1 ? 62 : 46,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    // ── Emoji ──
    return Text(item.display, style: const TextStyle(fontSize: 92));
  }

  Widget _buildWordBoxes(String word) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(word.length, (i) {
          final placed = i < _letterIndex;
          final isCurrent = i == _letterIndex;
          return Container(
            width: 36,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: placed
                  ? const Color(0xFF6EE482)
                  : isCurrent
                      ? const Color(0xFFB8C8FF)
                      : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: placed
                    ? const Color(0xFF4AC75E)
                    : isCurrent
                        ? AppTheme.primary
                        : const Color(0xFFD0D5E8),
                width: isCurrent ? 2.5 : 1.5,
              ),
            ),
            child: Center(
              child: Text(
                word[i],
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: placed
                      ? Colors.white
                      : isCurrent
                          ? AppTheme.primary
                          : const Color(0xFFBCC0D6),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Letter grid ───────────────────────────────────────────────────────────

  // Layout adapts to tile count so larger grids still look clean on screen.
  //
  // For `answerDrivenKeyCount` packs (Russian's word categories, where an
  // 8/10-key board is now common rather than rare), 8 and 10 keys share a
  // 4-column layout — 10 wraps to a 4+4+2, 3-row grid rather than a
  // 5-column row, which computed to ~53pt tiles on a 320pt-wide device,
  // well under the 64dp child touch-target minimum; 4 columns holds
  // ≥64dp down to that same width. For every en/uz pack this stays the
  // exact original 5-column/20pad/10spacing/20font layout, unchanged —
  // widening this fix to en/uz would itself be a visible behavior change,
  // which the hard "EN/UZ byte-for-byte identical" rule forbids even
  // though the narrow-device gap it fixes is real and pre-existing there
  // too (see PROGRESS.md).
  bool get _useWideKeyLayout => _config!.answerDrivenKeyCount;

  // A 3-row (10-key) grid needs more vertical room than the original
  // 2-row layout ever did — tightened section gaps reclaim it. Only
  // engaged for `_useWideKeyLayout` packs; en/uz keep the original 14/36
  // spacing exactly.
  double get _sectionGap => _useWideKeyLayout ? 8.0 : 14.0;
  double get _bottomGap => _useWideKeyLayout ? 12.0 : 36.0;

  int get _crossAxisCount {
    if (_grid.length <= 6) return 3;
    if (_useWideKeyLayout) return 4;
    return _grid.length <= 8 ? 4 : 5;
  }

  double get _gridSidePad {
    if (_grid.length <= 6) return 32.0;
    if (_useWideKeyLayout) return 12.0;
    return _grid.length <= 8 ? 20.0 : 12.0;
  }

  double get _gridItemSpacing {
    if (_grid.length <= 6) return 14.0;
    if (_useWideKeyLayout) return 6.0;
    return _grid.length <= 8 ? 10.0 : 8.0;
  }

  double get _tileFontSize {
    if (_grid.length <= 6) return 30.0;
    if (_useWideKeyLayout) return 24.0;
    return _grid.length <= 8 ? 24.0 : 20.0;
  }

  Widget _buildLetterGrid() {
    final spacing = _gridItemSpacing;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _gridSidePad),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 1,
        ),
        itemCount: _grid.length,
        itemBuilder: (_, i) => _buildLetterTile(_grid[i]),
      ),
    );
  }

  Widget _buildLetterTile(String letter) {
    final usedUp = _isUsedUp(letter);
    final isWrong = _flashWrong == letter;
    // Subtle blue tint on the tile that matches the next required letter.
    final isTarget =
        !usedUp && _letterIndex < _word.length && letter == _word[_letterIndex];

    final Color bg;
    final Color border;
    final Color textColor;

    if (usedUp) {
      bg = const Color(0xFF6EE482);
      border = const Color(0xFF4AC75E);
      textColor = Colors.white;
    } else if (isWrong) {
      bg = const Color(0xFFFFE0E0);
      border = const Color(0xFFFF6B6B);
      textColor = const Color(0xFFFF6B6B);
    } else if (isTarget) {
      bg = const Color(0xFFE8EEFF);
      border = AppTheme.primary;
      textColor = AppTheme.primary;
    } else {
      bg = Colors.white;
      border = const Color(0xFFD0D5E8);
      textColor = AppTheme.textDark;
    }

    return GestureDetector(
      onTap: usedUp ? null : () => _onLetterTap(letter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: isTarget ? 2.5 : 2),
          boxShadow: usedUp
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
        ),
        child: Center(
          child: Text(
            letter,
            style: GoogleFonts.nunito(
              fontSize: _tileFontSize,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
