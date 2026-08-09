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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.exportSuccessSnackbar)),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmDelete() async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: FkRadii.mdAll),
        title: Text(t.deleteChildDialogTitle),
        content: Text(t.deleteChildDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              t.deleteButton,
              style: const TextStyle(color: FkColors.peach),
            ),
          ),
        ],
      ),
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
    return Scaffold(
      backgroundColor: FkColors.background,
      appBar: AppBar(
        backgroundColor: FkColors.background,
        elevation: 0,
        title: Text(t.settingsTitle, style: FkTextStyles.adultHeadline),
      ),
      body: ListView(
        padding: const EdgeInsets.all(FkSpacing.sm),
        children: [
          // ── Learning language ──────────────────────────────────────────
          // The child's curriculum/AAC vocabulary language — independent of
          // the interface language below. See CLAUDE.md: "UI language and
          // learning language are independent settings."
          _SectionHeader(title: t.languageSetting),
          FkCard(
            child: Padding(
              padding: const EdgeInsets.all(FkSpacing.sm),
              child: _LanguagePicker(childId: widget.childId),
            ),
          ),

          const SizedBox(height: FkSpacing.sm),

          // ── Display (interface) language ────────────────────────────────
          _SectionHeader(title: t.uiLanguageSetting),
          FkCard(
            child: Padding(
              padding: const EdgeInsets.all(FkSpacing.sm),
              child: _UiLanguagePicker(childId: widget.childId),
            ),
          ),

          const SizedBox(height: FkSpacing.sm),

          // ── Session length preference ──────────────────────────────────
          _SectionHeader(title: t.sessionLengthHeader),
          FkCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FkSpacing.sm,
                vertical: FkSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.sessionLengthHint,
                    style: FkTextStyles.adultBody,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.sessionLengthBody,
                    style: FkTextStyles.adultCaption,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: FkSpacing.sm),

          // ── Data & privacy ─────────────────────────────────────────────
          _SectionHeader(title: t.dataPrivacyHeader),
          FkCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download_rounded,
                      color: FkColors.lavender),
                  title: Text(
                    t.exportDataTitle,
                    style: FkTextStyles.adultBody,
                  ),
                  subtitle: Text(
                    t.exportDataSubtitle,
                    style: FkTextStyles.adultCaption,
                  ),
                  trailing: _exporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: _exporting ? null : _exportData,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: FkColors.peach),
                  title: Text(
                    t.deleteChildAccountTitle,
                    style: FkTextStyles.adultBody,
                  ),
                  subtitle: Text(
                    t.deleteChildAccountSubtitle,
                    style: FkTextStyles.adultCaption,
                  ),
                  trailing: _deleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: _deleting ? null : _confirmDelete,
                ),
              ],
            ),
          ),

          const SizedBox(height: FkSpacing.sm),

          // ── Consent notice ─────────────────────────────────────────────
          FkCard(
            child: Padding(
              padding: const EdgeInsets.all(FkSpacing.sm),
              child: Text(
                t.dataPrivacyNotice,
                style: FkTextStyles.adultCaption,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FkSpacing.xs),
      child: Text(title, style: FkTextStyles.adultLabel),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorNetwork)),
        );
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
        return Column(
          children: languages.entries
              .map(
                (e) => InkWell(
                  onTap: () => _select(e.key, summary.learningLanguage),
                  borderRadius: FkRadii.smAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FkSpacing.xs,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: current == e.key
                                  ? FkColors.lavender
                                  : FkColors.disabled,
                              width: 2,
                            ),
                            color: current == e.key
                                ? FkColors.lavender
                                : Colors.transparent,
                          ),
                          child: current == e.key
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 12,
                                  color: FkColors.ink,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(e.value, style: FkTextStyles.adultBody),
                        if (_saving && _pending == e.key) ...[
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: FkSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Text(t.errorGeneric, style: FkTextStyles.adultBody),
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
      builder: (context, current, _) => Column(
        children: languages.entries
            .map(
              (e) => InkWell(
                onTap: () => _select(e.key),
                borderRadius: FkRadii.smAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FkSpacing.xs,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: current == e.key
                                ? FkColors.lavender
                                : FkColors.disabled,
                            width: 2,
                          ),
                          color: current == e.key
                              ? FkColors.lavender
                              : Colors.transparent,
                        ),
                        child: current == e.key
                            ? const Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: FkColors.ink,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(e.value, style: FkTextStyles.adultBody),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
