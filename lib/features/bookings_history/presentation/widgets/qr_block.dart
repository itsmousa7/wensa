// lib/features/bookings_history/presentation/widgets/qr_block.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrBlock extends StatelessWidget {
  const QrBlock({super.key, required this.qrToken});

  final String qrToken;

  @override
  Widget build(BuildContext context) {
    final merchantUrl = dotenv.env['MERCHANT_PORTAL_URL'] ?? '';
    final qrData = '$merchantUrl/scan/$qrToken';

    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: QrImageView(
        data: qrData.isEmpty ? qrToken : qrData,
        version: QrVersions.auto,
        size: 200,
        backgroundColor: Colors.white,
      ),
    );
  }
}
