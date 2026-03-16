import 'package:flutter/material.dart';

class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, required this.query, required this.isAr});
  final String query;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: cs.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              isAr ? 'لا توجد نتائج لـ "$query"' : 'No results for "$query"',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
