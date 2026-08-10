import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/tickets_provider.dart'
    show bookingsRefreshProvider;
import 'package:future_riverpod/features/discounts/presentation/providers/user_purchase_history_provider.dart';
import 'package:go_router/go_router.dart';

/// Shows the "Payment Method" bottom sheet (Cash / E-Payment) and returns the
/// user's choice, or null if dismissed without choosing. The Cash row is
/// omitted entirely when [cashEnabled] is false — the merchant has cash off.
Future<PaymentMethod?> showPaymentMethodSheet(
  BuildContext context, {
  required bool cashEnabled,
}) {
  return showModalBottomSheet<PaymentMethod>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _PaymentMethodSheet(cashEnabled: cashEnabled),
  );
}

class _PaymentMethodSheet extends StatelessWidget {
  const _PaymentMethodSheet({required this.cashEnabled});
  final bool cashEnabled;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? 'طريقة الدفع' : 'Payment Method',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (cashEnabled) ...[
              _PaymentMethodRow(
                icon: Icons.payments_rounded,
                iconBg: const Color(0xFF17A673),
                title: isAr ? 'نقداً' : 'Cash',
                subtitle: isAr ? 'ادفع عند الوصول' : 'Pay at the venue',
                onTap: () => Navigator.of(context).pop(PaymentMethod.cash),
              ),
              const Divider(height: 24),
            ],
            _PaymentMethodRow(
              icon: Icons.credit_card_rounded,
              iconBg: cs.primary,
              title: isAr ? 'الدفع الإلكتروني' : 'E-Payment',
              subtitle: isAr ? 'ادفع الآن عبر الإنترنت' : 'Pay online now',
              onTap: () => Navigator.of(context).pop(PaymentMethod.wayl),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.outline),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.outline),
          ],
        ),
      ),
    );
  }
}

/// Shared tail for a cash-confirmed booking/membership: the server already
/// confirmed it (no webview needed), so just refresh caches and land on the
/// ticket page. [routeId] is the raw booking id, or `m_<membershipId>` for a
/// membership — same id shape `context.go('/bookings/$routeId')` expects
/// elsewhere in this feature.
void goToCashBookingSuccess({
  required BuildContext context,
  required WidgetRef ref,
  required String routeId,
  required VoidCallback resetSubmitState,
}) {
  resetSubmitState();
  ref.read(bookingsRefreshProvider.notifier).bump();
  ref.invalidate(userPurchaseHistoryProvider);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking confirmed! Pay with cash at the venue.'),
        backgroundColor: Colors.green,
      ),
    );
    context.go('/bookings/$routeId');
  }
}
