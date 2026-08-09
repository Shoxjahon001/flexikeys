import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Dev-only visual QA surface — not linked from any real in-app navigation,
/// route only registered when `kDebugMode` (see `core/router.dart`).
///
/// Renders every Phase 2 component (`lib/design_system/components/`) plus
/// the Phase 1 atoms it hasn't yet replaced, under four independent toggles:
/// theme (light/dark), text scale (1.0×/1.3×), text direction (LTR/RTL),
/// and per-widget state variants (default/pressed/disabled/loading/selected)
/// shown side by side rather than behind a toggle, since state is usually
/// prop-driven, not global.
///
/// Note: atoms migrated in Phase 1 (`FkButton`, `FkCard`, `FkAvatar`, etc.)
/// still read the static `AppColors` class directly, not `context.colors` —
/// that's documented Phase 1 debt (see CLAUDE.md), not a bug in this
/// gallery. They will visibly NOT change between light/dark; only
/// components built against [AppColorTheme] will. That contrast is the
/// point — it's what "not yet dark-ready" looks like. All Phase 2
/// components below (everything under "Component Library") ARE built
/// against `context.colors` and should visibly repaint on the toggle.
class DesignGalleryScreen extends StatefulWidget {
  const DesignGalleryScreen({super.key});

  @override
  State<DesignGalleryScreen> createState() => _DesignGalleryScreenState();
}

class _DesignGalleryScreenState extends State<DesignGalleryScreen> {
  Brightness _brightness = Brightness.light;
  double _textScale = 1.0;
  bool _rtl = false;

  @override
  Widget build(BuildContext context) {
    final themeData = _brightness == Brightness.light
        ? FlexiKeysTheme.light()
        : FlexiKeysTheme.dark();

    return Theme(
      data: themeData,
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(_textScale),
          ),
          child: Directionality(
            textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Design Gallery (dev only)'),
              ),
              body: Column(
                children: [
                  _ControlBar(
                    brightness: _brightness,
                    onBrightnessChanged: (b) => setState(() => _brightness = b),
                    textScale: _textScale,
                    onTextScaleChanged: (s) => setState(() => _textScale = s),
                    rtl: _rtl,
                    onRtlChanged: (v) => setState(() => _rtl = v),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      children: const [
                        _Section(title: 'AppColorTheme (dark-ready)', children: [
                          _ColorSwatchRow(),
                        ]),
                        _ComponentLibrarySections(),
                        _Section(title: 'Legacy: FkButton (Phase 1)', children: [
                          _LegacyButtonRow(),
                        ]),
                        _Section(title: 'Legacy: FkCard / FkAvatar / FkAudioButton / FkCoinCounter (Phase 1)', children: [
                          _LegacyMiscRow(),
                        ]),
                        _Section(title: 'Legacy: FkProgressPath (Phase 1)', children: [
                          FkProgressPath(levels: [
                            FkLevelNode(ordinal: 1, label: 'Letters', state: FkLevelNodeState.mastered),
                            FkLevelNode(ordinal: 2, label: 'Numbers', state: FkLevelNodeState.active),
                            FkLevelNode(ordinal: 3, label: 'Shapes', state: FkLevelNodeState.locked),
                          ]),
                        ]),
                        _Section(title: 'AAC: AacCategoryTile', children: [
                          _AacCategoryTileRow(),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  final Brightness brightness;
  final ValueChanged<Brightness> onBrightnessChanged;
  final double textScale;
  final ValueChanged<double> onTextScaleChanged;
  final bool rtl;
  final ValueChanged<bool> onRtlChanged;

  const _ControlBar({
    required this.brightness,
    required this.onBrightnessChanged,
    required this.textScale,
    required this.onTextScaleChanged,
    required this.rtl,
    required this.onRtlChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.surfaceMuted,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<Brightness>(
            segments: const [
              ButtonSegment(value: Brightness.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
              ButtonSegment(value: Brightness.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
            ],
            selected: {brightness},
            onSelectionChanged: (s) => onBrightnessChanged(s.first),
          ),
          SegmentedButton<double>(
            segments: const [
              ButtonSegment(value: 1.0, label: Text('1.0×')),
              ButtonSegment(value: 1.3, label: Text('1.3×')),
            ],
            selected: {textScale},
            onSelectionChanged: (s) => onTextScaleChanged(s.first),
          ),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('LTR')),
              ButtonSegment(value: true, label: Text('RTL')),
            ],
            selected: {rtl},
            onSelectionChanged: (s) => onRtlChanged(s.first),
          ),
        ],
      ),
    );
  }
}

/// Every `lib/design_system/components/` widget, grouped by kind, each
/// shown across its meaningful states (default / pressed·selected /
/// disabled / loading) side by side.
class _ComponentLibrarySections extends StatelessWidget {
  const _ComponentLibrarySections();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(title: 'FkPrimaryButton', children: [_PrimaryButtonRow()]),
        _Section(title: 'FkSecondaryButton', children: [_SecondaryButtonRow()]),
        _Section(title: 'FkIconButton', children: [_IconButtonRow()]),
        _Section(title: 'FkCategoryCard', children: [_CategoryCardRow()]),
        _Section(title: 'FkContentCard', children: [_ContentCardRow()]),
        _Section(title: 'FkSpeakButton / FkPlayButton', children: [_SpeakAndPlayRow()]),
        _Section(title: 'FkFilterChipBar', children: [_FilterChipBarDemo()]),
        _Section(title: 'FkListRow', children: [_ListRowDemo()]),
        _Section(title: 'FkStepContainer', children: [_StepContainerDemo()]),
        _Section(title: 'FkTextField', children: [_TextFieldRow()]),
        _Section(title: 'FkColorPicker', children: [_ColorPickerDemo()]),
        _Section(title: 'FkBottomNav', children: [_BottomNavDemo()]),
        _Section(title: 'FkSideNav', children: [_SideNavDemo()]),
        _Section(title: 'FkPageIndicator', children: [_PageIndicatorRow()]),
        _Section(title: 'FkEmptyState', children: [_EmptyStateDemo()]),
        _Section(title: 'FkSkeleton', children: [_SkeletonRow()]),
        _Section(title: 'FkAvatar (shared, Phase 1)', children: [_AvatarRow()]),
        _Section(title: 'FkSectionHeader', children: [
          FkSectionHeader(title: 'Recent activity', actionLabel: 'See all', onAction: null),
        ]),
        _Section(title: 'FkAppBar / FkScaffold', children: [_AppBarDemo()]),
      ],
    );
  }
}

class _PrimaryButtonRow extends StatelessWidget {
  const _PrimaryButtonRow();
  @override
  Widget build(BuildContext context) => Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.lg, children: [
        FkPrimaryButton(label: 'Save', onPressed: () {}, leadingIcon: const Icon(Icons.check_rounded)),
        const FkPrimaryButton(label: 'Disabled'),
        const FkPrimaryButton(label: 'Loading', loading: true),
      ]);
}

