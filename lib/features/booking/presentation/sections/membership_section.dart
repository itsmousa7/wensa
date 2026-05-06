import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/membership_plan.dart';
import 'package:future_riverpod/features/booking/presentation/providers/availability_provider.dart';
import 'package:future_riverpod/features/booking/presentation/providers/booking_submit_provider.dart';
import 'package:future_riverpod/features/booking/presentation/providers/membership_submit_provider.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/bilingual_label.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/membership_plan_card.dart';
import 'package:future_riverpod/features/booking/domain/repositories/booking_repository.dart';
import 'package:future_riverpod/features/booking/presentation/pages/payment_webview_page.dart';
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
    final submitState = ref.watch(membershipSubmitProvider);

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
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment successful! Your membership is active.'),
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

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPlan = ref.watch(_selectedMembershipPlanProvider);
    final plansAsync = ref.watch(membershipPlansProvider(placeId));
    final submitState = ref.watch(membershipSubmitProvider);
    final isLoading = submitState.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Step 1: Plan list ----
          Text(
            'Select a Membership Plan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          plansAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading plans: $e'),
            data: (plans) {
              if (plans.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No membership plans available for this place.'),
                );
              }
              return Column(
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
              );
            },
          ),
          const SizedBox(height: 8),

          // ---- Step 2: Review + Pay ----
          if (selectedPlan != null) ...[
            const Divider(),
            const SizedBox(height: 12),
            _MembershipReviewPanel(
              selectedPlan: selectedPlan,
              placeName: placeName,
              placeId: placeId,
              isLoading: isLoading,
              formatDate: _formatDate,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Review + Pay panel
// ---------------------------------------------------------------------------

class _MembershipReviewPanel extends ConsumerWidget {
  const _MembershipReviewPanel({
    required this.selectedPlan,
    required this.placeName,
    required this.placeId,
    required this.isLoading,
    required this.formatDate,
  });

  final MembershipPlan selectedPlan;
  final String placeName;
  final String placeId;
  final bool isLoading;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final endDate = today.add(Duration(days: selectedPlan.durationDays));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Membership Summary',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _SummaryRow(label: 'Place', value: placeName),
        _SummaryRowBilingual(
          label: 'Plan',
          arValue: selectedPlan.nameAr,
          enValue: selectedPlan.nameEn,
        ),
        _SummaryRow(
            label: 'Duration', value: '${selectedPlan.durationDays} days'),
        _SummaryRow(label: 'Start Date', value: formatDate(today)),
        _SummaryRow(label: 'End Date', value: formatDate(endDate)),
        _SummaryRow(label: 'Total', value: '${selectedPlan.priceIqd} IQD'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: isLoading
              ? null
              : () {
                  ref
                      .read(membershipSubmitProvider.notifier)
                      .createMembership(
                        placeId: placeId,
                        planId: selectedPlan.id,
                      );
                },
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Proceed to Pay'),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SummaryRowBilingual extends StatelessWidget {
  const _SummaryRowBilingual({
    required this.label,
    required this.arValue,
    required this.enValue,
  });

  final String label;
  final String arValue;
  final String enValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          BilingualLabel(
            ar: arValue,
            en: enValue,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
