import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';
import '../services/progress/progress_repository.dart';
import '../design_system/atoms/fk_parent_gate.dart';
import '../features/auth/application/auth_controller.dart';
import 'levels_screen.dart';
import 'shop_screen.dart';
import 'profile_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with WidgetsBindingObserver {
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, 'Home'),
              _navItem(1, Icons.storefront_rounded, 'Shop'),
              _navItem(2, Icons.shield_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.cardActive
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: active ? AppTheme.primary : AppTheme.textMedium,
            ),
          ],
        ),
      ),
    );
  }
}