class _SecondaryButtonRow extends StatelessWidget {
  const _SecondaryButtonRow();
  @override
  Widget build(BuildContext context) => Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.lg, children: [
        FkSecondaryButton(label: 'Repeat', onPressed: () {}, leadingIcon: const Icon(Icons.replay_rounded)),
        const FkSecondaryButton(label: 'Disabled'),
      ]);
}

class _IconButtonRow extends StatelessWidget {
  const _IconButtonRow();
  @override
  Widget build(BuildContext context) => Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.lg, crossAxisAlignment: WrapCrossAlignment.center, children: [
        FkIconButton(icon: Icons.favorite_border_rounded, semanticLabel: 'Favorite', onPressed: () {}, size: FkIconButtonSize.small),
        FkIconButton(icon: Icons.favorite_border_rounded, semanticLabel: 'Favorite', onPressed: () {}),
        FkIconButton(icon: Icons.favorite_border_rounded, semanticLabel: 'Favorite', onPressed: () {}, size: FkIconButtonSize.large),
        FkIconButton(icon: Icons.share_rounded, semanticLabel: 'Share', onPressed: () {}, variant: FkIconButtonVariant.filled),
        const FkIconButton(icon: Icons.favorite_border_rounded, semanticLabel: 'Favorite'),
      ]);
}

class _CategoryCardRow extends StatelessWidget {
  const _CategoryCardRow();
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 132,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (var i = 0; i < AppColors.categoryPalette.length; i++) // ignore: static-tokens
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: SizedBox(
                width: 160,
                child: FkCategoryCard(
                  label: ['Daily', 'Feelings', 'Needs', 'People', 'Places', 'Play'][i],
                  paletteEntry: AppColors.categoryPalette[i], // ignore: static-tokens
                  illustration: const Icon(Icons.spa_rounded, size: 40),
                  onTap: () {},
                ),
              ),
            ),
        ]),
      );
}

