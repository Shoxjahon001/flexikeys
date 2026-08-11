library settings_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/user_service.dart';
import '../application/parent_provider.dart';

const _kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000/api/v1',
);

/// Parent settings — learning language, display language, data export,
/// account deletion.
class SettingsScreen extends StatefulWidget {
  final String childId;

  const SettingsScreen({super.key, required this.childId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _exporting = false;
  bool _deleting = false;

  Future<void> _exportData() async {
    setState(() => _exporting = true);
    try {
      final resp = await http.get(
        Uri.parse('$_kBaseUrl/parent/children/${widget.childId}/export'),
      );
      if (!mounted) return;
      if (resp.statusCode == 200) {
        FkToast.show(
          context,
          AppLocalizations.of(context)!.exportSuccessSnackbar,
          type: FkToastType.success,
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmDelete() async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await FkDialog.confirm(
      context,
      title: t.deleteChildDialogTitle,
      message: t.deleteChildDialogBody,
      confirmLabel: t.deleteButton,
      cancelLabel: t.cancelButton,
      isDestructive: true,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      final resp = await http.delete(
        Uri.parse('$_kBaseUrl/parent/children/${widget.childId}'),
      );
      if (!mounted) return;
      if (resp.statusCode == 204) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = context.colors;
    return FkScaffold(
      appBar: FkAppBar(title: t.settingsTitle),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Learning language ──────────────────────────────────────────
          // The child's curriculum/AAC vocabulary language — independent of
          // the interface language below. See CLAUDE.md: "UI language and
          // learning language are independent settings."
          FkSectionHeader(title: t.languageSetting),
          const SizedBox(height: AppSpacing.sm),
          _LanguagePicker(childId: widget.childId),

          const SizedBox(height: AppSpacing.xl),

          // ── Display (interface) language ────────────────────────────────
          FkSectionHeader(title: t.uiLanguageSetting),
          const SizedBox(height: AppSpacing.sm),
          _UiLanguagePicker(childId: widget.childId),

          const SizedBox(height: AppSpacing.xl),

          // ── Session length preference ──────────────────────────────────
          FkSectionHeader(title: t.sessionLengthHeader),
          const SizedBox(height: AppSpacing.sm),
          FkCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.sessionLengthHint,
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(t.sessionLengthBody,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Data & privacy ─────────────────────────────────────────────
          FkSectionHeader(title: t.dataPrivacyHeader),
          const SizedBox(height: AppSpacing.sm),
          FkCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                FkListRow(
                  leading: Icon(Icons.download_rounded, color: colors.primary),
                  label: t.exportDataTitle,
                  subtitle: t.exportDataSubtitle,
                  trailing: _exporting
                      ? const FkLoadingIndicator(size: 20, strokeWidth: 2)
                      : null,
                  onTap: _exporting ? null : _exportData,
                ),
                FkListRow(
                  leading:
                      Icon(Icons.delete_outline_rounded, color: colors.danger),
                  label: t.deleteChildAccountTitle,
                  subtitle: t.deleteChildAccountSubtitle,
                  showDivider: false,
                  trailing: _deleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _deleting ? null : _confirmDelete,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Consent notice ─────────────────────────────────────────────
          FkCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(t.dataPrivacyNotice,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
        ],
      ),
    );
  }
}

/// The child's LEARNING language (curriculum/AAC vocabulary) — persisted to
/// the backend via `PATCH /children/{id}`, independent of the interface
/// language ([_UiLanguagePicker] below). Previously a fully decorative
/// widget: local `State` only, never seeded from the real value, never
/// saved anywhere — see localization audit.
class _LanguagePicker extends ConsumerStatefulWidget {
  final String childId;
  const _LanguagePicker({required this.childId});

  @override
  ConsumerState<_LanguagePicker> createState() => _LanguagePickerState();
}

class _LanguagePickerState extends ConsumerState<_LanguagePicker> {
  String? _pending;
  bool _saving = false;

  Future<void> _select(String code, String current) async {
    if (code == current || _saving) return;
    setState(() {
      _pending = code;
      _saving = true;
    });
    try {
      final resp = await ApiClient.instance.patch(
        '/children/${widget.childId}',
        body: {'learning_language': code},
      );
      if (resp.statusCode == 200) {
        await UserService.setLearningLanguage(code);
        ref.invalidate(childSummaryProvider(widget.childId));
      } else if (mounted) {
        FkToast.show(context, AppLocalizations.of(context)!.errorGeneric,
            type: FkToastType.error);
      }
    } catch (_) {
      if (mounted) {
        FkToast.show(context, AppLocalizations.of(context)!.errorNetwork,
            type: FkToastType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final languages = {
      'en': t.languageEnglish,
      'uz': t.languageUzbek,
      'ru': t.languageRussian,
    };
    final summaryAsync = ref.watch(childSummaryProvider(widget.childId));

    return summaryAsync.when(
      data: (summary) {
        final current = _pending ?? summary.learningLanguage;
        return _LanguageSegmentedControl(
          languages: languages,
          current: current,
          saving: _saving ? _pending : null,
          onSelected: (code) => _select(code, summary.learningLanguage),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: FkLoadingIndicator()),
      ),
      error: (_, __) =>
          Text(t.errorGeneric, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

/// The app's INTERFACE language (buttons, menus, dashboard chrome) —
/// independent of [_LanguagePicker] above. Local-first (works offline,
/// exactly like the rest of this app's local stores) via
/// `UserService.uiLanguageNotifier`; also best-effort synced to the child
/// record so the backend can render server-side text (e.g. adaptation
/// explanations) in the same language.
class _UiLanguagePicker extends StatelessWidget {
  final String childId;
  const _UiLanguagePicker({required this.childId});

  Future<void> _select(String code) async {
    await UserService.setUiLanguage(code);
    // Fire-and-forget: the interface language must work offline and switch
    // instantly (above), so this backend sync is a best-effort mirror, not
    // a precondition — same reasoning as ProgressRepository.sync().
    try {
      await ApiClient.instance
          .patch('/children/$childId', body: {'ui_language': code});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final languages = {
      'en': t.languageEnglish,
      'uz': t.languageUzbek,
      'ru': t.languageRussian,
    };

    return ValueListenableBuilder<String>(
      valueListenable: UserService.uiLanguageNotifier,
      builder: (context, current, _) => _LanguageSegmentedControl(
        languages: languages,
        current: current,
        saving: null,
        onSelected: _select,
      ),
    );
  }
}

/// Shared "clear segmented control" for EN/UZ/RU, used by both language
/// pickers above — the redesign spec's explicit ask for the Settings
/// screen's language switcher, replacing the old vertical radio-button
/// list.
class _LanguageSegmentedControl extends StatelessWidget {
  final Map<String, String> languages;
  final String current;
  final String? saving;
  final ValueChanged<String> onSelected;

  const _LanguageSegmentedControl({
    required this.languages,
    required this.current,
    required this.saving,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: languages.entries.map((e) {
        final selected = current == e.key;
        final isSaving = saving == e.key;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: e.key == languages.keys.last ? 0 : AppSpacing.sm,
            ),
            child: GestureDetector(
              onTap: () => onSelected(e.key),
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.transition,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? colors.primary : colors.surfaceMuted,
                  borderRadius: AppRadius.smAll,
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        e.value,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: selected ? Colors.white : colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
