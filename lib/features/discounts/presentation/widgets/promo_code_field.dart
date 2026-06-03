import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/auth/presentation/providers/supabase_provider.dart';
import 'package:future_riverpod/features/discounts/presentation/providers/user_purchase_history_provider.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

class PromoApplied {
  const PromoApplied({
    required this.code,
    required this.percent,
    required this.discountAmount,
    required this.finalAmount,
    required this.promoCodeId,
  });
  final String code;
  final double percent;
  final int discountAmount;
  final int finalAmount;
  final String promoCodeId;
}

/// Compact text field + Apply button that previews a promo code against
/// `business.preview_promo_code`. Reports applied state via [onChange].
///
/// The parent owns the [applied] state and passes it back in to keep the
/// widget driven by external state (so the section can clear it when the
/// subtotal changes).
class PromoCodeField extends ConsumerStatefulWidget {
  const PromoCodeField({
    super.key,
    required this.orderType, // 'bookings' | 'memberships'
    required this.subtotal,
    required this.placeId,
    required this.merchantId,
    required this.categoryId,
    required this.applied,
    required this.onChange,
    required this.isAr,
  });

  final String orderType;
  final int subtotal;
  final String? placeId;
  final String? merchantId;
  final String? categoryId;
  final PromoApplied? applied;
  final ValueChanged<PromoApplied?> onChange;
  final bool isAr;

  @override
  ConsumerState<PromoCodeField> createState() => _PromoCodeFieldState();
}

class _PromoCodeFieldState extends ConsumerState<PromoCodeField> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_error != null) {
      setState(() => _error = null);
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  String _mapReason(String reason) {
    final ar = widget.isAr;
    switch (reason) {
      case 'not_authenticated':
        return ar
            ? 'يرجى تسجيل الدخول لاستخدام الرمز'
            : 'Please sign in to use a code';
      case 'not_found':
        return ar ? 'الرمز غير موجود' : 'Code not found';
      case 'inactive':
        return ar ? 'هذا الرمز غير مفعل' : 'This code is no longer active';
      case 'not_started':
        return ar ? 'هذا الرمز غير صالح بعد' : "This code isn't valid yet";
      case 'expired':
        return ar ? 'انتهت صلاحية الرمز' : 'This code has expired';
      case 'wrong_order_type':
        return ar ? 'هذا الرمز لا يُستخدم هنا' : "This code can't be used here";
      case 'not_first_purchase':
      case 'not_first_purchase_at_place':
        return ar ? 'صالح لأول عملية شراء فقط' : 'Only valid on first purchase';
      case 'not_new_customer':
        return ar ? 'للعملاء الجدد فقط' : 'Only valid for new customers';
      case 'out_of_scope':
        return ar ? 'لا يسري هذا الرمز هنا' : "This code doesn't apply here";
      case 'limit_reached':
        return ar ? 'وصل الرمز للحد الأقصى' : 'This code has reached its limit';
      case 'user_limit_reached':
        return ar
            ? 'استخدمت هذا الرمز من قبل'
            : "You've already used this code";
      default:
        return ar ? 'تعذّر تطبيق الرمز' : 'Could not apply this code';
    }
  }

  Future<void> _apply() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    final code = raw.toUpperCase();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final history = await ref.read(
        userPurchaseHistoryProvider(widget.placeId).future,
      );
      final client = ref.read(supabaseProvider);
      final res = await client
          .schema('business')
          .rpc(
            'preview_promo_code',
            params: {
              'p_code': code,
              'p_order_type': widget.orderType,
              'p_amount': widget.subtotal,
              'p_category_id': widget.categoryId,
              'p_merchant_id': widget.merchantId,
              'p_place_id': widget.placeId,
              'p_is_first_purchase_at_place': history.isFirstPurchaseAtPlace,
              'p_is_new_customer': history.isNewCustomer,
            },
          );
      final map = (res as Map).cast<String, dynamic>();
      if (map['valid'] == true) {
        widget.onChange(
          PromoApplied(
            code: code,
            percent: (map['percent'] as num).toDouble(),
            discountAmount: (map['discount_amount'] as num).round(),
            finalAmount: (map['final_amount'] as num).round(),
            promoCodeId: map['promo_code_id'] as String,
          ),
        );
      } else {
        widget.onChange(null);
        setState(() => _error = _mapReason((map['reason'] as String?) ?? ''));
      }
    } catch (_) {
      widget.onChange(null);
      setState(
        () => _error = widget.isAr
            ? 'تعذّر التحقق من الرمز'
            : 'Could not verify code',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _remove() {
    _controller.clear();
    setState(() => _error = null);
    widget.onChange(null);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final applied = widget.applied;
    final isAr = widget.isAr;

    if (applied != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.successDark.withValues(alpha: 0.08),
          borderRadius: AppSpacing.borderRadiusMD,
          border: Border.all(
            color: AppColors.successDark.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.successDark,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isAr
                    ? 'رمز "${applied.code}" مطبّق · خصم ${applied.percent.round()}%'
                    : 'Code "${applied.code}" applied · ${applied.percent.round()}% OFF',
                style: const TextStyle(
                  color: AppColors.successDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            GestureDetector(
              onTap: _remove,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.close_rounded, size: 18, color: cs.outline),
              ),
            ),
          ],
        ),
      );
    }

    final hasText = _controller.text.trim().isNotEmpty;
    final canApply = hasText && !_loading;
    final fontFamily = isAr ? 'Graphik-Extra-Bold' : 'Ibm-Bold';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? cs.surfaceContainerHighest
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsetsDirectional.only(start: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_loading,
                  style: TextStyle(color: cs.outline),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: isAr ? 'رمز الخصم' : 'Promo code',
                    hintStyle: TextStyle(color: cs.onTertiary),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) {
                    if (canApply) _apply();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: _ApplyButton(
                  enabled: canApply,
                  loading: _loading,
                  label: isAr ? 'تطبيق' : 'Apply',
                  fontFamily: fontFamily,
                  onTap: _apply,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.danger, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({
    required this.enabled,
    required this.loading,
    required this.label,
    required this.fontFamily,
    required this.onTap,
    required this.color,
  });

  final bool enabled;
  final bool loading;
  final String label;
  final String fontFamily;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: enabled
          ? color
          : Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.15)
              : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    color: enabled ? Colors.white : cs.onTertiary,
                    fontSize: 14,
                  ),
                ),
        ),
      ),
    );
  }
}
