library progress_screen;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/app_localizations.dart';
import '../application/parent_provider.dart';
import '../domain/parent_models.dart';

/// Parent progress view — charts, mastery grid, adaptation feed.
class ProgressScreen extends ConsumerStatefulWidget {
  final String childId;

  const ProgressScreen({super.key, required this.childId});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String _metric = 'accuracy';
  int _rangeDays = 14;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final tsAsync = ref.watch(
      timeseriesProvider((
        childId: widget.childId,
        metric: _metric,
        rangeDays: _rangeDays,
      )),
    );
    final skillsAsync = ref.watch(
      skillsProvider((childId: widget.childId, language: 'en')),
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ── Metric picker ──────────────────────────────────────────────
        _MetricPicker(
          current: _metric,
          onChanged: (m) => setState(() => _metric = m),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Line chart ────────────────────────────────────────────────
        FkCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              height: 180,
              child: tsAsync.when(
                data: (points) => _TimeseriesChart(
                  points: points,
                  metric: _metric,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(t.chartLoadError, style: textTheme.bodyLarge),
                ),
              ),
            ),
          ),
        ),

        // ── Range picker ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (final days in [7, 14, 30])
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: _RangeChip(
                    label: '${days}d',
                    selected: _rangeDays == days,
                    onTap: () => setState(() => _rangeDays = days),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Mastery grid ───────────────────────────────────────────────
        Text(t.letterMasteryHeader, style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(t.masteryLegend, style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        skillsAsync.when(
          data: (skills) => _MasteryGrid(skills: skills),
          loading: () => const FkSkeleton(height: 120),
          error: (_, __) => Text(t.masteryLoadError, style: textTheme.bodyLarge),
        ),
      ],
    );
  }
}

class _MetricPicker extends StatelessWidget {
  final String current;
  final void Function(String) onChanged;

  const _MetricPicker({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final metrics = [
      FkFilterChip(label: t.metricAccuracy, value: 'accuracy'),
      FkFilterChip(label: t.metricSpeed, value: 'speed'),
      FkFilterChip(label: t.metricTime, value: 'time'),
    ];
    return FkFilterChipBar(
      chips: metrics,
      selectedValue: current,
      onSelected: onChanged,
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: AppRadius.pillAll,
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? Colors.white : colors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

class _TimeseriesChart extends StatelessWidget {
  final List<TimeseriesPoint> points;
  final String metric;

  const _TimeseriesChart({required this.points, required this.metric});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      final v = points[i].value;
      if (v != null) {
        spots.add(FlSpot(i.toDouble(), v));
      }
    }

    if (spots.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noDataForRange,
            style: Theme.of(context).textTheme.bodyLarge),
      );
    }

    // Y-axis bounds
    final (minY, maxY) = metric == 'accuracy'
        ? (0.0, 1.0)
        : (0.0, spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2);

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY.clamp(0.01, double.infinity),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colors.border,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, _) => Text(
                metric == 'accuracy'
                    ? '${(value * 100).toInt()}%'
                    : value.toStringAsFixed(0),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: colors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colors.primary.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mastery grid — one cell per letter/skill, soft-colored by p_known.
class _MasteryGrid extends StatelessWidget {
  final List<SkillEntry> skills;

  const _MasteryGrid({required this.skills});

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return Text(AppLocalizations.of(context)!.noSkillsTracked,
          style: Theme.of(context).textTheme.bodyLarge);
    }
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: skills.map((s) => _MasteryCell(skill: s)).toList(),
    );
  }
}

class _MasteryCell extends StatelessWidget {
  final SkillEntry skill;
  const _MasteryCell({required this.skill});

  Color _cellColor(AppColorTheme colors) {
    if (skill.isMastered) return colors.success;
    if (skill.isPracticing) return colors.warning;
    return colors.primarySoft; // not started / low progress
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cellColor = _cellColor(colors);
    return Tooltip(
      message: '${skill.label}: ${(skill.pKnown * 100).toStringAsFixed(0)}%',
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: AppRadius.smAll,
        ),
        alignment: Alignment.center,
        child: Text(
          skill.label.length > 2
              ? skill.label.substring(skill.label.length - 2)
              : skill.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: skill.isMastered || skill.isPracticing
                    ? Colors.white
                    : colors.textPrimary,
              ),
        ),
      ),
    );
  }
}
