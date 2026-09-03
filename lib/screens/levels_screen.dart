import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../design_system/design_system.dart';
import '../services/user_service.dart';
import '../data/content_packs/spelling_content_packs.dart';
import '../data/content_packs/letters_content_packs.dart';
import '../data/trace_items/letters_trace_data.dart';
import '../features/aac/presentation/aac_home_screen.dart';

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
  bool get done => lockState == _LockState.done;
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
  bool _loading = true;

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
    final name = await UserService.getName();
    if (!mounted) return;
    setState(() {
      _completed = completed;
      _isAdmin = name.trim().toLowerCase() == 'admin';
      if (widget.externalName?.isNotEmpty == true) {
        _name = widget.externalName!;
      } else if (_name.isEmpty && name.isNotEmpty) {
        _name = name;
      }
      _loading = false;
    });
  }

  _LockState _stateOf(String id) {
    if (_completed.contains(id)) return _LockState.done;
    if (_isAdmin) return _LockState.unlocked;
    switch (id) {
      case 'letters':
        return _LockState.unlocked;
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

  List<_LevelItem> get _levels {
    final t = AppLocalizations.of(context)!;
    return [
      _LevelItem(
          id: 'letters',
          title: t.levelTitleLetters,
          letter: 'A',
          lockState: _stateOf('letters')),
      _LevelItem(
          id: 'numbers',
          title: t.levelTitleNumbers,
          customWidget: const _NumbersIcon(),
          lockState: _stateOf('numbers')),
      _LevelItem(
          id: 'colors',
          title: t.levelTitleColors,
          emoji: '🌈',
          lockState: _stateOf('colors')),
      _LevelItem(
          id: 'fruits',
          title: t.levelTitleFruits,
          emoji: '🍎',
          lockState: _stateOf('fruits')),
      _LevelItem(
          id: 'animals',
          title: t.levelTitleAnimals,
          emoji: '🦁',
          lockState: _stateOf('animals')),
      _LevelItem(
          id: 'food',
          title: t.levelTitleFood,
          emoji: '🍽️',
          lockState: _stateOf('food')),
    ];
  }

  Future<void> _onLevelTap(_LevelItem level) async {
    if (level.locked) return;
    final uiLocale = Localizations.localeOf(context).languageCode;
    if (level.id == 'letters') {
      final pack = LettersContentPacks.resolve(uiLocale);
      // groupSizes (data-driven, not a locale check) decides whether this
      // pack is too long for one sitting and needs the group picker first
      // — today only ru's 33-letter pack sets it; en/uz go straight to
      // the task screen exactly as before.
      final route =
          pack.groupSizes != null ? '/letters_group_picker' : '/game_stage1';
      await Navigator.pushNamed(context, route, arguments: pack);
    } else {
      final config = SpellingContentPacks.resolve(level.id, uiLocale);
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
      Navigator.pushNamed(context, '/fruits_coloring_game')
          .then((_) => _load());
      return;
    }
    if (id == 'animals_color') {
      Navigator.pushNamed(context, '/animals_coloring_game')
          .then((_) => _load());
      return;
    }
    if (id == 'nature') {
      Navigator.pushNamed(context, '/nature_coloring_game')
          .then((_) => _load());
      return;
    }
    if (id == 'transport') {
      Navigator.pushNamed(context, '/transport_coloring_game')
          .then((_) => _load());
      return;
    }
    FkToast.show(context, AppLocalizations.of(context)!.comingSoonSnackbar,
        type: FkToastType.info);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.background,
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildTabSwitcher(),
            Expanded(
              child: _loading
                  ? const Center(child: FkLoadingIndicator())
                  : (_tab == 0 ? _buildLearnTab() : _buildDrawTab()),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
      child: Row(
        children: [
          // Avatar + name. Not FkAvatar: the child picks a free-form emoji
          // avatar (UserService.avatarNotifier), not name-initials — a
          // different contract than FkAvatar's fallback, so it stays a
          // small local widget, just token-skinned.
          Container(
            padding: const EdgeInsets.fromLTRB(5, 5, AppSpacing.lg, 5),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppRadius.pillAll,
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primarySoft,
                  ),
                  child: ValueListenableBuilder<String>(
                    valueListenable: UserService.avatarNotifier,
                    builder: (_, emoji, __) => Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _name,
                  style: textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Stars
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: 9),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppRadius.pillAll,
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: UserService.starsNotifier,
                  builder: (_, stars, __) => Text(
                    '$stars',
                    style: textTheme.bodyLarge?.copyWith(
                        color: colors.textPrimary, fontWeight: FontWeight.w900),
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
  bool _lockedUnless(String requiredId) =>
      !_isAdmin && !_completed.contains(requiredId);

  /// The Letters drawing task is now split into 7 small groups (see
  /// letters_trace_data.dart) — Numbers unlocks once every group is done,
  /// not a single flat 'letter_drawing' flag.
  bool get _allLetterGroupsDone =>
      kLetterGroups.every((g) => _completed.contains(g.id));

  Widget _buildTabSwitcher() {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: context.colors.surfaceMuted,
          borderRadius: AppRadius.lgAll,
        ),
        child: Row(
          children: [
            _tabBtn(0, t.tabLearn, unlocked: true),
            _tabBtn(1, t.tabDraw, unlocked: _drawUnlocked),
            _voiceTabBtn(),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(int index, String label, {required bool unlocked}) {
    final active = _tab == index;
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!unlocked) {
            // "Letters" is the curriculum level name — deliberately not
            // translated, see plan: curriculum/level names stay as-is
            // regardless of interface language.
            FkToast.show(context,
                AppLocalizations.of(context)!.lockedLevelSnackbar('Letters'),
                type: FkToastType.info);
            return;
          }
          setState(() => _tab = index);
        },
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.transition,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? colors.primary : Colors.transparent,
            borderRadius: AppRadius.mdAll,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          // FittedBox: a longer word in some languages (e.g. Russian
          // "Рисование") can be wider than this tab's share of the 3-way
          // switcher — Row doesn't shrink non-flexible children to fit, so
          // without this it overflows instead of scaling down.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: active
                        ? Colors.white
                        : unlocked
                            ? colors.textSecondary
                            : colors.textTertiary,
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
      ),
    );
  }

  /// Pushes "My Voice" (AAC) as its own screen rather than a third
  /// setState-driven `_tab` value: unlike O'rganish/Chizish it's a
  /// self-contained screen (own header, own back button — see
  /// aac_home_screen.dart) and, as a communication tool, is never mastery-
  /// gated like `_drawUnlocked`.
  Widget _voiceTabBtn() {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AacHomeScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          // Same FittedBox reasoning as the other two tabs — keeps this
          // tab single-line and matching their height instead of a longer
          // label wrapping to 2 lines and misaligning the tab bar.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppLocalizations.of(context)!.tabVoice,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.colors.textSecondary,
                  ),
            ),
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
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
          sliver: SliverToBoxAdapter(
            child: Text(
              AppLocalizations.of(context)!.levelsTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(color: context.colors.textPrimary),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _buildLearnCard(_levels[i], i),
              childCount: _levels.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              // Shorter cards (was 0.92) to make room for a much bigger
              // icon circle below — easier for young/motor-impaired
              // children to recognize and tap accurately.
              childAspectRatio: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLearnCard(_LevelItem level, int index) {
    final colors = context.colors;
    Color cardBg;
    Color borderColor;
    if (level.locked) {
      cardBg = colors.surfaceMuted;
      borderColor = Colors.transparent;
    } else if (level.done) {
      cardBg = colors.successSoft;
      borderColor = colors.success;
    } else {
      cardBg = colors.primarySoft;
      borderColor = colors.primary.withValues(alpha: 0.5);
    }

    return _GridEntrance(
      index: index,
      child: _PressableCard(
        onTap: level.locked ? null : () => _onLevelTap(level),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: borderColor, width: 2),
            boxShadow: level.locked ? null : AppShadows.soft,
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
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: level.locked
                          ? colors.surface.withValues(alpha: 0.5)
                          : colors.surface,
                      boxShadow: level.locked ? null : AppShadows.soft,
                    ),
                    child: Center(child: _buildLearnIcon(level)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    level.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: level.locked
                              ? colors.textTertiary
                              : colors.textPrimary,
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
    final colors = context.colors;
    if (level.letter != null) {
      return Text(
        level.letter!,
        style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 66,
              color: level.locked ? colors.textTertiary : colors.textPrimary,
            ),
      );
    }
    if (level.customWidget != null) {
      return Opacity(
          opacity: level.locked ? 0.45 : 1.0, child: level.customWidget!);
    }
    if (level.emoji != null) {
      return Text(
        level.emoji!,
        style:
            TextStyle(fontSize: 64, color: level.locked ? Colors.grey : null),
      );
    }
    return const SizedBox();
  }

  // ── Chizish tab ───────────────────────────────────────────────────────────

  Widget _buildDrawTab() {
    final colors = context.colors;
    final t = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('✏️', t.drawSectionHeader),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.92,
            children: [
              _drawCard(
                id: 'shapes',
                title: t.drawTitleShapes,
                badge: '✏️',
                badgeColor: colors.primary,
                icon: const _ShapesIcon(),
                locked: false,
                index: 0,
                cardColor: colors.successSoft,
                borderColor: colors.success,
              ),
              _drawCard(
                id: 'letters_draw',
                title: t.drawTitleLetters,
                badge: '✏️',
                badgeColor: colors.primary,
                icon: Text('A',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontSize: 44, color: colors.textPrimary)),
                locked: _lockedUnless('shapes'),
                index: 1,
                cardColor: colors.successSoft,
                borderColor: colors.success,
              ),
              _drawCard(
                  id: 'numbers_draw',
                  title: t.drawTitleNumbers,
                  badge: '✏️',
                  badgeColor: colors.primary,
                  icon: Text('123',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              fontSize: 26, color: colors.textSecondary)),
                  locked: !_isAdmin && !_allLetterGroupsDone,
                  index: 2),
              _drawCard(
                  id: 'objects',
                  title: t.drawTitleObjects,
                  badge: '✏️',
                  badgeColor: colors.primary,
                  icon: const Text('🏠', style: TextStyle(fontSize: 40)),
                  locked: _lockedUnless('number_drawing'),
                  index: 3),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _sectionHeader('🖌️', t.paintSectionHeader),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.92,
            children: [
              _drawCard(
                id: 'fruits_color',
                title: t.colorTitleFruits,
                badge: '🖌️',
                badgeColor: colors.danger,
                icon: const Text('🍎', style: TextStyle(fontSize: 42)),
                locked: false,
                index: 0,
                cardColor: colors.warningSoft,
                borderColor: colors.warning,
              ),
              _drawCard(
                  id: 'animals_color',
                  title: t.colorTitleAnimals,
                  badge: '🖌️',
                  badgeColor: colors.danger,
                  icon: const Text('🦁', style: TextStyle(fontSize: 40)),
                  locked: _lockedUnless('fruits_color'),
                  index: 1),
              _drawCard(
                  id: 'nature',
                  title: t.colorTitleNature,
                  badge: '🖌️',
                  badgeColor: colors.danger,
                  icon: const Text('🌸', style: TextStyle(fontSize: 40)),
                  locked: _lockedUnless('animals_color'),
                  index: 2),
              _drawCard(
                  id: 'transport',
                  title: t.colorTitleTransport,
                  badge: '🖌️',
                  badgeColor: colors.danger,
                  icon: const Text('🚗', style: TextStyle(fontSize: 40)),
                  locked: _lockedUnless('nature_color'),
                  index: 3),
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
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: context.colors.textPrimary),
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
    required int index,
    Color? cardColor,
    Color? borderColor,
  }) {
    final colors = context.colors;
    return _GridEntrance(
      index: index,
      child: _PressableCard(
        onTap: locked ? null : () => _onDrawTap(id),
        child: Container(
          decoration: BoxDecoration(
            color: locked
                ? colors.surfaceMuted
                : (cardColor ?? colors.surfaceMuted),
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: locked
                  ? Colors.transparent
                  : (borderColor ?? Colors.transparent),
              width: 2,
            ),
            boxShadow: locked ? null : AppShadows.soft,
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
                            color:
                                locked ? colors.surfaceMuted : colors.surface,
                            boxShadow: locked ? null : AppShadows.soft,
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
                                child: Text(badge,
                                    style: const TextStyle(fontSize: 14)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color:
                              locked ? colors.textTertiary : colors.textPrimary,
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
}

// ── Grid card motion ─────────────────────────────────────────────────────────

/// Staggered fade + slide-up entrance for a grid card — the canonical
/// pattern documented on [AppMotion] (`entranceSlideOffset`/`staggerDelay`),
/// applied here to the level/draw grids. Skips the animation under reduced
/// motion rather than merely shortening it, per [AppMotion.reduced]'s
/// contract.
class _GridEntrance extends StatelessWidget {
  final int index;
  final Widget child;

  const _GridEntrance({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: AppMotion.base + AppMotion.staggerDelay * index,
      curve: AppMotion.entrance,
      builder: (_, v, builtChild) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, AppMotion.entranceSlideOffset * (1 - v)),
          child: builtChild,
        ),
      ),
      child: child,
    );
  }
}

/// Press-scale + haptic feedback for a tappable grid card — mirrors
/// [FkCategoryCard]'s press contract so level/draw cards feel consistent
/// with the rest of the redesigned surfaces. `onTap == null` (locked cards)
/// disables both the tap and the press animation.
class _PressableCard extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _PressableCard({required this.onTap, required this.child});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
    lowerBound: AppMotion.pressScale,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (widget.onTap == null) return;
    if (!AppMotion.reduced(context)) {
      _scaleController.animateTo(pressed ? AppMotion.pressScale : 1.0,
          curve: AppMotion.press);
    }
    if (pressed) HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) =>
            Transform.scale(scale: _scaleController.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _NumbersIcon extends StatelessWidget {
  const _NumbersIcon();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('1',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontSize: 32, color: colors.danger)),
        Text('2',
            style: Theme.of(context)
                .textTheme
                .headlineLarge
                ?.copyWith(fontSize: 38, color: colors.primary)),
        Text('3',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontSize: 30, color: colors.success)),
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
      painter: _ShapesIconPainter(context.colors),
    );
  }
}

class _ShapesIconPainter extends CustomPainter {
  final AppColorTheme colors;
  const _ShapesIconPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    // Square
    final pSquare = Paint()
      ..color = colors.primary
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(
              2, size.height * 0.3, size.height * 0.6, size.height * 0.6),
          const Radius.circular(4)),
      pSquare,
    );
    // Circle
    final pCircle = Paint()
      ..color = colors.danger
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.38),
        size.height * 0.32, pCircle);
    // Triangle
    final pTri = Paint()
      ..color = colors.success
      ..style = PaintingStyle.fill;
    final triPath = Path()
      ..moveTo(size.width * 0.82, size.height * 0.58)
      ..lineTo(size.width, size.height * 0.58)
      ..lineTo(size.width * 0.91, size.height * 0.35)
      ..close();
    canvas.drawPath(triPath, pTri);
  }

  @override
  bool shouldRepaint(covariant _ShapesIconPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
