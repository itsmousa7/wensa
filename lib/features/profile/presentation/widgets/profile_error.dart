import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/profile/presentation/providers/user_profile_provider.dart';

class ProfileError extends ConsumerWidget {
  const ProfileError({super.key, required this.isAr});

  final bool isAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return GlobalErrorWidget(
      cs: cs,
      isAr: isAr,
      tt: tt,
      onTap: () => ref.invalidate(profileProvider),
    );
  }
}

class GlobalErrorWidget extends StatelessWidget {
  const GlobalErrorWidget({
    super.key,
    required this.cs,
    required this.isAr,
    required this.tt,
    this.onTap,
  });

  final ColorScheme cs;
  final bool isAr;
  final TextTheme tt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onTap,
              icon: Icon(CupertinoIcons.arrow_counterclockwise, size: 60),
              color: cs.outline,
            ),
            const SizedBox(height: 30),
            Text(
              isAr
                  ? 'حدث خطأ، حاول مجدداً'
                  : 'Something went wrong. Try again.',
              style: tt.titleMedium?.copyWith(color: cs.outline),
            ),
          ],
        ),
      ),
    );
  }
}
