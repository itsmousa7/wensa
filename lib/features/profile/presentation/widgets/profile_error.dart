import 'package:flutter/material.dart';

class ProfileError extends StatelessWidget {
  const ProfileError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: cs.error, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: cs.error, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
