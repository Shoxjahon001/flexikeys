import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/level_configs.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cloud_mascot.dart';
import '../../services/user_service.dart';
import '../../services/tts_service.dart';

class GenericGameScreen extends StatefulWidget {
  const GenericGameScreen({super.key});

  @override
  State<GenericGameScreen> createState() => _GenericGameScreenState();
}

class _GenericGameScreenState extends State<GenericGameScreen> {
  LevelConfig? _config;
  List<GameItem> _questions = [];
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
      if (args is LevelConfig) {
        _config = args;
        _initQuestions();
      }
    }
  }

  void _initQuestions() {
    final cfg = _config!;
    final count = cfg.questionCount.clamp(1, cfg.items.length);
    final shuffled = List<GameItem>.from(cfg.items)..shuffle(_rng);
    _questions = shuffled.take(count).toList();
    _resetWord();
  }

  void _resetWord() {
    setState(() {
      _tapped = [];
      _flashWrong = null;
      _grid = _buildGrid(_questions[_current].word, _gridSize);
    });
    final capturedWord = _questions[_current].word;
    Future.delayed(const Duration(milliseconds: 350), () {
      TtsService.instance.speak(capturedWord);
    });
  }

  // ─── Progressive difficulty ────────────────────────────────────────────────

  /// Grid tile count grows in three stages as the level progresses:
  ///   First  third → 6 tiles (easier start)
  ///   Middle third → 8 tiles
  ///   Last   third → 10 tiles (most distractors, hardest)
  /// Always at least as many tiles as unique letters in the current word.
  int get _gridSize {
    final uniqueCount = _word.split('').toSet().length;
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

  List<String> _buildGrid(String word, int count) {
    final needed = word.split('').toSet().toList();
    final pool = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')
      ..removeWhere(needed.contains);
    pool.shuffle(_rng);
    final extras = pool.take((count - needed.length).clamp(0, 26)).toList();
    return ([...needed, ...extras]..shuffle(_rng)).take(count).toList();
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
      final next = [..._tapped, letter];
      setState(() => _tapped = next);
      if (next.length >= _word.length) {
        Future.delayed(const Duration(milliseconds: 500), _advance);
      }
    } else {
      UserService.recordAnswer(correct: false);
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
    await UserService.completeLevel(cfg.id);
    await UserService.addTimeSpent(5);
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
              const SizedBox(height: 14),
              _buildMascotBubble(),
              const SizedBox(height: 14),
              _buildQuestionCard(item),
              const Spacer(),
              _buildLetterGrid(),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

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
            _config!.title,
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
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppTheme.primary),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                _config!.instruction,
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

  Widget _buildQuestionCard(GameItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHint(item),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => TtsService.instance.speak(item.word),
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
            const SizedBox(height: 18),
            _buildWordBoxes(item.word),
          ],
        ),
      ),
    );
  }

  Widget _buildHint(GameItem item) {
    // ── Color swatch ──
    if (item.tileColor != null) {
      return Container(
        width: 88,
        height: 60,
        decoration: BoxDecoration(
          color: item.tileColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 3),
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
      return Container(
        width: 88,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(20),
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
              fontSize: item.display.length == 1 ? 44 : 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    // ── Emoji ──
    return Text(item.display, style: const TextStyle(fontSize: 64));
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
  int    get _crossAxisCount  => _grid.length <= 6 ? 3 : (_grid.length <= 8 ? 4 : 5);
  double get _gridSidePad     => _grid.length <= 6 ? 32.0 : (_grid.length <= 8 ? 20.0 : 12.0);
  double get _gridItemSpacing => _grid.length <= 6 ? 14.0 : (_grid.length <= 8 ? 10.0 : 8.0);
  double get _tileFontSize    => _grid.length <= 6 ? 30.0 : (_grid.length <= 8 ? 24.0 : 20.0);

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
    final isTarget = !usedUp &&
        _letterIndex < _word.length &&
        letter == _word[_letterIndex];

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
