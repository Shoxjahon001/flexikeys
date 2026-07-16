library assignment_composer_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../application/teacher_provider.dart';

/// Simple assignment composer for teachers.
class AssignmentComposerScreen extends ConsumerStatefulWidget {
  final String classId;

  const AssignmentComposerScreen({super.key, required this.classId});

  @override
  ConsumerState<AssignmentComposerScreen> createState() =>
      _AssignmentComposerScreenState();
}

class _AssignmentComposerScreenState
    extends ConsumerState<AssignmentComposerScreen> {
  final _instructionsCtrl = TextEditingController();
  DateTime? _dueAt;

  @override
  void dispose() {
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueAt = picked);
    }
  }

  Future<void> _submit() async {
    final notifier = ref.read(assignmentComposerProvider.notifier);
    notifier.setInstructions(_instructionsCtrl.text.trim());
    notifier.setDueAt(_dueAt);

    final result = await notifier.submit(widget.classId);
    if (!mounted) return;

    if (result != null) {
      ref.invalidate(assignmentsProvider(widget.classId));
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment created.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentComposerProvider);

    return Scaffold(
      backgroundColor: FkColors.background,
      appBar: AppBar(
        backgroundColor: FkColors.background,
        elevation: 0,
        title: const Text('New Assignment', style: FkTextStyles.adultHeadline),
      ),
      body: ListView(
        padding: const EdgeInsets.all(FkSpacing.sm),
        children: [
          // ── Instructions field ─────────────────────────────────────────
          const Text('Instructions', style: FkTextStyles.adultLabel),
          const SizedBox(height: FkSpacing.xs),
          FkCard(
            child: Padding(
              padding: const EdgeInsets.all(FkSpacing.xs),
              child: TextField(
                controller: _instructionsCtrl,
                enabled: !state.submitting,
                maxLength: 2000,
                maxLines: 5,
                style: FkTextStyles.adultBody,
                decoration: const InputDecoration(
                  hintText: 'Describe what students should work on…',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: FkSpacing.sm),

          // ── Due date ───────────────────────────────────────────────────
          const Text('Due Date (optional)', style: FkTextStyles.adultLabel),
          const SizedBox(height: FkSpacing.xs),
          InkWell(
            borderRadius: FkRadii.mdAll,
            onTap: state.submitting ? null : _pickDate,
            child: FkCard(
              child: Padding(
                padding: const EdgeInsets.all(FkSpacing.sm),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: FkColors.lavender, size: 20),
                    const SizedBox(width: FkSpacing.xs),
                    Text(
                      _dueAt != null
                          ? '${_dueAt!.year}-${_dueAt!.month.toString().padLeft(2, '0')}-${_dueAt!.day.toString().padLeft(2, '0')}'
                          : 'Select a due date',
                      style: FkTextStyles.adultBody,
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (state.errorMessage != null) ...[
            const SizedBox(height: FkSpacing.xs),
            Text(
              state.errorMessage!,
              style: FkTextStyles.adultCaption.copyWith(color: FkColors.peach),
            ),
          ],

          const SizedBox(height: FkSpacing.md),

          // ── Submit ─────────────────────────────────────────────────────
          FkButton(
            label: state.submitting ? 'Creating…' : 'Create Assignment',
            onPressed: state.submitting ? null : _submit,
            size: FkButtonSize.adult,
          ),

          const SizedBox(height: FkSpacing.sm),
          const Text(
            'Students will see this assignment in their practice dashboard. '
            'The adaptive engine continues to adjust for each student individually.',
            style: FkTextStyles.adultCaption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}