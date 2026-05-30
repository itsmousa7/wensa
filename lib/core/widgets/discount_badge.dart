import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class DiscountBadge extends StatelessWidget {
  const DiscountBadge({
    super.key,
    required this.percent,
    this.size = DiscountBadgeSize.small,
  });

  final int percent;
  final DiscountBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final isSmall = size == DiscountBadgeSize.small;
    final double iconSize = isSmall ? 8 : 10;
    final double fontSize = isSmall ? 10 : 12;
    final EdgeInsets pad = isSmall
        ? const EdgeInsets.symmetric(horizontal: 5, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 6, vertical: 5);
    final double gap = isSmall ? 2 : 4;

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: AppColors.lightRedSecondary,
        borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_offer_rounded,
            size: iconSize,
            color: AppColors.white,
          ),
          Gap(gap),
          Text(
            '$percent% OFF',
            style: TextStyle(
              color: AppColors.white,
              fontSize: fontSize,
              fontFamily: 'Ibm-Bold',
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

enum DiscountBadgeSize { small, medium }

/// Soft, outlined companion badge that surfaces a discount's spending cap,
/// e.g. "Max Discount 5,000 IQD". Pairs with the solid red [DiscountBadge]
/// without competing with it visually.
class MaxDiscountBadge extends StatelessWidget {
  const MaxDiscountBadge({
    super.key,
    required this.maxAmount,
    required this.isAr,
  });

  final num maxAmount;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final amount = NumberFormat('#,##0').format(maxAmount);
    final currency = isAr ? 'د.ع' : 'IQD';
    final label = isAr ? 'أقصى خصم' : 'Max Discount';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.lightRedSecondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.lightRedSecondary.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sell_outlined,
            size: 11,
            color: AppColors.lightRedSecondary,
          ),
          const Gap(5),
          Text(
            '$label $amount $currency',
            style: TextStyle(
              color: AppColors.lightRedSecondary,
              fontSize: 11,
              fontFamily: 'Ibm-Bold',
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
