library settings_screen;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../design_system/design_system.dart';

const _kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000/api/v1',
);

/// Parent settings — learning language, data export, account deletion.
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
          const SnackBar(content: Text('Data exported successfully.')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: FkRadii.mdAll),
        title: const Text('Delete child account?'),
        content: const Text(
          'This will permanently delete all practice data for this child. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: FkColors.peach),
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
    return Scaffold(
      backgroundColor: FkColors.background,
      appBar: AppBar(
        backgroundColor: FkColors.background,
        elevation: 0,
        title: const Text('Settings', style: FkTextStyles.adultHeadline),
      ),
      body: ListView(
        padding: const EdgeInsets.all(FkSpacing.sm),
        children: [
          // ── Learning language ──────────────────────────────────────────
          const _SectionHeader(title: 'Learning Language'),
          FkCard(
            child: Padding(
              padding: const EdgeInsets.all(FkSpacing.sm),
              child: _LanguagePicker(childId: widget.childId),
            ),
          ),

          const SizedBox(height: FkSpacing.sm),

          // ── Session length preference ──────────────────────────────────
          const _SectionHeader(title: 'Session Length'),
          const FkCard(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: FkSpacing.sm,
                vertical: FkSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggested session length: 10–15 minutes',
                    style: FkTextStyles.adultBody,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'The system will suggest a break if practice '
                    'exceeds 7 minutes continuously.',
                    style: FkTextStyles.adultCaption,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: FkSpacing.sm),

          // ── Data & privacy ─────────────────────────────────────────────
          const _SectionHeader(title: 'Data & Privacy'),
          FkCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download_rounded,
                      color: FkColors.lavender),
                  title: const Text(
                    'Export my child\'s data',
                    style: FkTextStyles.adultBody,
                  ),
                  subtitle: const Text(
                    'Download a complete JSON archive',
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
                  title: const Text(
                    'Delete child account',
                    style: FkTextStyles.adultBody,
                  ),
                  subtitle: const Text(
                    'Permanently deletes all practice data',
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
          const FkCard(
            child: Padding(
              padding: EdgeInsets.all(FkSpacing.sm),
              child: Text(
                'FlexiKeys collects only the minimum data needed to personalise '
                'your child\'s learning. No advertising. No third-party tracking. '
                'All telemetry is pseudonymised. You can export or delete all data '
                'at any time.',
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

class _LanguagePicker extends StatefulWidget {
  final String childId;
  const _LanguagePicker({required this.childId});

  @override
  State<_LanguagePicker> createState() => _LanguagePickerState();
}

class _LanguagePickerState extends State<_LanguagePicker> {
  String _selected = 'en';

  @override
  Widget build(BuildContext context) {
    const languages = {
      'en': 'English',
      'uz': 'O\'zbek',
      'ru': 'Русский',
    };

    return Column(
      children: languages.entries
          .map(
            (e) => InkWell(
              onTap: () => setState(() => _selected = e.key),
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
                          color: _selected == e.key
                              ? FkColors.lavender
                              : FkColors.disabled,
                          width: 2,
                        ),
                        color: _selected == e.key
                            ? FkColors.lavender
                            : Colors.transparent,
                      ),
                      child: _selected == e.key
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
    );
  }
}