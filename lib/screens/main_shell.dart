import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../design_system/design_system.dart';
import '../services/user_service.dart';
import '../services/progress/progress_repository.dart';
import '../features/auth/application/auth_controller.dart';
import 'levels_screen.dart';
import 'shop_screen.dart';
import 'profile_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  int _tab = 0;
  String _name = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadName();
    // Touching the provider triggers AuthController's bootstrap, which
    // restores any stored parent/child session, re-inits sync+telemetry,
    // and fires an initial progress sync (see AuthController.selectChild).
    ref.read(authControllerProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Fire-and-forget — never blocks the UI, silently no-ops offline/guest.
      unawaited(ProgressRepository.instance.sync());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && (args['name'] as String? ?? '').isNotEmpty) {
      setState(() => _name = args['name'] as String);
    }
  }

  Future<void> _loadName() async {
    final name = await UserService.getName();
    if (mounted && name.isNotEmpty) setState(() => _name = name);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      LevelsScreen(externalName: _name),
      const ShopScreen(),
      FkParentGate(onUnlocked: () {}, child: const ProfileScreen()),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    final t = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
        boxShadow: AppShadows.lifted,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl, vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, t.navHome),
              _navItem(1, Icons.storefront_rounded, t.navShop),
              _navItem(2, Icons.shield_rounded, t.navProfile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _tab == index;
    final colors = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: () => setState(() => _tab = index),
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.transition,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: active ? colors.primarySoft : Colors.transparent,
            borderRadius: AppRadius.mdAll,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: active ? colors.primary : colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
