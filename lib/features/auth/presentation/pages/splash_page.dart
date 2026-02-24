import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/auth/presentation/providers/google_auth_provider.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_button.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text('Welcome to Wain flosi App'),
            const Gap(300),
            Center(
              child: Consumer(
                builder: (context, ref, child) => AppButton.secondary(
                  onPressed: () async {
                    try {
                      await ref
                          .read(googleAuthProvider.notifier)
                          .signInWithGoogle();
                      // Don't navigate manually — GoRouterRefreshNotifier handles it
                    } catch (e) {
                      debugPrint(e.toString());
                    }
                  },
                  color: AppColors.white,
                  icon: SvgPicture.asset(
                    'assets/icons/google.svg',
                    width: width * 0.02,
                    height: height * 0.02,
                  ),
                  label: 'Continue with Google',
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                context.goNamed(RouteNames.signup);
              },
              child: const Text('Register with email'),
            ),
          ],
        ),
      ),
    );
  }
}
