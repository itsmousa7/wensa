import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.initials,
    this.radius = 20,
  });

  final String? avatarUrl;
  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: ClipOval(
        child: ColoredBox(
          color: cs.primary.withValues(alpha: 0.1),
          child: avatarUrl != null
              ? CachedNetworkImage(
                  imageUrl: avatarUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      _Initials(initials: initials, radius: radius),
                  errorWidget: (_, _, _) =>
                      _Initials(initials: initials, radius: radius),
                )
              : _Initials(initials: initials, radius: radius),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials, required this.radius});

  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w700,
          color: cs.primary,
        ),
      ),
    );
  }
}
