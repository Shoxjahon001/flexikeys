import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';
import '../data/level_configs.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

enum _LockState { locked, unlocked, done }

class _LevelItem {
  final String id;
  final String title;
  final String? emoji;
  final String? letter;
  final Widget? customWidget;
  final _LockState lockState;

  const _LevelItem({
    required this.id,
    required this.title,
    this.emoji,
    this.letter,
    this.customWidget,
    required this.lockState,
  });

  bool get locked => lockState == _LockState.locked;
  bool get done   => lockState == _LockState.done;

  Color get cardColor {
    switch (lockState) {
      case _LockState.done:     return const Color(0xFFD4F5DC);
      case _LockState.unlocked: return const Color(0xFFD6EEFF);
      case _LockState.locked:   return AppTheme.cardLocked;
    }
  }

  Color get borderColor {
    switch (lockState) {
      case _LockState.done:     return const Color(0xFF52C96A);
      case _LockState.unlocked: return AppTheme.primary;
      case _LockState.locked:   return Colors.transparent;
    }
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class LevelsScreen extends StatefulWidget {
  final String? externalName;
  const LevelsScreen({super.key, this.externalName});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  int _stars = 0;
  String _name = '';
  Set<String> _completed = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      final n = args['name'] as String? ?? '';
      if (n.isNotEmpty && n != _name) setState(() => _name = n);
    }
  }

  Future<void> _load() async {
    final stars     = await UserService.getStars();
    final completed = await UserService.getCompletedLevels();
    final name      = await UserService.getName();
    if (!mounted) return;
    setState(() {
      _stars     = stars;
      _completed = completed;
      if (widget.externalName != null && widget.externalName!.isNotEmpty) {
        _name = widget.externalName!;
      } else if (_name.isEmpty && name.isNotEmpty) {
        _name = name;
      }
    });
  }

  _LockState _stateOf(String id) {
    if (_completed.contains(id)) return _LockState.done;
    // Unlock chain
    switch (id) {
      case 'letters':
        return _LockState.unlocked; // always available
      case 'numbers':
        return _completed.contains('letters_1')
            ? _LockState.unlocked
            : _LockState.locked;
      case 'colors':
        return _completed.contains('numbers')
            ? _LockState.unlocked
            : _LockState.locked;
      case 'fruits':
        return _completed.contains('colors')
            ? _LockState.unlocked
            : _LockState.locked;
      case 'animals':
        return _completed.contains('fruits')
            ? _LockState.unlocked
            : _LockState.locked;
      case 'food':
        return _completed.contains('animals')
            ? _LockState.unlocked
            : _LockState.locked;
      default:
        return _LockState.locked;
    }
  }

  List<_LevelItem> get _levels => [
        _LevelItem(
          id: 'letters',
          title: 'Letters',
          letter: 'A',
          lockState: _stateOf('letters'),
        ),
        _LevelItem(
          id: 'numbers',
          title: 'Numbers',
          customWidget: const _NumbersIcon(),
          lockState: _stateOf('numbers'),
        ),
        _LevelItem(
          id: 'colors',
          title: 'Colors',
          emoji: '🌈',
          lockState: _stateOf('colors'),
        ),
        _LevelItem(
          id: 'fruits',
          title: 'Fruits',
          emoji: '🍎',
          lockState: _stateOf('fruits'),
        ),
        _LevelItem(
          id: 'animals',
          title: 'Animals',
          emoji: '🦁',
          lockState: _stateOf('animals'),
        ),
        _LevelItem(
          id: 'food',
          title: 'Food',
          emoji: '🍽️',
          lockState: _stateOf('food'),
        ),
      ];

  // ─── Navigation ─────────────────────────────────────────────────────────────

  Future<void> _onLevelTap(_LevelItem level) async {
    if (level.id == 'letters') {
      // Always show Stage 1 (A–O letter recognition) so Letters never
      // shows number-word content that looks like the Numbers level.
      await Navigator.pushNamed(context, '/game_stage1');
      _load();
      return;
    }
    final config = LevelConfigs.getById(level.id);
    if (config == null) return;
    await Navigator.pushNamed(context, '/generic_game', arguments: config);
    _load();
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: appGradientBg,
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 8),
            Text(
              'Levels',
              style: GoogleFonts.nunito(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.95,
                ),
                itemCount: _levels.length,
                itemBuilder: (context, index) =>
                    _buildCard(_levels[index], index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD6E8), Color(0xFFD6C8FF)],
                    ),
                  ),
                  child: const Center(
                      child: Text('☁️', style: TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 10),
                Text(
                  _name,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  '$_stars',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.star_rounded,
                    color: AppTheme.starYellow, size: 26),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(_LevelItem level, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 80),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(scale: 0.85 + 0.15 * value, child: child),
      ),
      child: GestureDetector(
        onTap: level.locked ? null : () => _onLevelTap(level),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: level.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: level.borderColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: level.locked ? 0.04 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (level.locked)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Icon(
                    Icons.lock_rounded,
                    size: 22,
                    color: AppTheme.textDark.withValues(alpha: 0.45),
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: level.locked
                          ? Colors.white.withValues(alpha: 0.45)
                          : Colors.white,
                      boxShadow: level.locked
                          ? []
                          : [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                blurRadius: 16,
                              )
                            ],
                    ),
                    child: Center(child: _buildIcon(level)),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    level.title,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: level.locked
                          ? AppTheme.textMedium.withValues(alpha: 0.55)
                          : AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(_LevelItem level) {
    if (level.letter != null) {
      return Text(
        level.letter!,
        style: GoogleFonts.nunito(
          fontSize: 48,
          fontWeight: FontWeight.w900,
          color: level.locked
              ? AppTheme.textMedium.withValues(alpha: 0.4)
              : AppTheme.textDark,
        ),
      );
    }
    if (level.customWidget != null) return level.customWidget!;
    if (level.emoji != null) {
      return Text(
        level.emoji!,
        style: TextStyle(
          fontSize: 44,
          color: level.locked ? null : null,
        ),
      );
    }
    return const SizedBox();
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _NumbersIcon extends StatelessWidget {
  const _NumbersIcon();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('1',
            style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFF8A80))),
        Text('2',
            style: GoogleFonts.nunito(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF69C0FF))),
        Text('3',
            style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF95DE64))),
      ],
    );
  }
}
