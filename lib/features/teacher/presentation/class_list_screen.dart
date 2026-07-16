library class_list_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../application/teacher_provider.dart';
import '../domain/teacher_models.dart';
import 'class_detail_screen.dart';

/// Teacher home — shows the list of classes.
class ClassListScreen extends ConsumerWidget {
  const ClassListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classListProvider);

    return Scaffold(
      backgroundColor: FkColors.background,
      appBar: AppBar(
        backgroundColor: FkColors.background,
        elevation: 0,
        title: const Text('My Classes', style: FkTextStyles.adultHeadline),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Create class',
            onPressed: () => _showCreateDialog(context, ref),
          ),
        ],
      ),
      body: classesAsync.when(
        data: (classes) => classes.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(FkSpacing.sm),
                itemCount: classes.length,
                itemBuilder: (_, i) => _ClassCard(cls: classes[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text(
            'Could not load classes. Please try again.',
            style: FkTextStyles.adultBody,
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: FkRadii.mdAll),
        title: const Text('New Class', style: FkTextStyles.adultHeadline),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 128,
          decoration: const InputDecoration(
            hintText: 'Class name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.invalidate(classListProvider);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
  }
}

class _ClassCard extends StatelessWidget {
  final ClassItem cls;
  const _ClassCard({required this.cls});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FkSpacing.xs),
      child: InkWell(
        borderRadius: FkRadii.mdAll,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClassDetailScreen(classId: cls.id, className: cls.name),
          ),
        ),
        child: FkCard(
          child: Padding(
            padding: const EdgeInsets.all(FkSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: FkColors.lavender,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.group_rounded,
                    color: FkColors.ink,
                    size: 24,
                  ),
                ),
                const SizedBox(width: FkSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cls.name, style: FkTextStyles.adultHeadline),
                      const SizedBox(height: 2),
                      Text(
                        '${cls.studentCount} students · Code: ${cls.joinCode}',
                        style: FkTextStyles.adultCaption,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: FkColors.disabledInk),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FkSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_rounded, size: 64, color: FkColors.lavender.withValues(alpha: 0.5)),
            const SizedBox(height: FkSpacing.sm),
            const Text(
              'No classes yet',
              style: FkTextStyles.adultHeadline,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FkSpacing.xs),
            const Text(
              'Tap + to create your first class and share the join code with parents.',
              style: FkTextStyles.adultBody,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}