import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';

Container newOpeningBadge(bool isAr, BuildContext context) {
  return feedBadge(
    isAr: isAr,
    context: context,
    color: Theme.of(context).colorScheme.primary,
    text: isAr ? 'افتتح مؤخراً' : 'Just Opened',
  );
}

// ✅ دالة عامة يستخدمها feed_card.dart لكل الـ badges
Container feedBadge({
  required bool isAr,
  required BuildContext context,
  required Color color,
  required String text,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 6,
      vertical: 4,
    ), // ← vertical: 7 → 4
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
    ),
    // ✅ أضف alignment للـ Container
    alignment: Alignment.center,
    child: Text(
      text,
      textAlign: TextAlign.center, // ✅ يحل مشكلة المحاذاة
      // ✅ TextStyle مباشر بدل copyWith — يحل مشكلة التكرار
      style: TextStyle(
        color: AppColors.black,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        fontFamily: AppTypography.getBodyFontFamily(isAr ? 'ar' : 'en'),
        height: 1.4, // ← يمنع أي line height إضافي يسبب ظهور مزدوج
      ),
    ),
  );
}
