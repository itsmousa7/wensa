import 'package:flutter/material.dart';

class IdleHint extends StatelessWidget {
  const IdleHint({super.key, required this.isAr});
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded, size: 64, color: cs.primary),
          const SizedBox(height: 16),
          Text(
            isAr ? 'ابحث عن مكان أو فعالية' : 'Search for a place or event',
            style: tt.titleMedium?.copyWith(color: cs.onTertiary),
          ),
        ],
      ),
    );
  }
}
