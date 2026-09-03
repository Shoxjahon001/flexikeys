import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/content_packs/content_pack.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../services/progress/progress_repository.dart';

/// Sub-task picker for a Letters [ContentPack] whose alphabet is too long
/// for one sitting (today: Russian's 33 letters, via [ContentPack.groupSizes])
/// — small groups of 3-4 letters, unlocked in sequence, each independently
/// completable. Mirrors the UX already proven for the Drawing module's
/// letter groups (see letter_groups_screen.dart) rather than inventing a
/// new pattern, but stays on this feature's own legacy [AppTheme] surface
/// rather than that screen's `FkPlayTheme` — see CLAUDE.md's design-system
/// migration boundary.
///
/// The task screen itself ([LettersStage1Screen], reached via '/game_stage1')
/// needs no awareness that grouping exists — it's handed one group's own
/// small [ContentPack] via route arguments exactly as it would the full
/// pack, see [splitIntoGroups]. English/Uzbek packs have no [ContentPack.
/// groupSizes] and never reach this screen — [levels_screen.dart] routes
/// straight to '/game_stage1' for them, unchanged.
class LettersGroupPickerScreen extends StatefulWidget {
  const LettersGroupPickerScreen({super.key});

  @override
  State<LettersGroupPickerScreen> createState() =>
      _LettersGroupPickerScreenState();
}

class _LettersGroupPickerScreenState extends State<LettersGroupPickerScreen> {
  ContentPack? _pack;
  List<ContentPack> _groups = const [];
  Set<String> _completed = {};
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pack == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is ContentPack) {
        _pack = args;
        _groups = splitIntoGroups(args);
        _load();
      }
    }
  }

  Future<void> _load() async {
    final completed = await UserService.getCompletedLevels();
    if (!mounted) return;
    setState(() {
      _completed = completed;
      _loading = false;
    });
    await _maybeCompleteUmbrella();
  }

  /// Once every group is done, mirrors the ungrouped flow's umbrella
  /// completion (`UserService.setLettersStage(1)` completes both
  /// 'letters_1' and 'letters') so unlock logic elsewhere (Numbers gated
  /// on 'letters_1' in levels_screen.dart) keeps working regardless of
  /// which locale's Letters flow a child went through. `stars: 0` here —
  /// each group already paid out its own reward on the way.
  Future<void> _maybeCompleteUmbrella() async {
    if (_groups.isEmpty) return;
    final allDone = _groups.every((g) => _completed.contains(g.categoryId));
    if (!allDone || _completed.contains('letters_1')) return;
    await UserService.setLettersStage(1);
    ProgressRepository.instance
        .recordLevelCompleteAndSync('letters_1', stars: 0);
    ProgressRepository.instance.recordLevelCompleteAndSync('letters', stars: 0);
    if (!mounted) return;
    setState(() => _completed = {..._completed, 'letters_1', 'letters'});
  }

  bool _isUnlocked(int index) {
    if (index == 0) return true;
    return _completed.contains(_groups[index - 1].categoryId);
  }

  void _openGroup(ContentPack group) {
    Navigator.pushNamed(context, '/game_stage1', arguments: group)
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    if (_pack == null || _loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final doneCount =
        _groups.where((g) => _completed.contains(g.categoryId)).length;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.bgTop, AppTheme.bgBottom],
            stops: [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(doneCount),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: _groups.length,
                  itemBuilder: (_, i) => _buildGroupCard(i),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int doneCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: AppTheme.textDark),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _pack!.title,
            style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark),
          ),
          const Spacer(),
          Text(
            '$doneCount / ${_groups.length}',
            style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(int index) {
    final group = _groups[index];
    final unlocked = _isUnlocked(index);
    final done = _completed.contains(group.categoryId);

    final Color bg;
    final Color border;
    if (done) {
      bg = const Color(0xFFDFF6E3);
      border = const Color(0xFF4AC75E);
    } else if (unlocked) {
      bg = Colors.white;
      border = AppTheme.primary.withValues(alpha: 0.4);
    } else {
      bg = Colors.white.withValues(alpha: 0.5);
      border = Colors.transparent;
    }

    return GestureDetector(
      onTap: unlocked ? () => _openGroup(group) : null,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 2),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Stack(
          children: [
            if (!unlocked)
              const Positioned(
                top: 8,
                right: 10,
                child: Icon(Icons.lock_rounded,
                    size: 16, color: AppTheme.textMedium),
              ),
            if (done)
              const Positioned(
                top: 8,
                right: 10,
                child: Icon(Icons.check_circle_rounded,
                    size: 18, color: Color(0xFF4AC75E)),
              ),
            Center(
              child: Text(
                group.title,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: unlocked ? AppTheme.textDark : AppTheme.textMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
