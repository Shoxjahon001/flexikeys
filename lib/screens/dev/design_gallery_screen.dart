import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Dev-only visual QA surface — not linked from any real in-app navigation,
/// route only registered when `kDebugMode` (see `core/router.dart`).
///
/// Renders a representative sample of design-system components under a
/// toggleable light/dark `FlexiKeysTheme`, independent of the app's actual
/// root theme (which stays light-only — dark mode is deliberately not
/// shipped yet, see CLAUDE.md). Purpose: catch "looks wrong in dark" during
/// review, for components that are supposed to already be dark-ready via
/// [AppColorTheme]/`context.colors`, even though nothing ships dark today.
///
/// Note: atoms migrated in Phase 1 (`FkButton`, `FkCard`, `FkAvatar`, etc.)
/// still read the static `AppColors` class directly, not `context.colors` —
/// that's documented Phase 1 debt (see CLAUDE.md), not a bug in this
/// gallery. They will visibly NOT change between the two toggle states
/// below; only components written against [AppColorTheme] will. That
/// contrast is the point — it's what "not yet dark-ready" looks like.
class DesignGalleryScreen extends StatefulWidget {
  const DesignGalleryScreen({super.key});

  @override
  State<DesignGalleryScreen> createState() => _DesignGalleryScreenState();
}

class _DesignGalleryScreenState extends State<DesignGalleryScreen> {
  Brightness _brightness = Brightness.light;

  @override
  Widget build(BuildContext context) {
    final themeData = _brightness == Brightness.light
        ? FlexiKeysTheme.light()
        : FlexiKeysTheme.dark();

    return Theme(
      data: themeData,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Design Gallery (dev only)'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Center(
                  child: SegmentedButton<Brightness>(
                    segments: const [
                      ButtonSegment(
                        value: Brightness.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: Brightness.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {_brightness},
                    onSelectionChanged: (s) =>
                        setState(() => _brightness = s.first),
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            children: [
              _Section(title: 'AppColorTheme (dark-ready)', children: [
                _ColorSwatchRow(),
              ]),
              _Section(title: 'FkButton', children: [
                Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.lg, children: [
                  FkButton(label: 'Primary', onPressed: () {}),
                  const FkButton(
                    label: 'Secondary',
                    variant: FkButtonVariant.secondary,
                  ),
                  const FkButton(label: 'Ghost', variant: FkButtonVariant.ghost),
                  const FkButton(label: 'Disabled'),
                  FkButton(label: 'Loading', onPressed: () {}, loading: true),
                ]),
              ]),
              const _Section(title: 'FkCard', children: [
                FkCard(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Text('Card content'),
                  ),
                ),
              ]),
              _Section(title: 'FkAvatar / FkAudioButton / FkCoinCounter', children: [
                Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.lg, children: [
                  const FkAvatar(name: 'Alex Kim'),
                  FkAudioButton(onPressed: () {}),
                  const FkCoinCounter(value: 42),
                ]),
              ]),
              const _Section(title: 'FkProgressPath', children: [
                FkProgressPath(
                  levels: [
                    FkLevelNode(ordinal: 1, label: 'Letters', state: FkLevelNodeState.mastered),
                    FkLevelNode(ordinal: 2, label: 'Numbers', state: FkLevelNodeState.active),
                    FkLevelNode(ordinal: 3, label: 'Shapes', state: FkLevelNodeState.locked),
                  ],
                ),
              ]),
              _Section(title: 'AacCategoryTile', children: [
                Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.lg, children: [
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
                ]),
              ]),
            ],
          ),
        ),
      ),
    );
  }
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
