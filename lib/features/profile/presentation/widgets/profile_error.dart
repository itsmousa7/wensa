import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';

class ProfileError extends StatelessWidget {
  const ProfileError({super.key, required this.isAr});

  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return GlobalErrorWidget(cs: cs, isAr: isAr, tt: tt);
  }
}

class GlobalErrorWidget extends StatelessWidget {
  const GlobalErrorWidget({
    super.key,
    required this.cs,
    required this.isAr,
    required this.tt,
  });

  final ColorScheme cs;
  final bool isAr;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.wifi_slash, color: cs.primary, size: 100),
            const SizedBox(height: 30),
            Text(
              isAr
                  ? 'حدث خطأ، حاول مجدداً'
                  : 'Something went wrong. Try again.',
              style: tt.titleMedium?.copyWith(color: AppColors.alert),
            ),
          ],
        ),
      ),
    );
  }
}
