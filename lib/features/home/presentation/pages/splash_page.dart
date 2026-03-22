import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/router/router_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SplashPage — animation + navigation only
//
//  Supabase.initialize() has been moved to main() so it always runs before
//  any Riverpod provider is created. This page now only:
//    1. Shows the brand animation (600ms)
//    2. Marks Supabase as ready (triggers router redirect evaluation)
//    3. Navigates based on session state
//
//  No try/catch around init needed here anymore.
// ─────────────────────────────────────────────────────────────────────────────

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _navigate();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    // Minimum splash time so it doesn't flash
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // Mark ready — this unblocks _RouterNotifier and the redirect guard
    ref.read(supabaseReadyProvider.notifier).setReady();

    // Navigate based on current session (Supabase is already initialized)
    final session = Supabase.instance.client.auth.currentSession;
    final isVerified =
        Supabase.instance.client.auth.currentUser?.emailConfirmedAt != null;

    if (!mounted) return;

    if (session != null && isVerified) {
      context.go('/home');
    } else if (session != null && !isVerified) {
      context.go('/verify-email');
    } else {
      context.go('/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreenPrimary,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Text(
            'ونسة',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
