// ─────────────────────────────────────────────────────────────────────────────
//  Profile header — gradient band + avatar + name + email
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:future_riverpod/features/profile/presentation/widgets/profile_avatar.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.user, required this.isAr});

  final dynamic user;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          children: [
            // Avatar
            ProfileAvatar(user: user),
            const SizedBox(height: 14),

            // Full name
            Text(
              user.fullName,
              style: tt.titleMedium?.copyWith(
                color: cs.outline,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Email
            Text(
              user.email,
              style: tt.bodySmall?.copyWith(
                color: cs.outline,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),

            // City (optional)
            if (user.city != null && user.city!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    user.city!,
                    style: tt.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
