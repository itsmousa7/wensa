import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Bordered merchant logo badge.
///
/// Shows the merchant's logo retrieved from Supabase.
/// Falls back to a shop icon when [logoUrl] is null or fails to load.
/// Has a white ring border around it, rendered as a slightly-elevated pill.
class MerchantLogo extends StatelessWidget {
  const MerchantLogo({
    super.key,
    this.logoUrl,
    this.size = 46,
    this.borderWidth = 2.5,
  });

  final String? logoUrl;
  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + borderWidth * 2,
      height: size + borderWidth * 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(borderWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14 - borderWidth),
          child: logoUrl != null
              ? CachedNetworkImage(
                  imageUrl: logoUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => _fallback(context),
                  errorWidget: (_, _, _) => _fallback(context),
                )
              : _fallback(context),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.storefront_rounded,
        size: size * 0.52,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}
