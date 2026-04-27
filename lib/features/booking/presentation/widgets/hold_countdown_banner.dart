import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/presentation/providers/hold_provider.dart';

class HoldCountdownBanner extends ConsumerWidget {
  const HoldCountdownBanner({super.key, required this.holdUntil});

  final String holdUntil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seconds = ref.watch(holdCountdownProvider(holdUntil));

    if (seconds <= 0) {
      return MaterialBanner(
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        content: Text(
          'Slot expired — please restart',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [SizedBox.shrink()],
      );
    }

    return MaterialBanner(
      backgroundColor: Colors.amber.shade100,
      content: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 18, color: Colors.amber),
          const SizedBox(width: 8),
          Text(
            'Hold expires in $seconds seconds',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: const [SizedBox.shrink()],
    );
  }
}
