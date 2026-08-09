import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the Phase 2 rule from the design-token unification work (see
/// CLAUDE.md Design System section, and the Phase 1 report): components
/// under the walked directories must read colors/type from
/// `Theme.of(context)` — `AppColorTheme`/`context.colors` — never the flat
/// static `AppColors`/`AppTypography` classes directly. Reading them
/// directly is exactly the `FkTheme` situation Phase 1 spent its whole
/// budget escaping (dark mode, or any future re-theming, becomes a
/// file-by-file migration again instead of flipping `themeMode`).
///
/// Static access stays legitimate:
/// - inside the token/theme definition files themselves (excluded below);
/// - on a line with a trailing `// ignore: static-tokens` comment, for a
///   genuine, reasoned exception (e.g. a value that provably doesn't vary
///   by theme) — visible in code review, not silent;
/// - inside [_allowlist], which is **known, pre-existing Phase 1 debt**:
///   files that were migrated onto `AppColors`/`AppTypography` directly
///   before this rule existed. It exists so the rule can block *new*
///   violations today without requiring an immediate, unplanned rewrite of
///   that debt. It must only shrink as Phase 2 migrates each file onto
///   `context.colors` — this test fails if an allowlisted file no longer
///   actually violates the rule, so the list can't go stale in the
///   "forgot to remove it" direction either.
void main() {
  test('no static AppColors/AppTypography usage outside tokens/theme (or the allowlist)', () {
    final repoRoot = Directory.current.path;
    const walkedRoots = [
      'lib/design_system/components',
      'lib/screens',
    ];
    const excludedDirs = [
      'lib/design_system/tokens',
      'lib/design_system/theme',
    ];
    final pattern = RegExp(r'\bAppColors\.|\bAppTypography\.');

    // Scoped to the two directories this test actually walks — NOT the
    // full Phase 1 blast radius. The bulk of Phase 1's static-token debt
    // (the 7 shared atoms in lib/design_system/atoms/, the 3 auth screens
    // and fk_keyboard.dart under lib/features/) lives outside
    // lib/design_system/components/ and lib/screens/, so it isn't covered
    // by this test as scoped and needs no entry here.
    const allowlist = <String>{};

    final violations = <String, List<int>>{};

    for (final rootPath in walkedRoots) {
      final dir = Directory('$repoRoot/$rootPath');
      if (!dir.existsSync()) continue;

      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;

        final relPath =
            entity.path.substring(repoRoot.length + 1).replaceAll('\\', '/');
        if (excludedDirs.any((d) => relPath.startsWith('$d/'))) continue;

        final lines = entity.readAsLinesSync();
        final hits = <int>[];
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (pattern.hasMatch(line) &&
              !line.contains('// ignore: static-tokens')) {
            hits.add(i + 1);
          }
        }
        if (hits.isNotEmpty) violations[relPath] = hits;
      }
    }

    final unexpected =
        violations.keys.where((f) => !allowlist.contains(f)).toList()..sort();
    expect(
      unexpected,
      isEmpty,
      reason: 'New static AppColors/AppTypography usage outside the '
          'allowlist. Either read colors via context.colors '
          '(AppColorTheme.of(context)), add "// ignore: static-tokens" for '
          'a reasoned exception, or — only if this is pre-existing Phase 1 '
          'debt — add the file to the allowlist: '
          '${{for (final f in unexpected) f: violations[f]}}',
    );

    final stale = allowlist.where((f) => !violations.containsKey(f)).toList()
      ..sort();
    expect(
      stale,
      isEmpty,
      reason: 'These allowlisted files no longer violate the rule — remove '
          'them from the allowlist so it stays accurate: $stale',
    );
  });
}
