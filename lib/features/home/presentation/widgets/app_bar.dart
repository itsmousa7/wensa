import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/auth/presentation/providers/user_profile_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Helper — يكشف إذا كان النص يحتوي على حروف عربية
//
//  نستخدمه لتحديد فونت الاسم بشكل مستقل عن لغة التطبيق
//
//  مثال:
//    لغة التطبيق = English  +  اسم المستخدم = "محمد"  → يستخدم Zain (عربي)
//    لغة التطبيق = العربية  +  اسم المستخدم = "John"   → يستخدم Roboto (إنجليزي)
// ─────────────────────────────────────────────────────────────────────────────
bool _isArabicText(String text) => RegExp(r'[\u0600-\u06FF]').hasMatch(text);

class HomeAppBar extends ConsumerWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final userAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    // TextTheme بناءً على لغة التطبيق — للـ UI العام (greeting، labels)
    final uiLocale = isAr ? 'ar' : 'en';
    final textTheme = AppTypography.getTextTheme(uiLocale, context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Greeting + Username ──────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "مرحباً،" / "Hello," — دائماً بفونت لغة التطبيق
              Text(
                isAr ? 'مرحباً،' : 'Hello,',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 2),

              // ── Username ──────────────────────────────────────────────────
              userAsync.when(
                // ✅ Skeleton
                loading: () => Skeletonizer(
                  enabled: true,
                  effect: ShimmerEffect(
                    baseColor: theme.colorScheme.surfaceContainer,
                    highlightColor: theme.colorScheme.surfaceContainerHighest,
                    duration: const Duration(milliseconds: 1000),
                  ),
                  child: Container(
                    width: 130,
                    height: 20,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),

                error: (_, _) => Text(
                  '',
                  style: textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                data: (users) {
                  final firstName = users.first.firstName;

                  // ✅ نكشف لغة الاسم نفسه — مستقل عن لغة التطبيق
                  final nameLocale = _isArabicText(firstName) ? 'ar' : 'en';

                  // TextTheme بناءً على لغة الاسم (مو لغة التطبيق)
                  final nameTT = AppTypography.getTextTheme(
                    nameLocale,
                    context,
                  );

                  return Text(
                    '$firstName 👋',
                    style: nameTT.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      // titleMedium = 16px w600
                      // Zain إذا الاسم عربي ← Roboto إذا الاسم إنجليزي
                    ),
                  );
                },
              ),
            ],
          ),
          Spacer(),
          // ── Bell ──────────────────────────────────────────────────────────
          Stack(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    CupertinoIcons.bell,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
