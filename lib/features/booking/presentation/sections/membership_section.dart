import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/membership_plan.dart';
import 'package:future_riverpod/features/booking/presentation/providers/availability_provider.dart';
import 'package:future_riverpod/features/booking/presentation/providers/booking_submit_provider.dart';
import 'package:future_riverpod/features/booking/presentation/providers/membership_submit_provider.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/bilingual_label.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/booking_date_strip.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/booking_summary_card.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/membership_plan_card.dart';
import 'package:future_riverpod/features/booking/domain/repositories/booking_repository.dart';
import 'package:future_riverpod/features/booking/presentation/pages/payment_webview_page.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/tickets_provider.dart' show bookingsRefreshProvider;
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
        _SelectedPlanNotifier.new);

// ---------------------------------------------------------------------------
// MembershipSection
// ---------------------------------------------------------------------------

class MembershipSection extends ConsumerWidget {
  const MembershipSection({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  final String placeId;
  final String placeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Payment successful! Your membership is now active.'),
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
                    backgroundColor: Color(0xFFE53935),
                  ),
                );
              },
              onPaymentCancelled: () {
                ref.read(membershipSubmitProvider.notifier).reset();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment cancelled.')),
                );
              },
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

    return _MembershipFormView(placeId: placeId, placeName: placeName);
  }
}

// ---------------------------------------------------------------------------
// Plan selection + review form
// ---------------------------------------------------------------------------

class _MembershipFormView extends ConsumerWidget {
  const _MembershipFormView({
    required this.placeId,
    required this.placeName,
  });

  final String placeId;
  final String placeName;

  static String _formatPrice(int priceIqd) {
    final formatted = priceIqd.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'IQD $formatted';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPlan = ref.watch(_selectedMembershipPlanProvider);
    final plansAsync = ref.watch(membershipPlansProvider(placeId));
    final submitState = ref.watch(membershipSubmitProvider);
    final isLoading =
        submitState.maybeWhen(loading: () => true, orElse: () => false);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final today = DateTime.now();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Plan list ──────────────────────────────────────────────
          BookingSectionLabel(
              isAr ? 'اختر خطة العضوية' : 'Select Membership Plan'),
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
                      horizontal: 20, vertical: 8),
                  child: Text(
                    isAr
                        ? 'لا توجد خطط عضوية متاحة لهذا الموقع.'
                        : 'No membership plans available for this location.',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5)),
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
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            ),
            child: selectedPlan != null
                ? Padding(
                    key: const ValueKey('summary-visible'),
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
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
                              today.add(Duration(days: selectedPlan.durationDays))),
                        ),
                      ],
                      totalLabel: isAr ? 'الإجمالي' : 'Total Amount',
                      totalValue: _formatPrice(selectedPlan.priceIqd),
                      actionLabel:
                          isAr ? 'المتابعة للدفع' : 'Proceed to Payment',
                      onAction: () {
                        final plan = selectedPlan;
                        ref
                            .read(membershipSubmitProvider.notifier)
                            .createMembership(
                              placeId: placeId,
                              planId: plan.id,
                            );
                      },
                      isLoading: isLoading,
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('summary-hidden')),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
