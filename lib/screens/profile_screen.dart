import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';
import '../services/tts_service.dart';
import '../services/sound_service.dart';
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
    final hasAccount = await SecureTokenStore.instance.hasParentSession();
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
    return Container(
      decoration: appGradientBg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 8),
              Text(
                t.parentDashboardHeader,
                style: GoogleFonts.nunito(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 20),

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
                  const SizedBox(width: 14),
                  Expanded(
                    child: ValueListenableBuilder<int>(
                      valueListenable: UserService.starsNotifier,
                      builder: (_, stars, __) =>
                          _statCard(t.statStarsLabel, '$stars ⭐', '🎯'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                      child: _statCard(t.accuracyLabel,
                          '${(_accuracy * 100).round()}%', '✅')),
                  const SizedBox(width: 14),
                  Expanded(
                      child: _statCard(
                          t.statTimeSpentLabel, '$_timeToday min', '⏱️',
                          subtitle: t.statTodaySuffix)),
                ],
              ),
              const SizedBox(height: 14),

              // Needs practice
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.needsPracticeLabel,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/game_stage1');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          t.practiceButton,
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // AI assistant entry point
              GestureDetector(
                onTap: _openAssistant,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD9D2F0), Color(0xFFFFD9C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.askAiAssistantTitle,
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.askAiAssistantSubtitle,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: AppTheme.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: AppTheme.textMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Settings
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.settingsTitle,
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: _settingsBtn(t.signOutButton, _signOut),
                        ),
                      ],
                    ),
                    if (!_hasBackendAccount) ...[
                      const SizedBox(height: 12),
                      _settingsBtn(
                        t.saveProgressButton,
                        () => Navigator.pushNamed(context, '/parent_signup'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      t.volumeLabel,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Slider(
                      value: _volume,
                      onChanged: (v) {
                        setState(() => _volume = v);
                        TtsService.instance.setVolume(v);
                        SoundService.instance.setVolume(v);
                      },
                      activeColor: AppTheme.primary,
                      inactiveColor: AppTheme.primaryLight,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD6E8), Color(0xFFD6C8FF)],
                    ),
                  ),
                  child: ValueListenableBuilder<String>(
                    valueListenable: UserService.avatarNotifier,
                    builder: (_, emoji, __) => Center(
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 26))),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _name,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: UserService.starsNotifier,
                  builder: (_, stars, __) => Text(
                    '$stars',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.star_rounded,
                    color: AppTheme.starYellow, size: 26),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, String icon,
      {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMedium,
                ),
              ),
              const Spacer(),
              Text(icon, style: const TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppTheme.textMedium,
              ),
            ),
        ],
      ),
    );
  }

  Widget _settingsBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.signOutDialogTitle,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w900)),
        content: Text(t.signOutDialogBody, style: GoogleFonts.nunito()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancelButton, style: GoogleFonts.nunito()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.signOutConfirm,
                style: GoogleFonts.nunito(color: Colors.red)),
          ),
        ],
      ),
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
    final current = UserService.uiLanguageNotifier.value;
    final options = {
      'en': t.languageEnglish,
      'uz': t.languageUzbek,
      'ru': t.languageRussian,
    };
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.uiLanguageSetting,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.entries
              .map((e) => ListTile(
                    onTap: () => Navigator.pop(ctx, e.key),
                    leading: Icon(
                      e.key == current
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: AppTheme.primary,
                    ),
                    title: Text('${_flagFor(e.key)}  ${e.value}',
                        style: GoogleFonts.nunito()),
                  ))
              .toList(),
        ),
      ),
    );
    if (selected != null && selected != current) {
      await UserService.setUiLanguage(selected);
    }
  }
}
