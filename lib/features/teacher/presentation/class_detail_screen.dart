library class_detail_screen;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../application/teacher_provider.dart';
import '../domain/teacher_models.dart';
import 'assignment_composer_screen.dart';

/// Teacher class detail — roster + assignment list.
/// No parent contact data shown. "Needs attention" = "could use extra practice".
class ClassDetailScreen extends ConsumerWidget {
  final String classId;
  final String className;

  const ClassDetailScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(classAnalyticsProvider(classId));
    final assignmentsAsync = ref.watch(assignmentsProvider(classId));

    return Scaffold(
      backgroundColor: FkColors.background,
      appBar: AppBar(
        backgroundColor: FkColors.background,
        elevation: 0,
        title: Text(className, style: FkTextStyles.adultHeadline),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'New assignment',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AssignmentComposerScreen(classId: classId),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(FkSpacing.sm),
        children: [
          // ── Join code card ────────────────────────────────────────────────
          analyticsAsync.when(
            data: (a) => _JoinCodeCard(
              classId: classId,
              studentCount: a.studentCount,
              avgMastery: a.avgMastery,
              needsAttentionCount: a.needsAttentionCount,
            ),
            loading: () => const _Skeleton(height: 80),
            error: (_, __) => const _ErrorText('Could not load class summary.'),
          ),

          const SizedBox(height: FkSpacing.sm),

          // ── Roster ───────────────────────────────────────────────────────
          const Text('Students', style: FkTextStyles.adultHeadline),
          const SizedBox(height: FkSpacing.xs),
          analyticsAsync.when(
            data: (a) => a.studentSummaries.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: FkSpacing.sm),
                    child: Text('No students enrolled yet.', style: FkTextStyles.adultBody),
                  )
                : _RosterGrid(students: a.studentSummaries),
            loading: () => const _Skeleton(height: 120),
            error: (_, __) => const _ErrorText('Could not load roster.'),
          ),

          const SizedBox(height: FkSpacing.sm),

          // ── Assignments ───────────────────────────────────────────────────
          const Text('Assignments', style: FkTextStyles.adultHeadline),
          const SizedBox(height: FkSpacing.xs),
          assignmentsAsync.when(
            data: (list) => list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: FkSpacing.sm),
                    child: Text('No assignments yet.', style: FkTextStyles.adultBody),
                  )
                : Column(
                    children: list.map((a) => _AssignmentTile(a: a)).toList(),
                  ),
            loading: () => const _Skeleton(height: 80),
            error: (_, __) => const _ErrorText('Could not load assignments.'),
          ),
        ],
      ),
    );
  }
}

class _JoinCodeCard extends StatelessWidget {
  final String classId;
  final int studentCount;
  final double avgMastery;
  final int needsAttentionCount;

  const _JoinCodeCard({
    required this.classId,
    required this.studentCount,
    required this.avgMastery,
    required this.needsAttentionCount,
  });

  @override
  Widget build(BuildContext context) {
    return FkCard(
      child: Padding(
        padding: const EdgeInsets.all(FkSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join Code: $classId',
                        style: FkTextStyles.adultLabel,
                      ),
                      const Text(
                        'Share with parents to enroll their child.',
                        style: FkTextStyles.adultCaption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  tooltip: 'Copy join code',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: classId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Join code copied')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: FkSpacing.xs),
            Row(
              children: [
                _StatChip(label: '$studentCount students'),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Avg ${(avgMastery * 100).toStringAsFixed(0)}%',
                ),
                if (needsAttentionCount > 0) ...[
                  const SizedBox(width: 8),
                  _StatChip(
                    label: '$needsAttentionCount could use extra practice',
                    highlight: true,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final bool highlight;

  const _StatChip({required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? FkColors.warmYellow : FkColors.surface,
        borderRadius: FkRadii.pillAll,
        border: Border.all(
          color: highlight ? FkColors.warmYellow : FkColors.disabled,
        ),
      ),
      child: Text(label, style: FkTextStyles.adultCaption),
    );
  }
}

class _RosterGrid extends StatelessWidget {
  final List<StudentSummary> students;
  const _RosterGrid({required this.students});

  Color _cellColor(StudentSummary s) {
    if (s.masteryScore >= 0.8) return FkColors.mint;
    if (s.masteryScore >= 0.4) return FkColors.warmYellow;
    return FkColors.lavender;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: students.map((s) {
        return Tooltip(
          message: '${s.displayName}: ${(s.masteryScore * 100).toStringAsFixed(0)}%'
              '${s.needsAttention ? " — could use extra practice" : ""}',
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _cellColor(s),
              borderRadius: FkRadii.smAll,
            ),
            alignment: Alignment.center,
            child: Text(
              s.displayName.isNotEmpty ? s.displayName[0].toUpperCase() : '?',
              style: FkTextStyles.adultCaption.copyWith(
                fontWeight: FontWeight.w700,
                color: FkColors.ink,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  final Assignment a;
  const _AssignmentTile({required this.a});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FkSpacing.xs),
      child: FkCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FkSpacing.sm,
            vertical: 10,
          ),
          child: Row(
            children: [
              const Icon(Icons.assignment_rounded, color: FkColors.lavender, size: 20),
              const SizedBox(width: FkSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.instructions ?? 'Assignment',
                      style: FkTextStyles.adultBody,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (a.dueAt != null)
                      Text(
                        'Due: ${_formatDate(a.dueAt!)}',
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

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
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

class _ErrorText extends StatelessWidget {
  final String message;
  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) {
    return Text(message, style: FkTextStyles.adultBody);
  }
}