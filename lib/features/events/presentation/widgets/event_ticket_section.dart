// lib/features/events/presentation/widgets/event_ticket_section.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class EventTicketSection extends StatelessWidget {
  const EventTicketSection({
    super.key,
    required this.ticketPrice,
    required this.ticketUrl,
    required this.isAr,
  });

  final double ticketPrice;
  final String ticketUrl;
  final bool isAr;

  /// Formats a price with thousands separators: 75000 → "75,000"
  static String _formatPrice(double price) {
    // Strip unnecessary decimals: 75000.0 → "75000", 75000.5 → "75000.5"
    final isWhole = price == price.truncateToDouble();
    final raw = isWhole ? price.toInt().toString() : price.toStringAsFixed(2);

    // Insert comma every 3 digits from the right (integer part only)
    final parts = raw.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';

    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '$buf$decPart';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceLabel = ticketPrice == 0
        ? (isAr ? 'مجاني' : 'Free')
        : '${_formatPrice(ticketPrice)} ${isAr ? 'د.ع' : 'IQD'}';

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        // ── Price chip ─────────────────────────────────────────────────
        _Chip(
          label: priceLabel,
          color: ticketPrice == 0 ? AppColors.success : cs.primary,
          icon: CupertinoIcons.money_dollar,
        ),

        // ── Buy button ─────────────────────────────────────────────────
        _Chip(
          label: isAr ? 'احجز تذكرة' : 'Buy Tickets',
          color: isDark ? AppColors.headline2 : AppColors.headline,
          icon: CupertinoIcons.ticket,
          onTap: () => _launch(ticketUrl),
        ),
      ],
    );
  }

  Future<void> _launch(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

// ── Shared chip ────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.icon,
    this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final container = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: tt.headlineSmall?.copyWith(color: color, fontSize: 12),
          ),
        ],
      ),
    );

    if (onTap == null) return container;
    return GestureDetector(onTap: onTap, child: container);
  }
}
