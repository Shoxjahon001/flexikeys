library parent_home_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/user_service.dart';
import '../../aac/presentation/parent/aac_dashboard_screen.dart';
import '../application/parent_provider.dart';
import '../domain/parent_models.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';
import 'assistant/assistant_screen.dart';

/// Parent home dashboard — shows today's summary, streak, and adaptation feed.
/// Adult design variant: denser, still pastel/rounded.
class ParentHomeScreen extends ConsumerStatefulWidget {
  final String childId;

  /// Which tab to open on (0=Home, 1=Progress, 2=My Voice, 3=Ask AI) — lets
  /// callers deep link straight into a tab instead of always landing on Home.
  final int initialTab;

  const ParentHomeScreen(
      {super.key, required this.childId, this.initialTab = 0});

  @override
  ConsumerState<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends ConsumerState<ParentHomeScreen> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(childSummaryProvider(widget.childId));

    return Scaffold(
      backgroundColor: FkColors.background,
      appBar: AppBar(
        backgroundColor: FkColors.background,
        elevation: 0,
        title: summaryAsync.when(
          data: (s) => Text(
            s.displayName,
            style: FkTextStyles.adultHeadline,
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => Text(AppLocalizations.of(context)!.dashboardTitle),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(childId: widget.childId),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _TabBar(current: _tab, onTap: (i) => setState(() => _tab = i)),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _HomeTab(childId: widget.childId),
                ProgressScreen(childId: widget.childId),
                AacDashboardScreen(childId: widget.childId),
                AssistantScreen(childId: widget.childId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final int current;
  final void Function(int) onTap;

  const _TabBar({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final labels = [t.navHome, t.navProgressTab, t.navVoiceTab, t.navAskAiTab];
    const icons = [
      Icons.home_rounded,
      Icons.bar_chart_rounded,
      Icons.record_voice_over_rounded,
      Icons.chat_bubble_rounded,
    ];

    return Container(
      color: FkColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: FkSpacing.sm),
      child: Row(
        children: List.generate(
          4,
          (i) => Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: FkDurations.fast,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          current == i ? FkColors.lavender : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[i],
                      size: 20,
                      color: current == i
                          ? FkColors.lavender
                          : FkColors.disabledInk,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      labels[i],
                      style: FkTextStyles.adultCaption.copyWith(
                        color: current == i
                            ? FkColors.lavender
                            : FkColors.disabledInk,
                        fontWeight:
                            current == i ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  final String childId;
  const _HomeTab({required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(childSummaryProvider(childId));
    // Uses the parent dashboard's own current display language, not the
    // child's stored (initial-default) ui_language — a parent who changes
    // the dashboard's language should see backend-rendered adaptation text
    // in that same language immediately, without touching the child record.
    final adaptAsync = ref.watch(
      adaptationsProvider(
        (childId: childId, uiLanguage: UserService.uiLanguageNotifier.value),
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(FkSpacing.sm),
      children: [
        summaryAsync.when(
          data: (s) => _TodayCard(summary: s),
          loading: () => const _CardSkeleton(height: 140),
          error: (_, __) => _ErrorCard(label: t.todayActivityLoadError),
        ),
        const SizedBox(height: FkSpacing.sm),
        Text(t.adaptationsSectionHeader, style: FkTextStyles.adultHeadline),
        const SizedBox(height: FkSpacing.xs),
        Text(
          t.adaptationsBody,
          style: FkTextStyles.adultBody,
        ),
        const SizedBox(height: FkSpacing.sm),
        adaptAsync.when(
          data: (items) => items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: FkSpacing.md),
                  child: Text(
                    t.noAdjustmentsYet,
                    style: FkTextStyles.adultBody,
                  ),
                )
              : Column(
                  children:
                      items.map((item) => _AdaptationCard(item: item)).toList(),
                ),
          loading: () => const _CardSkeleton(height: 80),
          error: (_, __) => _ErrorCard(label: t.feedLoadError),
        ),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  final ChildSummary summary;
  const _TodayCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return FkCard(
      child: Padding(
        padding: const EdgeInsets.all(FkSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: _StatPill(
                icon: Icons.timer_rounded,
                label: t.statTodayPill,
                value: '${summary.todayMinutes.toStringAsFixed(0)} min',
              ),
            ),
            Expanded(
              child: _StatPill(
                icon: Icons.check_circle_rounded,
                label: t.statItemsPill,
                value: '${summary.todayItems}',
              ),
            ),
            Expanded(
              child: _StatPill(
                icon: Icons.local_fire_department_rounded,
                label: t.statStreakPill,
                value: '${summary.streakDays}d',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: FkColors.lavender),
        const SizedBox(height: 4),
        Text(value, style: FkTextStyles.adultHeadline),
        Text(label, style: FkTextStyles.adultCaption),
      ],
    );
  }
}

class _AdaptationCard extends StatelessWidget {
  final AdaptationFeedItem item;
  const _AdaptationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: FkSpacing.xs),
      child: FkCard(
        child: Padding(
          padding: const EdgeInsets.all(FkSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: FkColors.lavender,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: FkColors.ink,
                ),
              ),
              const SizedBox(width: FkSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.sentence, style: FkTextStyles.adultBody),
                    const SizedBox(height: 2),
                    Text(
                      _relativeDate(t, item.changedAt),
                      style: FkTextStyles.adultCaption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeDate(AppLocalizations t, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return t.relativeToday;
    if (diff.inDays == 1) return t.relativeYesterday;
    return t.relativeDaysAgo(diff.inDays);
  }
}

class _CardSkeleton extends StatelessWidget {
  final double height;
  const _CardSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: FkColors.disabled.withValues(alpha: 0.4),
        borderRadius: FkRadii.mdAll,
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String label;
  const _ErrorCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FkSpacing.xs),
      child: Text(label, style: FkTextStyles.adultBody),
    );
  }
}
