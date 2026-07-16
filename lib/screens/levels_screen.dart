import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';
import '../data/level_configs.dart';
import '../data/trace_items/letters_trace_data.dart';

// ── Lock state ────────────────────────────────────────────────────────────────

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
}

// ── Screen ────────────────────────────────────────────────────────────────────

class LevelsScreen extends StatefulWidget {
  final String? externalName;
  const LevelsScreen({super.key, this.externalName});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  String _name = '';
  Set<String> _completed = {};
  int _tab = 0; // 0 = O'rganish, 1 = Chizish

  // Dev/QA backdoor: registering the kid's name as "admin" unlocks every
  // level and task, regardless of actual progress. Any other name behaves
  // normally (mastery-gated progression, unaffected).
  bool _isAdmin = false;

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
    final completed = await UserService.getCompletedLevels();
    final name      = await UserService.getName();
    if (!mounted) return;
    setState(() {
      _completed = completed;
      _isAdmin = name.trim().toLowerCase() == 'admin';
      if (widget.externalName?.isNotEmpty == true) {
        _name = widget.externalName!;
      } else if (_name.isEmpty && name.isNotEmpty) {
        _name = name;
      }
    });
  }

  _LockState _stateOf(String id) {
    if (_completed.contains(id)) return _LockState.done;
    if (_isAdmin) return _LockState.unlocked;
    switch (id) {
      case 'letters': return _LockState.unlocked;
      case 'numbers': return _completed.contains('letters_1') ? _LockState.unlocked : _LockState.locked;
      case 'colors':  return _completed.contains('numbers')   ? _LockState.unlocked : _LockState.locked;
      case 'fruits':  return _completed.contains('colors')    ? _LockState.unlocked : _LockState.locked;
      case 'animals': return _completed.contains('fruits')    ? _LockState.unlocked : _LockState.locked;
      case 'food':    return _completed.contains('animals')   ? _LockState.unlocked : _LockState.locked;
      default:        return _LockState.locked;
    }
  }

  List<_LevelItem> get _levels => [
    _LevelItem(id: 'letters', title: 'Letters', letter: 'A', lockState: _stateOf('letters')),
    _LevelItem(id: 'numbers', title: 'Numbers', customWidget: const _NumbersIcon(), lockState: _stateOf('numbers')),
    _LevelItem(id: 'colors',  title: 'Colors',  emoji: '🌈', lockState: _stateOf('colors')),
    _LevelItem(id: 'fruits',  title: 'Fruits',  emoji: '🍎', lockState: _stateOf('fruits')),
    _LevelItem(id: 'animals', title: 'Animals', emoji: '🦁', lockState: _stateOf('animals')),
    _LevelItem(id: 'food',    title: 'Food',    emoji: '🍽️', lockState: _stateOf('food')),
  ];

  Future<void> _onLevelTap(_LevelItem level) async {
    if (level.locked) return;
    if (level.id == 'letters') {
      await Navigator.pushNamed(context, '/game_stage1');
    } else {
      final config = LevelConfigs.getById(level.id);
      if (config == null) return;
      await Navigator.pushNamed(context, '/generic_game', arguments: config);
    }
    _load();
  }

  void _onDrawTap(String id) {
    if (id == 'shapes') {
      Navigator.pushNamed(context, '/shapes_game').then((_) => _load());
      return;
    }
    if (id == 'letters_draw') {
      Navigator.pushNamed(context, '/letter_groups').then((_) => _load());
      return;
    }
    if (id == 'numbers_draw') {
      Navigator.pushNamed(context, '/number_drawing_game').then((_) => _load());
      return;
    }
    if (id == 'objects') {
      Navigator.pushNamed(context, '/object_drawing_game').then((_) => _load());
      return;
    }
    if (id == 'fruits_color') {
      Navigator.pushNamed(context, '/fruits_coloring_game').then((_) => _load());
      return;
    }
    if (id == 'animals_color') {
      Navigator.pushNamed(context, '/animals_coloring_game').then((_) => _load());
      return;
    }
    if (id == 'nature') {
      Navigator.pushNamed(context, '/nature_coloring_game').then((_) => _load());
      return;
    }
    if (id == 'transport') {
      Navigator.pushNamed(context, '/transport_coloring_game').then((_) => _load());
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tez kunda! 🚀', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF4A90F7),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: appGradientBg,
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildTabSwitcher(),
            Expanded(child: _tab == 0 ? _buildLearnTab() : _buildDrawTab()),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: Row(
        children: [
          // Avatar + name
          Container(
            padding: const EdgeInsets.fromLTRB(5, 5, 16, 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFCDD6FF), Color(0xFFA7B6F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ValueListenableBuilder<String>(
                    valueListenable: UserService.avatarNotifier,
                    builder: (_, emoji, __) => Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _name,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2A2F45),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Stars
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: UserService.starsNotifier,
                  builder: (_, stars, __) => Text(
                    '$stars',
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2A2F45),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                const Text('⭐', style: TextStyle(fontSize: 17)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab switcher ──────────────────────────────────────────────────────────

  bool get _drawUnlocked => _isAdmin || _completed.contains('letters_1');

  /// True (locked) unless the admin backdoor is active or [requiredId] has
  /// already been completed.
  bool _lockedUnless(String requiredId) => !_isAdmin && !_completed.contains(requiredId);

  /// The Letters drawing task is now split into 7 small groups (see
  /// letters_trace_data.dart) — Numbers unlocks once every group is done,
  /// not a single flat 'letter_drawing' flag.
  bool get _allLetterGroupsDone =>
      kLetterGroups.every((g) => _completed.contains(g.id));

  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFFE3E6F3),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            _tabBtn(0, '🎓 O\'rganish', unlocked: true),
            _tabBtn(1, '🎨 Chizish',   unlocked: _drawUnlocked),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(int index, String label, {required bool unlocked}) {
    final active = _tab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!unlocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '🔒 "Letters" darajasini tugatib oching!',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                ),
                backgroundColor: const Color(0xFF4A90F7),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
            return;
          }
          setState(() => _tab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF4A90F7) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFF4A90F7).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: active
                      ? Colors.white
                      : unlocked
                          ? const Color(0xFF6B7186)
                          : const Color(0xFFAEB4C8),
                ),
              ),
              if (!unlocked) ...[
                const SizedBox(width: 4),
                const Text('🔒', style: TextStyle(fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── O'rganish tab ─────────────────────────────────────────────────────────

  Widget _buildLearnTab() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Darajalar',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF2A2F45),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _buildLearnCard(_levels[i], i),
              childCount: _levels.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.92,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLearnCard(_LevelItem level, int index) {
    Color cardBg;
    Color borderColor;
    if (level.locked) {
      cardBg = const Color(0xFFE9EAEF);
      borderColor = Colors.transparent;
    } else if (level.done) {
      cardBg = const Color(0xFFDFF0DB);
      borderColor = const Color(0xFF8ED07A);
    } else {
      cardBg = const Color(0xFFDBEAFE);
      borderColor = const Color(0xFF9CC6F7);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 380 + index * 70),
      curve: Curves.easeOut,
      builder: (_, v, child) =>
          Opacity(opacity: v, child: Transform.scale(scale: 0.85 + 0.15 * v, child: child)),
      child: GestureDetector(
        onTap: level.locked ? null : () => _onLevelTap(level),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: level.locked ? 0.0 : 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (level.locked)
                const Positioned(
                  top: 12,
                  right: 13,
                  child: Text('🔒', style: TextStyle(fontSize: 18)),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: level.locked
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.white,
                      boxShadow: level.locked
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Center(child: _buildLearnIcon(level)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    level.title,
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: level.locked
                          ? const Color(0xFFAEB4C8)
                          : const Color(0xFF2A2F45),
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

  Widget _buildLearnIcon(_LevelItem level) {
    if (level.letter != null) {
      return Text(
        level.letter!,
        style: GoogleFonts.nunito(
          fontSize: 44,
          fontWeight: FontWeight.w900,
          color: level.locked ? const Color(0xFFAEB4C8) : const Color(0xFF2A2F45),
        ),
      );
    }
    if (level.customWidget != null) {
      return Opacity(opacity: level.locked ? 0.45 : 1.0, child: level.customWidget!);
    }
    if (level.emoji != null) {
      return Text(
        level.emoji!,
        style: TextStyle(fontSize: 42, color: level.locked ? Colors.grey : null),
      );
    }
    return const SizedBox();
  }

  // ── Chizish tab ───────────────────────────────────────────────────────────

  Widget _buildDrawTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('✏️', 'Chizish'),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.92,
            children: [
              _drawCard(
                id: 'shapes',
                title: 'Shakllar',
                badge: '✏️',
                badgeColor: const Color(0xFF4A90F7),
                icon: const _ShapesIcon(),
                locked: false,
                cardColor: const Color(0xFFDFF0DB),
                borderColor: const Color(0xFF8ED07A),
              ),
              _drawCard(
                id: 'letters_draw',
                title: 'Harflar',
                badge: '✏️',
                badgeColor: const Color(0xFF4A90F7),
                icon: Text('A', style: GoogleFonts.nunito(fontSize: 44, fontWeight: FontWeight.w900, color: const Color(0xFF2A2F45))),
                locked: _lockedUnless('shapes'),
                cardColor: const Color(0xFFDFF0DB),
                borderColor: const Color(0xFF8ED07A),
              ),
              _drawCard(id: 'numbers_draw', title: 'Raqamlar', badge: '✏️', badgeColor: const Color(0xFF4A90F7), icon: const Text('123', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF5A6076))), locked: !_isAdmin && !_allLetterGroupsDone),
              _drawCard(id: 'objects', title: 'Narsalar', badge: '✏️', badgeColor: const Color(0xFF4A90F7), icon: const Text('🏠', style: TextStyle(fontSize: 40)), locked: _lockedUnless('number_drawing')),
            ],
          ),

          const SizedBox(height: 22),
          _sectionHeader('🖌️', "Bo'yash"),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.92,
            children: [
              _drawCard(
                id: 'fruits_color',
                title: 'Mevalar',
                badge: '🖌️',
                badgeColor: const Color(0xFFEF6F9C),
                icon: const Text('🍎', style: TextStyle(fontSize: 42)),
                locked: false,
                cardColor: const Color(0xFFFDECD6),
                borderColor: const Color(0xFFF3C27A),
              ),
              _drawCard(id: 'animals_color', title: 'Hayvonlar', badge: '🖌️', badgeColor: const Color(0xFFEF6F9C), icon: const Text('🦁', style: TextStyle(fontSize: 40)), locked: _lockedUnless('fruits_color')),
              _drawCard(id: 'nature',        title: 'Tabiat',    badge: '🖌️', badgeColor: const Color(0xFFEF6F9C), icon: const Text('🌸', style: TextStyle(fontSize: 40)), locked: _lockedUnless('animals_color')),
              _drawCard(id: 'transport',     title: 'Transport', badge: '🖌️', badgeColor: const Color(0xFFEF6F9C), icon: const Text('🚗', style: TextStyle(fontSize: 40)), locked: _lockedUnless('nature_color')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String emoji, String title) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF2A2F45),
          ),
        ),
      ],
    );
  }

  Widget _drawCard({
    required String id,
    required String title,
    required String badge,
    required Color badgeColor,
    required Widget icon,
    required bool locked,
    Color cardColor = const Color(0xFFE9EAEF),
    Color borderColor = Colors.transparent,
  }) {
    return GestureDetector(
      onTap: locked ? null : () => _onDrawTap(id),
      child: Container(
        decoration: BoxDecoration(
          color: locked ? const Color(0xFFE9EAEF) : cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: locked ? Colors.transparent : borderColor,
            width: 2,
          ),
          boxShadow: locked
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Stack(
          children: [
            if (locked)
              const Positioned(
                top: 12,
                right: 13,
                child: Text('🔒', style: TextStyle(fontSize: 18)),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: locked
                              ? const Color(0xFFF3F4F7)
                              : Colors.white,
                          boxShadow: locked
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: Opacity(
                            opacity: locked ? 0.45 : 1.0,
                            child: icon,
                          ),
                        ),
                      ),
                      if (!locked)
                        Positioned(
                          right: -3,
                          bottom: -3,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: badgeColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: badgeColor.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(badge, style: const TextStyle(fontSize: 14)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: locked ? const Color(0xFFAEB4C8) : const Color(0xFF2A2F45),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _NumbersIcon extends StatelessWidget {
  const _NumbersIcon();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('1', style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFFEF6F9C))),
        Text('2', style: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFF4A90F7))),
        Text('3', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF22B07D))),
      ],
    );
  }
}

// Mini icon for Shakllar card: shows 3 shapes
class _ShapesIcon extends StatelessWidget {
  const _ShapesIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(58, 42),
      painter: _ShapesIconPainter(),
    );
  }
}

class _ShapesIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Square
    final pSquare = Paint()..color = const Color(0xFF4A90F7)..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(2, size.height * 0.3, size.height * 0.6, size.height * 0.6), const Radius.circular(4)),
      pSquare,
    );
    // Circle
    final pCircle = Paint()..color = const Color(0xFFEF6F9C)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.38), size.height * 0.32, pCircle);
    // Triangle
    final pTri = Paint()..color = const Color(0xFF22B07D)..style = PaintingStyle.fill;
    final triPath = Path()
      ..moveTo(size.width * 0.82, size.height * 0.58)
      ..lineTo(size.width, size.height * 0.58)
      ..lineTo(size.width * 0.91, size.height * 0.35)
      ..close();
    canvas.drawPath(triPath, pTri);
  }

  @override
  bool shouldRepaint(_) => false;
}
