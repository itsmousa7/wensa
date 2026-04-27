import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/membership_plan.dart';
import 'package:future_riverpod/features/booking/presentation/providers/availability_provider.dart';
import 'package:future_riverpod/features/booking/presentation/providers/booking_submit_provider.dart';
import 'package:future_riverpod/features/booking/presentation/providers/membership_submit_provider.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/membership_plan_card.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
        success: (bookingId, paymentUrl, holdUntil) async {
          if (paymentUrl.isNotEmpty) {
            final uri = Uri.parse(paymentUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
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

    return submitState.maybeWhen(
      success: (bookingId, paymentUrl, holdUntil) =>
          const _MembershipPaymentInProgressView(),
      orElse: () => _MembershipFormView(
        placeId: placeId,
        placeName: placeName,
      ),
    );
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
        _SummaryRow(label: 'Plan', value: selectedPlan.nameEn),
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

// ---------------------------------------------------------------------------
// Payment in-progress screen
// ---------------------------------------------------------------------------

class _MembershipPaymentInProgressView extends ConsumerWidget {
  const _MembershipPaymentInProgressView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.payment_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'Payment in progress...',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete the payment in your browser, then return here.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.goNamed('bookingsHistory'),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("I've completed payment"),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                ref.read(membershipSubmitProvider.notifier).reset();
                ref.read(_selectedMembershipPlanProvider.notifier).set(null);
              },
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}
