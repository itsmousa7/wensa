  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:future_riverpod/core/constants/theme/app_colors.dart';
  import 'package:future_riverpod/core/router/router_provider.dart';
  import 'package:go_router/go_router.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';

  // ─────────────────────────────────────────────────────────────────────────────
  //  SplashPage
  //  ✅ Supabase.initialize() runs HERE so runApp() is never blocked
  //  ✅ After init, navigates based on auth — router redirect handles the rest
  // ─────────────────────────────────────────────────────────────────────────────
  class SplashPage extends ConsumerStatefulWidget {
    const SplashPage({super.key});

    @override
    ConsumerState<SplashPage> createState() => _SplashPageState();
  }

  class _SplashPageState extends ConsumerState<SplashPage>
      with SingleTickerProviderStateMixin {
    bool _hasError = false;
    late AnimationController _ctrl;
    late Animation<double> _fade;

    @override
    void initState() {
      super.initState();
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
      _ctrl.forward();
      _init();
    }

    @override
    void dispose() {
      _ctrl.dispose();
      super.dispose();
    }

    Future<void> _init() async {
      try {
        await Supabase.initialize(
          url: 'https://qvozjwlkzordudkhamcu.supabase.co',
          anonKey:
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
              '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF2b3pqd2xrem9yZHVka2hhbWN1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEwOTA4MzksImV4cCI6MjA4NjY2NjgzOX0'
              '.VYsaJ7TST2PuHQFmalwRuENxpeUGylkHI59YiRyjxzc',
          // ✅ Reduce realtime overhead
          realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 2),
          // ✅ Prevent multiple background refresh calls on startup
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
            autoRefreshToken: true,
          ),
        );

        // ✅ Mark Supabase as ready — this triggers GoRouterRefreshNotifier
        ref.read(supabaseReadyProvider.notifier).setReady();

        // ✅ Minimum visible time so splash doesn't flash
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;

        // ✅ Navigate — router redirect will validate auth from here
        final session = Supabase.instance.client.auth.currentSession;
        final isVerified =
            Supabase.instance.client.auth.currentUser?.emailConfirmedAt != null;

        if (session != null && isVerified) {
          context.go('/home');
        } else if (session != null && !isVerified) {
          context.go('/verify-email');
        } else {
          context.go('/signin');
        }
      } catch (_) {
        if (mounted) setState(() => _hasError = true);
      }
    }

    @override
    Widget build(BuildContext context) {
      final cs = Theme.of(context).colorScheme;

      return Scaffold(
        backgroundColor: AppColors.lightGreenPrimary,
        body: Center(
          child: _hasError
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 40,
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'تعذّر الاتصال',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() => _hasError = false);
                        _init();
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                )
              : FadeTransition(
                  opacity: _fade,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ونسة',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }
  }
