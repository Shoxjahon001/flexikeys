import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/content_packs/content_pack.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cloud_mascot.dart';
import '../../services/user_service.dart';
import '../../services/tts_service.dart';
import '../../services/sound_service.dart';
import '../../services/progress/progress_repository.dart';
import '../../design_system/fk_tokens.dart';

class LettersStage1Screen extends StatefulWidget {
  const LettersStage1Screen({super.key});

  @override
  State<LettersStage1Screen> createState() => _LettersStage1ScreenState();
}

class _LettersStage1ScreenState extends State<LettersStage1Screen>
    with TickerProviderStateMixin {
  ContentPack? _pack;
  late List<String> _letters;

  /// word -> spokenText, for letters whose TTS pronunciation differs from
  /// their on-screen glyph (Ь/Ъ have no standalone sound — see
  /// [ContentItem.spokenText]). Letters not in this map are simply spoken
  /// as their own glyph.
  late Map<String, String> _spokenTextByLetter;
  String _speakTextFor(String letter) => _spokenTextByLetter[letter] ?? letter;

  int _current = 0;
  String? _selected;
  bool _answered = false;
  final _rng = Random();
  List<String> _choices = const [];
  late AnimationController _correctCtrl;
  late Animation<double> _correctScale;

  // Retry phase state
  final Set<String> _missedLetters = {};
  bool _isRetryPhase = false;
  List<String> _retryLetters = [];
  int _retryIndex = 0;

  String get _currentTarget =>
      _isRetryPhase ? _retryLetters[_retryIndex] : _letters[_current];

  @override
  void initState() {
    super.initState();
    _correctCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _correctScale = Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: _correctCtrl, curve: Curves.elasticOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pack == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is ContentPack) {
        _pack = args;
        _letters = _pack!.items.map((i) => i.word).toList();
        _spokenTextByLetter = {
          for (final i in _pack!.items) i.word: i.spokenText,
        };
        _buildChoicesDirect();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            TtsService.instance.speak(_speakTextFor(_letters[_current]),
                locale: _pack!.locale);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _correctCtrl.dispose();
    super.dispose();
  }

  void _buildChoicesDirect() {
    final target = _currentTarget;
    final pool = List<String>.from(_letters)..remove(target);
    pool.shuffle(_rng);
    final wrong = pool.take(2).toList();
    _choices = [target, ...wrong]..shuffle(_rng);
    _selected = null;
    _answered = false;
  }

  void _generateChoices() {
    _buildChoicesDirect();
    setState(() {});
    final capturedSpeech = _speakTextFor(_currentTarget);
    final locale = _pack!.locale;
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) TtsService.instance.speak(capturedSpeech, locale: locale);
    });
  }

  void _onTap(String letter) {
    if (_answered) return;
    final correct = letter == _currentTarget;
    setState(() {
      _selected = letter;
      _answered = true;
    });
    UserService.recordAnswer(correct: correct);
    if (correct) {
      SoundService.instance.playCorrect();
      _correctCtrl.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 600), _advance);
    } else {
      SoundService.instance.playWrong();
      if (!_isRetryPhase) _missedLetters.add(_currentTarget);
      Future.delayed(const Duration(milliseconds: 800), _advance);
    }
  }

  void _advance() {
    if (!mounted) return;

    if (_isRetryPhase) {
      if (_retryIndex >= _retryLetters.length - 1) {
        _onComplete();
        return;
      }
      _retryIndex++;
      _generateChoices();
      return;
    }

    // Fires once, roughly halfway through the run — `_letters.length ~/ 2`
    // reproduces the exact previous hardcoded `7` for the old fixed 15-item
    // English list (15 ~/ 2 == 7), and generalizes correctly now that list
    // length varies by locale (26 for English, 33 for Russian).
    if (_current == _letters.length ~/ 2) {
      Navigator.pushNamed(context, '/good_job', arguments: {
        'onContinue': () {
          if (!mounted) return;
          _current++;
          _generateChoices();
        }
      });
      return;
    }
    if (_current >= _letters.length - 1) {
      if (_missedLetters.isNotEmpty) {
        _startRetryPhase();
        return;
      }
      _onComplete();
      return;
    }
    _current++;
    _generateChoices();
  }

  void _startRetryPhase() {
    setState(() {
      _isRetryPhase = true;
      _retryLetters = _missedLetters.toList()..shuffle(_rng);
      _retryIndex = 0;
    });
    _generateChoices();
  }

  Future<void> _onComplete() async {
    final slug = _pack!.categoryId;
    final stars = _pack!.starsReward;
    await UserService.addStars(stars);
    await UserService.addTimeSpent(5);
    if (slug == 'letters') {
      // The ungrouped pack (en/uz today) — mirrors
      // UserService.setLettersStage(1): completes both 'letters_1' and the
      // umbrella 'letters' level. Reproduces the exact prior hardcoded
      // behavior byte-for-byte (both packs' starsReward default to 10).
      await UserService.setLettersStage(1);
      ProgressRepository.instance
          .recordLevelCompleteAndSync('letters_1', stars: stars);
      ProgressRepository.instance
          .recordLevelCompleteAndSync('letters', stars: stars);
    } else {
      // A single letter group (Russian's grouped flow — see
      // letters_group_picker_screen.dart) completes only its own slug; the
      // picker screen marks the umbrella 'letters'/'letters_1' complete
      // once every group is done.
      await UserService.completeLevel(slug);
      ProgressRepository.instance.recordLevelCompleteAndSync(slug, stars: stars);
    }
    if (!mounted) return;
    final title = AppLocalizations.of(context)!.correctFeedback;
    Navigator.pushReplacementNamed(context, '/level_complete', arguments: {
      'starsEarned': stars,
      'title': title,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pack == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final target = _currentTarget;
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
              const SizedBox(height: 20),
              _buildMascotRow(),
              const SizedBox(height: 16),
              _buildQuestionCard(target),
              const Spacer(),
              _buildChoices(target),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final total = _isRetryPhase ? _retryLetters.length : _letters.length;
    final current = _isRetryPhase ? _retryIndex + 1 : _current + 1;
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
            _isRetryPhase
                ? AppLocalizations.of(context)!.tryAgainHeader
                : 'Letters',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const Spacer(),
          Text(
            '$current/$total',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _isRetryPhase
        ? (_retryIndex + 1) / _retryLetters.length
        : (_current + 1) / _letters.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          backgroundColor: Colors.white.withValues(alpha: 0.5),
          valueColor: AlwaysStoppedAnimation<Color>(
            _isRetryPhase ? const Color(0xFFFF9800) : AppTheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildMascotRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            child: const CloudMascot(size: 94, animate: true),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                _isRetryPhase
                    ? AppLocalizations.of(context)!.retryMascotMessage
                    : AppLocalizations.of(context)!.findAndTapInstruction,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String target) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          children: [
            // Wrapped in FittedBox so the enlarged target box can never
            // overflow on a narrow screen — it only ever scales down, never
            // up past its natural size.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _correctScale,
                    child: Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        color: _isRetryPhase
                            ? const Color(0xFFFF9800)
                            : AppTheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          target,
                          style: GoogleFonts.nunito(
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => TtsService.instance
                        .speak(_speakTextFor(target), locale: _pack!.locale),
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
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.findAndTapCaption,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoices(String target) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _choices.map((letter) {
          final isSelected = _selected == letter;
          final isCorrect = letter == target;

          Color bgColor = Colors.white;
          Color borderColor = Colors.transparent;
          Color textColor = AppTheme.textDark;

          if (_answered) {
            if (isCorrect) {
              bgColor = const Color(0xFF6EE482);
              borderColor = const Color(0xFF4AC75E);
              textColor = Colors.white;
            } else if (isSelected) {
              bgColor = FkColors.attention;
              borderColor = FkColors.attention;
              textColor = FkColors.ink;
            }
          } else if (isCorrect) {
            bgColor = const Color(0xFFE8EEFF);
            borderColor = AppTheme.primary;
            textColor = AppTheme.primary;
          }

          return GestureDetector(
            onTap: () => _onTap(letter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Center(
                child: Text(
                  letter,
                  style: GoogleFonts.nunito(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