class _ContentCardRow extends StatelessWidget {
  const _ContentCardRow();
  @override
  Widget build(BuildContext context) => Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.lg, children: [
        SizedBox(
          width: 150,
          child: FkContentCard(
            image: Container(color: context.colors.primarySoft, child: const Icon(Icons.pets_rounded, size: 40)),
            caption: 'Cow',
            onTap: () {},
            onSpeak: () {},
          ),
        ),
        SizedBox(
          width: 150,
          child: FkContentCard(
            image: Container(color: context.colors.primarySoft, child: const Icon(Icons.pets_rounded, size: 40)),
            caption: 'Speaking now',
            onTap: () {},
            onSpeak: () {},
            speaking: true,
          ),
        ),
      ]);
}

class _SpeakAndPlayRow extends StatelessWidget {
  const _SpeakAndPlayRow();
  @override
  Widget build(BuildContext context) => Wrap(spacing: AppSpacing.xl, runSpacing: AppSpacing.lg, crossAxisAlignment: WrapCrossAlignment.center, children: [
        FkSpeakButton(onPressed: () {}),
        FkSpeakButton(onPressed: () {}, playing: true),
        FkPlayButton(playing: false, onPressed: () {}),
        FkPlayButton(playing: true, onPressed: () {}),
      ]);
}

class _FilterChipBarDemo extends StatefulWidget {
  const _FilterChipBarDemo();
  @override
  State<_FilterChipBarDemo> createState() => _FilterChipBarDemoState();
}

class _FilterChipBarDemoState extends State<_FilterChipBarDemo> {
  String _selected = 'all';
  @override
  Widget build(BuildContext context) => FkFilterChipBar(
        chips: const [
          FkFilterChip(label: 'All', value: 'all'),
          FkFilterChip(label: 'Favorites', value: 'fav'),
          FkFilterChip(label: 'Recent', value: 'recent'),
        ],
        selectedValue: _selected,
        onSelected: (v) => setState(() => _selected = v),
      );
}

class _ListRowDemo extends StatelessWidget {
  const _ListRowDemo();
  @override
  Widget build(BuildContext context) => Column(children: [
        FkListRow(
          leading: Container(color: context.colors.primarySoft),
          label: 'Display language',
          subtitle: 'English',
          onTap: () {},
        ),
        const FkListRow(label: 'No chevron, no divider', showChevron: false, showDivider: false),
      ]);
}

class _StepContainerDemo extends StatelessWidget {
  const _StepContainerDemo();
  @override
  Widget build(BuildContext context) => FkStepContainer(
        stepNumber: 1,
        title: 'Add a photo',
        child: Text('Step content slot',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
      );
}

class _TextFieldRow extends StatelessWidget {
  const _TextFieldRow();
  @override
  Widget build(BuildContext context) => const Column(children: [
        FkTextField(labelText: 'Card name', hintText: 'e.g. Water'),
        SizedBox(height: AppSpacing.lg),
        FkTextField(labelText: 'Card name', errorText: 'This field is required'),
      ]);
}

class _ColorPickerDemo extends StatefulWidget {
  const _ColorPickerDemo();
  @override
  State<_ColorPickerDemo> createState() => _ColorPickerDemoState();
}

class _ColorPickerDemoState extends State<_ColorPickerDemo> {
  int _selected = 0;
  @override
  Widget build(BuildContext context) =>
      FkColorPicker(selectedIndex: _selected, onSelected: (i) => setState(() => _selected = i));
}

class _BottomNavDemo extends StatelessWidget {
  const _BottomNavDemo();
  @override
  Widget build(BuildContext context) => FkBottomNav(
        items: const [
          FkBottomNavItem(icon: Icons.home_outlined, filledIcon: Icons.home_rounded, label: 'Home'),
          FkBottomNavItem(icon: Icons.grid_view_outlined, filledIcon: Icons.grid_view_rounded, label: 'Cards'),
          FkBottomNavItem(icon: Icons.bar_chart_outlined, filledIcon: Icons.bar_chart_rounded, label: 'Progress'),
          FkBottomNavItem(icon: Icons.settings_outlined, filledIcon: Icons.settings_rounded, label: 'Settings'),
        ],
        currentIndex: 0,
        onTap: (_) {},
        onFabPressed: () {},
      );
}

class _SideNavDemo extends StatelessWidget {
  const _SideNavDemo();
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 320,
        child: FkSideNav(
          items: const [
            FkBottomNavItem(icon: Icons.home_outlined, filledIcon: Icons.home_rounded, label: 'Home'),
            FkBottomNavItem(icon: Icons.grid_view_outlined, filledIcon: Icons.grid_view_rounded, label: 'Cards'),
            FkBottomNavItem(icon: Icons.settings_outlined, filledIcon: Icons.settings_rounded, label: 'Settings'),
          ],
          currentIndex: 1,
          onTap: (_) {},
          profileCard: FkCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(children: [
                const FkAvatar(name: 'Alex Kim', size: 32),
                const SizedBox(width: AppSpacing.sm),
                Text('Alex', style: AppTypography.caption.copyWith(color: context.colors.textPrimary)), // ignore: static-tokens
              ]),
            ),
          ),
        ),
      );
}

