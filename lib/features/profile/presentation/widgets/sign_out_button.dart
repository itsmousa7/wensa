import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_repository_provider.dart';

class SignOutButton extends ConsumerWidget {
  const SignOutButton({super.key, required this.isAr});

  final bool isAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(authRepositoryProvider).signOut(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.alert.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.alert.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.square_arrow_right,
              color: AppColors.alert,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              isAr ? 'تسجيل الخروج' : 'Sign Out',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.alert,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
