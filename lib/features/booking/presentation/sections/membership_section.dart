import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/membership_plan.dart';
import 'package:future_riverpod/features/booking/domain/repositories/booking_repository.dart';
import 'package:future_riverpod/features/booking/presentation/pages/payment_webview_page.dart';
import 'package:future_riverpod/features/booking/presentation/providers/availability_provider.dart';
import 'package:future_riverpod/features/booking/presentation/providers/booking_submit_provider.dart';
import 'package:future_riverpod/features/booking/presentation/providers/membership_submit_provider.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/bilingual_label.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/booking_date_strip.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/booking_summary_card.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/membership_plan_card.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/tickets_provider.dart'
    show bookingsRefreshProvider;
import 'package:future_riverpod/features/discounts/domain/discount_math.dart';
import 'package:future_riverpod/features/discounts/domain/models/auto_discount.dart';
import 'package:future_riverpod/features/discounts/presentation/providers/merchant_discounts_provider.dart';
import 'package:future_riverpod/features/discounts/presentation/providers/user_purchase_history_provider.dart';
import 'package:future_riverpod/features/discounts/presentation/widgets/promo_code_field.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Local state notifier
// ---------------------------------------------------------------------------

class _SelectedPlanNotifier extends Notifier<MembershipPlan?> {
  @override
  MembershipPlan? build() => null;
  void set(MembershipPlan? plan) => state = plan;
}

final _selectedMembershipPlanProvider =
    NotifierProvider<_SelectedPlanNotifier, MembershipPlan?>(
      _SelectedPlanNotifier.new,
    );

final _membershipPromoProvider =
    NotifierProvider.autoDispose<_MembershipPromoNotifier, PromoApplied?>(
        _MembershipPromoNotifier.new);

class _MembershipPromoNotifier extends Notifier<PromoApplied?> {
  @override
  PromoApplied? build() => null;
  void set(PromoApplied? p) => state = p;
}

// ---------------------------------------------------------------------------
// MembershipSection
// ---------------------------------------------------------------------------

