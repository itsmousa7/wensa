// lib/features/profile/presentation/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:future_riverpod/features/profile/presentation/widgets/profile_content.dart';
import 'package:future_riverpod/core/widgets/profile_error.dart';
import 'package:future_riverpod/features/profile/presentation/widgets/profile_skeleton.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final profileAsync = ref.watch(profileProvider);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: profileAsync.when(
          loading: () => const ProfileSkeleton(),
          error: (e, _) => ProfileError(isAr: isAr),
          data: (user) => ProfileContent(user: user, isAr: isAr),
        ),
      ),
    );
  }
}

// class SectionDivider extends StatelessWidget {
//   const SectionDivider({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//     return Padding(
//       padding: const EdgeInsets.only(left: 64, right: 16),
//       child: Divider(
//         height: 1,
//         thickness: 0.5,
//         color: cs.onSurface.withValues(alpha: 0.08),
//       ),
//     );
//   }
// }
