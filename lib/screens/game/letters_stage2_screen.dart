import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cloud_mascot.dart';
import '../../services/user_service.dart';
import '../../services/tts_service.dart';

class LettersStage2Screen extends StatefulWidget {
  const LettersStage2Screen({super.key});

  @override
  State<LettersStage2Screen> createState() => _LettersStage2ScreenState();
}

class _LettersStage2ScreenState extends State<LettersStage2Screen>
    with TickerProviderStateMixin {
  static const _words = [
    'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE',
    'SIX', 'SEVEN', 'EIGHT', 'NINE', 'TEN'
  ];

  int _wordIndex = 0;
  int _letterIndex = 0; // which letter in current word we're targeting
  late List<String> _tapped; // letters tapped so far
  late List<String> _choices;
  final _rng = Random();
  String? _flashWrong;

  @override
  void initState() {
    super.initState();
    _resetWord();
  }

  void _resetWord() {
    _letterIndex = 0;
    _tapped = [];
    _flashWrong = null;
    _generateChoices();
    final capturedWord = _words[_wordIndex];
    Future.delayed(const Duration(milliseconds: 350), () {
      TtsService.instance.speak(capturedWord);
    });
  }

  void _generateChoices() {
    final word = _words[_wordIndex];
    // All unique letters in the word
    final wordLetters = word.split('').toSet().toList();
    // Add distractors from alphabet
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final pool = alphabet.split('')
      ..removeWhere((l) => wordLetters.contains(l));
    pool.shuffle(_rng);
    final distractors = pool.take(6 - wordLetters.length).toList();
    final all = [...wordLetters, ...distractors]..shuffle(_rng);
    // Ensure exactly 6
    setState(() {
      _choices = all.take(6).toList();
      _flashWrong = null;
    });
  }

  void _onTap(String letter) {
    final word = _words[_wordIndex];
    final expected = word[_letterIndex];
    if (letter == expected) {
      UserService.recordAnswer(correct: true);
      setState(() {
        _tapped = [..._tapped, letter];
        _letterIndex++;
        _flashWrong = null;
      });
      if (_letterIndex >= word.length) {
        Future.delayed(const Duration(milliseconds: 500), _advanceWord);
      }
    } else {
      UserService.recordAnswer(correct: false);
      setState(() => _flashWrong = letter);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _flashWrong = null);
      });
    }
  }

  void _advanceWord() {
    if (!mounted) return;
    if (_wordIndex >= _words.length - 1) {
      _onComplete();
      return;
    }
    _wordIndex++;
    _resetWord();
  }

  Future<void> _onComplete() async {
    await UserService.addStars(10);
    await UserService.setLettersStage(2);
    await UserService.addTimeSpent(5);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/level_complete', arguments: {
      'starsEarned': 10,
      'title': 'You did it!',
    });
  }

  @override
  Widget build(BuildContext context) {
    final word = _words[_wordIndex];
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
              _buildWordCard(word),
              const Spacer(),
              _buildChoicesGrid(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
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
            'Letters',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const Spacer(),
          Text(
            '${_wordIndex + 1}/${_words.length}',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: (_wordIndex + (_letterIndex / _words[_wordIndex].length)) /
              _words.length,
          minHeight: 8,
          backgroundColor: Colors.white.withValues(alpha: 0.5),
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                'Find and tap\nthis letter',
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

  Widget _buildWordCard(String word) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(word.length, (i) {
                  final done = i < _letterIndex;
                  final current = i == _letterIndex;
                  Color bg = current
                      ? AppTheme.primary
                      : done
                          ? const Color(0xFFA8E6B0)
                          : Colors.grey.withValues(alpha: 0.25);
                  Color textColor =
                      (current || done) ? Colors.white : AppTheme.textMedium;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        done || current ? word[i] : '',
                        style: GoogleFonts.nunito(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => TtsService.instance.speak(word),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volume_up_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Find and tap this letter',
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

  Widget _buildChoicesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _choices.take(3).map((l) => _choiceBtn(l)).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _choices.skip(3).take(3).map((l) => _choiceBtn(l)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _choiceBtn(String letter) {
    final word = _words[_wordIndex];
    final expected = _letterIndex < word.length ? word[_letterIndex] : '';
    final alreadyUsed = _tapped.contains(letter) &&
        word.split('').where((c) => c == letter).length <=
            _tapped.where((c) => c == letter).length;
    final isWrong = _flashWrong == letter;
    final isCurrentTarget = letter == expected && !alreadyUsed;

    Color bg = Colors.white;
    Color border = Colors.transparent;
    if (alreadyUsed) {
      bg = const Color(0xFFC8F0D0);
    } else if (isWrong) {
      bg = const Color(0xFFFFE0E0);
      border = const Color(0xFFFF6B6B);
    } else if (isCurrentTarget) {
      bg = AppTheme.cardActive;
      border = AppTheme.primary;
    }

    return GestureDetector(
      onTap: alreadyUsed ? null : () => _onTap(letter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 2.5),
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
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
