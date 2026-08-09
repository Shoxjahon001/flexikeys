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
      padding: const EdgeInsets.all(FkSpacing.sm),
      children: [
        // ── Metric picker ──────────────────────────────────────────────
        _MetricPicker(
          current: _metric,
          onChanged: (m) => setState(() => _metric = m),
        ),
        const SizedBox(height: FkSpacing.sm),

        // ── Line chart ────────────────────────────────────────────────
        FkCard(
          child: Padding(
            padding: const EdgeInsets.all(FkSpacing.sm),
            child: SizedBox(
              height: 180,
              child: tsAsync.when(
                data: (points) => _TimeseriesChart(
                  points: points,
                  metric: _metric,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(t.chartLoadError, style: FkTextStyles.adultBody),
                ),
              ),
            ),
          ),
        ),

        // ── Range picker ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: FkSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (final days in [7, 14, 30])
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _RangeChip(
                    label: '${days}d',
                    selected: _rangeDays == days,
                    onTap: () => setState(() => _rangeDays = days),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: FkSpacing.sm),

        // ── Mastery grid ───────────────────────────────────────────────
        Text(t.letterMasteryHeader, style: FkTextStyles.adultHeadline),
        const SizedBox(height: FkSpacing.xs),
        Text(
          t.masteryLegend,
          style: FkTextStyles.adultCaption,
        ),
        const SizedBox(height: FkSpacing.xs),
        skillsAsync.when(
          data: (skills) => _MasteryGrid(skills: skills),
          loading: () => const _Skeleton(height: 120),
          error: (_, __) => Text(
            t.masteryLoadError,
            style: FkTextStyles.adultBody,
          ),
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
    final metrics = {
      'accuracy': t.metricAccuracy,
      'speed': t.metricSpeed,
      'time': t.metricTime,
    };
    return Wrap(
      spacing: 8,
      children: metrics.entries
          .map(
            (e) => ChoiceChip(
              label: Text(e.value, style: FkTextStyles.adultCaption),
              selected: current == e.key,
              onSelected: (_) => onChanged(e.key),
              selectedColor: FkColors.lavender,
              backgroundColor: FkColors.surface,
              shape: const StadiumBorder(),
            ),
          )
          .toList(),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? FkColors.lavender : FkColors.surface,
          borderRadius: FkRadii.pillAll,
          border: Border.all(
            color: selected ? FkColors.lavender : FkColors.disabled,
          ),
        ),
        child: Text(
          label,
          style: FkTextStyles.adultCaption.copyWith(
            color: selected ? FkColors.ink : FkColors.disabledInk,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
            style: FkTextStyles.adultBody),
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
            color: FkColors.disabled.withValues(alpha: 0.5),
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
                style: FkTextStyles.adultCaption,
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
            color: FkColors.lavender,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: FkColors.lavender.withValues(alpha: 0.15),
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
          style: FkTextStyles.adultBody);
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: skills.map((s) => _MasteryCell(skill: s)).toList(),
    );
  }
}

class _MasteryCell extends StatelessWidget {
  final SkillEntry skill;
  const _MasteryCell({required this.skill});

  Color get _cellColor {
    if (skill.isMastered) return FkColors.mint;
    if (skill.isPracticing) return FkColors.warmYellow;
    return FkColors.lavender; // not started / low progress
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${skill.label}: ${(skill.pKnown * 100).toStringAsFixed(0)}%',
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _cellColor,
          borderRadius: FkRadii.smAll,
        ),
        alignment: Alignment.center,
        child: Text(
          skill.label.length > 2
              ? skill.label.substring(skill.label.length - 2)
              : skill.label,
          style: FkTextStyles.adultCaption.copyWith(
            fontWeight: FontWeight.w700,
            color: FkColors.ink,
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double height;
  const _Skeleton({required this.height});

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
