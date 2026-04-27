import 'package:flutter/material.dart';

/// Blue checkmark shown next to Pro merchant names on place/event cards and profiles.
/// Size: 14dp inline. Color: primary brand blue.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 14.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified,
      size: size,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}
