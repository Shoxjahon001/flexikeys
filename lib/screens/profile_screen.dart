import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../design_system/design_system.dart';
import '../services/user_service.dart';
import '../services/tts_service.dart';
import '../services/sound_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/network/secure_token_store.dart';
import '../features/parent/presentation/parent_home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  int _lettersStage = 0;
  int _totalCorrect = 0;
  int _totalAnswers = 0;
  int _timeToday = 0;
  double _volume = 0.7;
  bool _hasBackendAccount = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      UserService.getName(),
      UserService.getLettersStage(),
      UserService.getTotalCorrect(),
      UserService.getTotalAnswers(),
      UserService.getTimeSpentToday(),
      UserService.getVolume(),
    ]);
    final hasAccount = Supabase.instance.client.auth.currentSession != null;
    if (mounted) setState(() => _hasBackendAccount = hasAccount);
    if (mounted) {
      setState(() {
        _name = results[0] as String;
        _lettersStage = results[1] as int;
        _totalCorrect = results[2] as int;
        _totalAnswers = results[3] as int;
        _timeToday = results[4] as int;
        _volume = results[5] as double;
      });
    }
  }

  double get _accuracy =>
      _totalAnswers == 0 ? 0 : _totalCorrect / _totalAnswers;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      color: colors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                t.parentDashboardHeader,
                style: textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Stats grid
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      t.statLettersLabel,
                      _lettersStage == 0
                          ? t.statNotStarted
                          : _lettersStage == 1
                              ? t.statStage1Done
                              : t.statDone,
                      '📚',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ValueListenableBuilder<int>(
                      valueListenable: UserService.starsNotifier,
                      builder: (_, stars, __) =>
                          _statCard(t.statStarsLabel, '$stars ⭐', '🎯'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                      child: _statCard(t.accuracyLabel,
                          '${(_accuracy * 100).round()}%', '✅')),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                      child: _statCard(
                          t.statTimeSpentLabel, '$_timeToday min', '⏱️',
                          subtitle: t.statTodaySuffix)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Needs practice
              FkCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.needsPracticeLabel,
                        style: textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    FkSecondaryButton(
                      label: t.practiceButton,
                      onPressed: () =>
                          Navigator.pushNamed(context, '/game_stage1'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // AI assistant entry point
              GestureDetector(
                onTap: _openAssistant,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: colors.primarySoft,
                    borderRadius: AppRadius.lgAll,
                    boxShadow: AppShadows.soft,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.auto_awesome_rounded,
                            color: colors.primary, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.askAiAssistantTitle,
                              style: textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.askAiAssistantSubtitle,
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: colors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Settings
              FkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.settingsTitle, style: textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: ValueListenableBuilder<String>(
                            valueListenable: UserService.uiLanguageNotifier,
                            builder: (_, uiLanguage, __) => _settingsBtn(
                              '${t.languageMenuButton} ${_flagFor(uiLanguage)}',
                              _changeLanguage,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _settingsBtn(t.signOutButton, _signOut),
                        ),
                      ],
                    ),
                    if (!_hasBackendAccount) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _settingsBtn(
                        t.saveProgressButton,
                        () => Navigator.pushNamed(context, '/parent_signup'),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      t.volumeLabel,
                      style:
                          textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Slider(
                      value: _volume,
                      onChanged: (v) {
                        setState(() => _volume = v);
                        TtsService.instance.setVolume(v);
                        SoundService.instance.setVolume(v);
                      },
                      activeColor: colors.primary,
                      inactiveColor: colors.primarySoft,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppRadius.pillAll,
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primarySoft,
                  ),
                  child: ValueListenableBuilder<String>(
                    valueListenable: UserService.avatarNotifier,
                    builder: (_, emoji, __) => Center(
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 26))),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _name,
                  style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppRadius.pillAll,
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: UserService.starsNotifier,
                  builder: (_, stars, __) => Text(
                    '$stars',
                    style:
                        textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.star_rounded, color: colors.warning, size: 26),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, String icon, {String? subtitle}) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return FkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(icon, style: const TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: textTheme.headlineLarge?.copyWith(color: colors.primary),
          ),
          if (subtitle != null) Text(subtitle, style: textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _settingsBtn(String label, VoidCallback onTap) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: AppRadius.mdAll,
        ),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /// Opens the AI assistant.
  ///
  /// TEMP: guest access is allowed for now — a real parent account/child
  /// isn't required to open the screen, so anyone can see the assistant UI
  /// before a backend/database is wired up for this build. Once that's
  /// ready, restore the gate: require `_hasBackendAccount` and a real
  /// `SecureTokenStore.instance.getActiveChildId()`, redirecting to
  /// `/parent_signup` when either is missing (the assistant is meant to be
  /// grounded in real backend progress data, not shown empty).
  Future<void> _openAssistant() async {
    final childId =
        await SecureTokenStore.instance.getActiveChildId() ?? 'guest';
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParentHomeScreen(childId: childId, initialTab: 3),
      ),
    );
  }

  Future<void> _signOut() async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await FkDialog.confirm(
      context,
      title: t.signOutDialogTitle,
      message: t.signOutDialogBody,
      confirmLabel: t.signOutConfirm,
      cancelLabel: t.cancelButton,
      isDestructive: true,
    );
    if (confirmed == true) {
      await UserService.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
    }
  }

  static const _languageFlags = {'en': '🇺🇸', 'uz': '🇺🇿', 'ru': '🇷🇺'};
  String _flagFor(String code) => _languageFlags[code] ?? '🇺🇸';

  /// This was previously a decorative no-op button — see localization audit.
  /// It sets the app's INTERFACE language only (UserService.uiLanguageNotifier),
  /// not the child's learning language, which stays untouched here.
  Future<void> _changeLanguage() async {
    final t = AppLocalizations.of(context)!;
    final colors = context.colors;
    final current = UserService.uiLanguageNotifier.value;
    final options = {
      'en': t.languageEnglish,
      'uz': t.languageUzbek,
      'ru': t.languageRussian,
    };
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => FkDialog(
        title: t.uiLanguageSetting,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.entries
              .map((e) => ListTile(
                    onTap: () => Navigator.pop(ctx, e.key),
                    leading: Icon(
                      e.key == current
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: colors.primary,
                    ),
                    title: Text('${_flagFor(e.key)}  ${e.value}'),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancelButton),
          ),
        ],
      ),
    );
    if (selected != null && selected != current) {
      await UserService.setUiLanguage(selected);
    }
  }
}
