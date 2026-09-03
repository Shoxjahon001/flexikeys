import 'package:flutter/material.dart';
import '../../design_system/design_system.dart';
import '../../l10n/app_localizations.dart';
import '../../services/user_service.dart';
import '../../data/trace_items/trace_item_def.dart';
import '../../data/trace_items/letters_trace_data.dart';
import '../../data/trace_items/letters_trace_data_ru.dart';
import 'trace_drawing_screen.dart';

/// Sub-task picker for the Letters drawing section — small groups of 3-4
/// letters each (unlocked in sequence) instead of all letters in one
/// sitting (7 groups for English's 26 letters, 9 for Russian's 33 — see
/// computeGroupSizes in trace_item_def.dart). Tapping an unlocked group
/// opens [TraceDrawingScreen] scoped to just that group's letters;
/// finishing it awards 5 stars on its own.
class LetterGroupsScreen extends StatefulWidget {
  const LetterGroupsScreen({super.key});

  @override
  State<LetterGroupsScreen> createState() => _LetterGroupsScreenState();
}

class _LetterGroupsScreenState extends State<LetterGroupsScreen> {
  Set<String> _completed = {};

  List<LetterGroup> _groups(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ru'
          ? kLetterGroupsRu
          : kLetterGroups;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final completed = await UserService.getCompletedLevels();
    if (!mounted) return;
    setState(() => _completed = completed);
  }

  bool _isUnlocked(List<LetterGroup> groups, int index) {
    if (index == 0) return true;
    return _completed.contains(groups[index - 1].id);
  }

  void _openGroup(LetterGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TraceDrawingScreen(
          title: '${AppLocalizations.of(context)!.drawTitleLetters} · ${group.label}',
          items: group.items,
          levelSlug: group.id,
          completionTitle: AppLocalizations.of(context)!.groupReadyHeadline,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final fk = FkPlayTheme.of(context);
    final groups = _groups(context);
    final doneCount = groups.where((g) => _completed.contains(g.id)).length;

    return Scaffold(
      backgroundColor: fk.background,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(fk, groups, doneCount),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(FkSpacing.sm),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: FkSpacing.sm,
                mainAxisSpacing: FkSpacing.sm,
                childAspectRatio: 1.05,
              ),
              itemCount: groups.length,
              itemBuilder: (context, i) => _buildGroupCard(fk, groups, i),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader(FkPlayTheme fk, List<LetterGroup> groups, int doneCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          FkSpacing.sm, FkSpacing.xs, FkSpacing.sm, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: fk.surface,
              borderRadius: FkRadii.smAll,
              boxShadow: FkElevation.low(fk.ink),
            ),
            child:
                Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: fk.ink),
          ),
        ),
        const SizedBox(width: FkSpacing.xs),
        Text(AppLocalizations.of(context)!.drawTitleLetters,
            style: FkTextStyles.playHeadline
                .copyWith(fontSize: 20, color: fk.ink)),
        const Spacer(),
        Text(
          '$doneCount/${groups.length}',
          style: FkTextStyles.playCaption
              .copyWith(fontSize: 15, color: fk.inkSoft),
        ),
      ]),
    );
  }

  Widget _buildGroupCard(FkPlayTheme fk, List<LetterGroup> groups, int index) {
    final group = groups[index];
    final unlocked = _isUnlocked(groups, index);
    final done = _completed.contains(group.id);

    final Color bg = done
        ? fk.success.withValues(alpha: 0.16)
        : unlocked
            ? fk.surface
            : fk.disabled.withValues(alpha: 0.25);
    final Color border = done
        ? fk.success
        : unlocked
            ? fk.secondary.withValues(alpha: 0.35)
            : Colors.transparent;

    return GestureDetector(
      onTap: unlocked ? () => _openGroup(group) : null,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: FkRadii.mdAll,
          border: Border.all(color: border, width: 2),
          boxShadow: unlocked ? FkElevation.low(fk.ink) : null,
        ),
        child: Stack(
          children: [
            if (!unlocked)
              Positioned(
                top: 10,
                right: 12,
                child: Icon(Icons.lock_rounded, size: 18, color: fk.inkSoft),
              ),
            if (done)
              Positioned(
                top: 10,
                right: 12,
                child: Icon(Icons.check_circle_rounded,
                    size: 20, color: fk.success),
              ),
            Center(
              child: Text(
                group.label,
                style: FkTextStyles.playHeadline.copyWith(
                  fontSize: 24,
                  color: unlocked ? fk.ink : fk.inkSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