class MembershipSection extends ConsumerStatefulWidget {
  const MembershipSection({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  final String placeId;
  final String placeName;

  @override
  ConsumerState<MembershipSection> createState() => _MembershipSectionState();
}

class _MembershipSectionState extends ConsumerState<MembershipSection> {
  @override
  Widget build(BuildContext context) {
    ref.listen<BookingSubmitState>(membershipSubmitProvider, (prev, next) {
      next.maybeWhen(
        success: (bookingId, paymentUrl, holdUntil, waylReferenceId) {
          if (paymentUrl.isNotEmpty) {
            PaymentWebViewPage.push(
              context,
              paymentUrl,
              referenceId: waylReferenceId,
              redirectionUrl: 'wansa://payment',
              onPaymentSuccess: (_, orderId) async {
                try {
                  await ref
                      .read(bookingRepositoryProvider)
                      .confirmMembershipPayment(bookingId, orderId);
                } catch (_) {}
                ref.read(membershipSubmitProvider.notifier).reset();
                ref.read(bookingsRefreshProvider.notifier).bump();
                ref.invalidate(userPurchaseHistoryProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Payment successful! Your membership is now active.',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.go('/bookings/m_$bookingId');
                }
              },
              onPaymentFailed: () {
                ref.read(membershipSubmitProvider.notifier).reset();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment failed. Please try again.'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              },
              onPaymentCancelled: () async {
                // Await the server-side cancel before releasing the Proceed
                // button — otherwise the next tap races the still-`pending`
                // membership row and hits a constraint conflict.
                await ref
                    .read(membershipSubmitProvider.notifier)
                    .cancelPending();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment cancelled.')),
                );
              },
            );
          } else {
            ref.read(membershipSubmitProvider.notifier).reset();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Unable to get payment link. Please try again.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        error: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
        orElse: () {},
      );
    });

    return _MembershipFormView(
        placeId: widget.placeId, placeName: widget.placeName);
  }
}

// ---------------------------------------------------------------------------
// Plan selection + review form
// ---------------------------------------------------------------------------

class _MembershipFormView extends ConsumerWidget {
  const _MembershipFormView({required this.placeId, required this.placeName});

  final String placeId;
  final String placeName;

  static String _formatPrice(int priceIqd) {
    final formatted = priceIqd.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'IQD $formatted';
  }

  static ({int discount, int finalAmount, String label}) _resolveEffective({
    required int subtotal,
    required PromoApplied? promo,
    required AutoDiscount? autoDiscount,
  }) {
    if (promo != null) {
      return (
        discount: promo.discountAmount,
        finalAmount: promo.finalAmount,
        label: '${promo.percent.round()}% OFF · ${promo.code}',
      );
    }
    if (autoDiscount != null) {
      final r = computeDiscount(
        subtotal: subtotal,
        percent: autoDiscount.percent,
        maxCap: autoDiscount.maxDiscountAmount,
      );
      return (
        discount: r.discountAmount,
        finalAmount: r.finalAmount,
        label: '${autoDiscount.percent.round()}% OFF',
      );
    }
    return (discount: 0, finalAmount: subtotal, label: '');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPlan = ref.watch(_selectedMembershipPlanProvider);
    final plansAsync = ref.watch(membershipPlansProvider(placeId));
    final submitState = ref.watch(membershipSubmitProvider);
    final isLoading = submitState.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final today = DateTime.now();

    final placeAsync = ref.watch(placeDetailsProvider(placeId));
    final place = placeAsync.value;
    final autoDiscount = ref.watch(bestAutoDiscountProvider(AutoDiscountKey(
      orderType: 'memberships',
      placeId: placeId,
      merchantId: place?.merchantId,
      categoryId: place?.categoryId,
    )));
    final promo = ref.watch(_membershipPromoProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Plan list ──────────────────────────────────────────────
          BookingSectionLabel(
            isAr ? 'اختر خطة العضوية' : 'Select Membership Plan',
          ),
          plansAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Error loading plans: $e'),
            ),
            data: (plans) {
              if (plans.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    isAr
                        ? 'لا توجد خطط عضوية متاحة لهذا الموقع.'
                        : 'No membership plans available for this location.',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: plans.map((plan) {
                    final isSelected = selectedPlan?.id == plan.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MembershipPlanCard(
                        plan: plan,
                        isSelected: isSelected,
                        onTap: () {
                          ref
                              .read(_selectedMembershipPlanProvider.notifier)
                              .set(isSelected ? null : plan);
                        },
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // ── Membership summary card (animated) ─────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
            ),
            child: selectedPlan != null
                ? Builder(
                    key: const ValueKey('summary-visible'),
                    builder: (context) {
                      final subtotal = selectedPlan.priceIqd;
                      final eff = _MembershipFormView._resolveEffective(
                        subtotal: subtotal,
                        promo: promo,
                        autoDiscount: autoDiscount,
                      );

                      // Re-validate promo on subtotal change.
                      if (promo != null &&
                          promo.finalAmount + promo.discountAmount != subtotal) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref.read(_membershipPromoProvider.notifier).set(null);
                        });
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: BookingSummaryCard(
                          title: isAr ? 'ملخص العضوية' : 'Membership Summary',
                          badgeText: isAr
                              ? '${selectedPlan.durationDays} أيام'
                              : '${selectedPlan.durationDays} days',
                          rows: [
                            BookingSummaryRow(
                              icon: Icons.store_rounded,
                              label: isAr ? 'المكان' : 'Venue',
                              value: placeName,
                            ),
                            BookingSummaryRow(
                              icon: Icons.card_membership_rounded,
                              label: isAr ? 'الخطة' : 'Plan',
                              valueWidget: BilingualLabel(
                                ar: selectedPlan.nameAr,
                                en: selectedPlan.nameEn,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ),
                            BookingSummaryRow(
                              icon: Icons.date_range_rounded,
                              label: isAr ? 'المدة' : 'Duration',
                              value: isAr
                                  ? '${selectedPlan.durationDays} أيام'
                                  : '${selectedPlan.durationDays} days',
                            ),
                            BookingSummaryRow(
                              icon: Icons.event_available_rounded,
                              label: isAr ? 'تاريخ البداية' : 'Start Date',
                              value: bookingFormatDate(today),
                            ),
                            BookingSummaryRow(
                              icon: Icons.event_busy_rounded,
                              label: isAr ? 'تاريخ الانتهاء' : 'End Date',
                              value: bookingFormatDate(
                                today.add(
                                  Duration(days: selectedPlan.durationDays),
                                ),
                              ),
                            ),
                          ],
                          subtotalLabel: isAr ? 'المجموع' : 'Subtotal',
                          subtotalValue:
                              eff.discount > 0 ? _formatPrice(subtotal) : null,
                          discountLabel: eff.discount > 0 ? eff.label : null,
                          discountValue: eff.discount > 0
                              ? '−${_formatPrice(eff.discount)}'
                              : null,
                          totalLabel: isAr ? 'الإجمالي' : 'Total Amount',
                          totalValue: _formatPrice(eff.finalAmount),
                          extraSlot: subtotal > 0
                              ? PromoCodeField(
                                  orderType: 'memberships',
                                  subtotal: subtotal,
                                  placeId: placeId,
                                  merchantId: place?.merchantId,
                                  categoryId: place?.categoryId,
                                  applied: promo,
                                  isAr: isAr,
                                  onChange: (p) => ref
                                      .read(_membershipPromoProvider.notifier)
                                      .set(p),
                                )
                              : null,
                          actionLabel:
                              isAr ? 'المتابعة للدفع' : 'Proceed to Payment',
                          onAction: () {
                            final plan = selectedPlan;
                            ref
                                .read(membershipSubmitProvider.notifier)
                                .createMembership(
                                  placeId: placeId,
                                  planId: plan.id,
                                  promoCode: promo?.code,
                                );
                          },
                          isLoading: isLoading,
                        ),
                      );
                    },
                  )
                : const SizedBox.shrink(key: ValueKey('summary-hidden')),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
