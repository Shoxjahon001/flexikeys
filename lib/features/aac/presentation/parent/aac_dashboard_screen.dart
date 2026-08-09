library aac_dashboard_screen;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/user_service.dart';
import '../../application/aac_dashboard_provider.dart';
import '../../data/aac_card_repository.dart';
import '../../domain/aac_card_def.dart';
import '../aac_glyphs.dart';
import 'aac_card_manager_screen.dart';
import 'aac_parent_settings_screen.dart';

/// The "My Voice" section of the parent dashboard — docs/aac_design_system.md
/// Phase 4. Lives as one tab's content inside ParentHomeScreen's existing
/// Scaffold/IndexedStack (matches _HomeTab: no own Scaffold/background).
class AacDashboardScreen extends ConsumerStatefulWidget {
  final String childId;

  const AacDashboardScreen({super.key, required this.childId});

  @override
  ConsumerState<AacDashboardScreen> createState() => _AacDashboardScreenState();
}

class _AacDashboardScreenState extends ConsumerState<AacDashboardScreen> {
  Map<String, AacCardDef> _cardsById = {};
  AacLanguage _language = AacLanguage.en;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final results = await Future.wait([
      AacCardRepository.instance.loadAllCards(),
      UserService.getLanguage(),
    ]);
    final cards = results[0] as List<AacCardDef>;
    final code = results[1] as String;
    final lang = AacLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AacLanguage.en,
    );
    if (mounted) {
      setState(() {
        _cardsById = {for (final c in cards) c.id: c};
        _language = lang;
      });
    }
  }

  String _labelFor(String cardId) {
    final card = _cardsById[cardId];
    if (card == null) return cardId;
    return card.label[_language] ?? card.label[AacLanguage.en] ?? cardId;
  }

  Future<void> _refresh() async {
    ref.invalidate(aacStatsProvider(widget.childId));
    ref.invalidate(aacInsightsProvider(widget.childId));
    await _loadCards();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(aacStatsProvider(widget.childId));
    final insightsAsync = ref.watch(aacInsightsProvider(widget.childId));

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(FkSpacing.sm),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(t.navVoiceTab, style: FkTextStyles.adultHeadline),
              ),
              IconButton(
                tooltip: t.manageCardsTooltip,
                icon: const Icon(Icons.style_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AacCardManagerScreen(),
                  ),
                ),
              ),
              IconButton(
                tooltip: t.settingsTitle,
                icon: const Icon(Icons.settings_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AacParentSettingsScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: FkSpacing.xs),
          Text(
            t.myVoiceDashboardSubheader,
            style: FkTextStyles.adultBody,
          ),
          const SizedBox(height: FkSpacing.sm),
          Text(t.statTodayPill, style: FkTextStyles.adultHeadline),
          const SizedBox(height: FkSpacing.xs),
          statsAsync.when(
            data: (stats) => _TodayStats(
              stats: stats.today,
              labelFor: _labelFor,
            ),
            loading: () => const _CardSkeleton(height: 100),
            error: (_, __) => _ErrorCard(label: t.todayActivityLoadError),
          ),
          const SizedBox(height: FkSpacing.md),
          Text(t.thisWeekSectionHeader, style: FkTextStyles.adultHeadline),
          const SizedBox(height: FkSpacing.xs),
          statsAsync.when(
            data: (stats) => _TrendChart(trend: stats.trend),
            loading: () => const _CardSkeleton(height: 180),
            error: (_, __) => _ErrorCard(label: t.weekTrendLoadError),
          ),
          const SizedBox(height: FkSpacing.md),
          insightsAsync.when(
            data: (result) => result.insights.isEmpty
                ? const SizedBox.shrink()
                : _InsightsSection(result: result),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _TodayStats extends StatelessWidget {
  final List<AacTodayCardStat> stats;
  final String Function(String cardId) labelFor;

  const _TodayStats({required this.stats, required this.labelFor});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return FkCard(
        child: Padding(
          padding: const EdgeInsets.all(FkSpacing.sm),
          child: Text(AppLocalizations.of(context)!.noCardsTappedToday,
              style: FkTextStyles.adultBody),
        ),
      );
    }
    final aac = AacTheme.of(context);
    return Wrap(
      spacing: FkSpacing.xs,
      runSpacing: FkSpacing.xs,
      children: stats.take(8).map((s) {
        final category = _categoryOrNull(s.category);
        final color = category == null ? FkColors.lavender : aac.colorFor(category);
        return FkCard(
          color: Color.alphaBlend(color.withValues(alpha: 0.12), Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: FkSpacing.sm, vertical: FkSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emojiForCard(s.cardId), style: const TextStyle(fontSize: 20)),
              const SizedBox(width: FkSpacing.xxs),
              Text(
                '${labelFor(s.cardId)} ×${s.count}',
                style: FkTextStyles.adultBody.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<AacTrendPoint> trend;

  const _TrendChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return FkCard(
        child: Padding(
          padding: const EdgeInsets.all(FkSpacing.sm),
          child: Text(AppLocalizations.of(context)!.notEnoughWeeklyActivity,
              style: FkTextStyles.adultBody),
        ),
      );
    }

    final t = AppLocalizations.of(context)!;
    final aac = AacTheme.of(context);
    final days = <DateTime>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      days.add(DateTime(d.year, d.month, d.day));
    }

    // Total taps per day (summed across categories) — the color-per-category
    // breakdown is available in the raw data but a single stacked bar per
    // day keeps the chart readable at dashboard-card size; per-category
    // detail lives in the "Today" stats above instead of doubling up here.
    double maxY = 1;
    final totals = <DateTime, double>{};
    final dominantColor = <DateTime, Color>{};
    final dominantCount = <DateTime, int>{};
    for (final day in days) {
      totals[day] = 0;
      dominantColor[day] = FkColors.lavender;
      dominantCount[day] = 0;
    }
    for (final point in trend) {
      final day = DateTime(point.date.year, point.date.month, point.date.day);
      if (!totals.containsKey(day)) continue;
      totals[day] = (totals[day] ?? 0) + point.count;
      if (point.count > (dominantCount[day] ?? 0)) {
        dominantCount[day] = point.count;
        final category = _categoryOrNull(point.category);
        dominantColor[day] = category == null ? FkColors.lavender : aac.colorFor(category);
      }
      if ((totals[day] ?? 0) > maxY) maxY = totals[day]!;
    }

    return FkCard(
      padding: const EdgeInsets.fromLTRB(FkSpacing.xs, FkSpacing.sm, FkSpacing.sm, FkSpacing.xs),
      child: SizedBox(
        height: 160,
        child: BarChart(
          BarChartData(
            maxY: maxY * 1.2,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final i = value.toInt();
                    if (i < 0 || i >= days.length) return const SizedBox.shrink();
                    final weekdays = [
                      t.weekdayMonShort,
                      t.weekdayTueShort,
                      t.weekdayWedShort,
                      t.weekdayThuShort,
                      t.weekdayFriShort,
                      t.weekdaySatShort,
                      t.weekdaySunShort,
                    ];
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        weekdays[days[i].weekday - 1],
                        style: FkTextStyles.adultCaption,
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (int i = 0; i < days.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: totals[days[i]] ?? 0,
                      color: dominantColor[days[i]],
                      width: 18,
                      borderRadius: BorderRadius.circular(FkRadii.xs),
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

class _InsightsSection extends StatelessWidget {
  final AacInsightsResult result;

  const _InsightsSection({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.insightsSectionHeader,
            style: FkTextStyles.adultHeadline),
        const SizedBox(height: FkSpacing.xs),
        ...result.insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: FkSpacing.xs),
              child: FkCard(
                color: insight.tone == 'attention'
                    ? FkColors.sunshine.withValues(alpha: 0.15)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(FkSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.headline,
                        style: FkTextStyles.adultBody.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: FkSpacing.xxs),
                      Text(insight.body, style: FkTextStyles.adultBody),
                    ],
                  ),
                ),
              ),
            )),
        if (result.disclaimer != null)
          Padding(
            padding: const EdgeInsets.only(top: FkSpacing.xxs),
            child: Text(
              result.disclaimer!,
              style: FkTextStyles.adultCaption.copyWith(color: FkColors.disabledInk),
            ),
          ),
      ],
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  final double height;
  const _CardSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return FkCard(
      child: SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String label;
  const _ErrorCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return FkCard(
      child: Padding(
        padding: const EdgeInsets.all(FkSpacing.sm),
        child: Text(label, style: FkTextStyles.adultBody),
      ),
    );
  }
}

AacCategory? _categoryOrNull(String name) {
  for (final c in AacCategory.values) {
    if (c.name == name) return c;
  }
  return null;
}