class _PageIndicatorRow extends StatelessWidget {
  const _PageIndicatorRow();
  @override
  Widget build(BuildContext context) => const Wrap(spacing: AppSpacing.xxl, runSpacing: AppSpacing.md, crossAxisAlignment: WrapCrossAlignment.center, children: [
        FkPageIndicator(current: 3, total: 8),
        FkPageIndicator(current: 3, total: 8, dotVariant: true),
      ]);
}

class _EmptyStateDemo extends StatelessWidget {
  const _EmptyStateDemo();
  @override
  Widget build(BuildContext context) => FkEmptyState(
        illustration: const Icon(Icons.inbox_outlined, size: 56),
        title: 'No cards yet',
        description: 'Cards you create will show up here.',
        actionLabel: 'Create a card',
        onAction: () {},
      );
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();
  @override
  Widget build(BuildContext context) => const Row(children: [
        Expanded(child: FkSkeleton(height: 120)),
        SizedBox(width: AppSpacing.md),
        Expanded(child: FkSkeleton(height: 120)),
      ]);
}

class _AvatarRow extends StatelessWidget {
  const _AvatarRow();
  @override
  Widget build(BuildContext context) => const Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.lg, crossAxisAlignment: WrapCrossAlignment.end, children: [
        FkAvatar(name: 'Alex Kim', size: 32),
        FkAvatar(name: 'Alex Kim', size: 40),
        FkAvatar(name: 'Alex Kim', size: 56),
      ]);
}

class _AppBarDemo extends StatelessWidget {
  const _AppBarDemo();
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: AppRadius.mdAll,
        child: FkAppBar(
          title: 'My Voice',
          onBack: () {},
          actions: [
            FkAppBarAction(icon: Icons.star_border_rounded, semanticLabel: 'Favorite', onPressed: () {}),
            FkAppBarAction(icon: Icons.more_vert_rounded, semanticLabel: 'More', onPressed: () {}),
          ],
        ),
      );
}

class _LegacyButtonRow extends StatelessWidget {
  const _LegacyButtonRow();
  @override
  Widget build(BuildContext context) => Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.lg, children: [
        FkButton(label: 'Primary', onPressed: () {}),
        const FkButton(label: 'Secondary', variant: FkButtonVariant.secondary),
        const FkButton(label: 'Ghost', variant: FkButtonVariant.ghost),
        const FkButton(label: 'Disabled'),
        FkButton(label: 'Loading', onPressed: () {}, loading: true),
      ]);
}

class _LegacyMiscRow extends StatelessWidget {
  const _LegacyMiscRow();
  @override
  Widget build(BuildContext context) => Column(children: [
        const FkCard(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Text('Card content'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.lg, children: [
          const FkAvatar(name: 'Alex Kim'),
          FkAudioButton(onPressed: () {}),
          const FkCoinCounter(value: 42),
        ]),
      ]);
}

class _AacCategoryTileRow extends StatelessWidget {
  const _AacCategoryTileRow();
  @override
  Widget build(BuildContext context) => Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.lg, children: [
        AacCategoryTile(
          category: AacCategory.play,
          label: 'Play',
          glyph: const Text('🧸', style: TextStyle(fontSize: 32)),
          onTap: () {},
        ),
        AacCategoryTile(
          category: AacCategory.needs,
          label: 'Needs',
          glyph: const Text('🥤', style: TextStyle(fontSize: 32)),
          onTap: () {},
        ),
      ]);
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.huge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type metrics (size/weight) don't vary by theme, only color does
          // — and that part already comes from context.colors below.
          Text(title, style: AppTypography.h3.copyWith(color: context.colors.textPrimary)), // ignore: static-tokens
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}

class _ColorSwatchRow extends StatelessWidget {
  const _ColorSwatchRow();
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final swatches = <(String, Color)>[
      ('primary', c.primary),
      ('surface', c.surface),
      ('background', c.background),
      ('success', c.success),
      ('warning', c.warning),
      ('danger', c.danger),
      ('info', c.info),
    ];
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: swatches.map((s) {
        return Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: s.$2,
                borderRadius: AppRadius.smAll,
                border: Border.all(color: c.border),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(s.$1, style: AppTypography.caption.copyWith(color: c.textSecondary)), // ignore: static-tokens
          ],
        );
      }).toList(),
    );
  }
}
