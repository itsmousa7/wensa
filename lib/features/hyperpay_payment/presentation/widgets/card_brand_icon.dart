import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Visa/Mastercard mark for a card, with a generic credit-card glyph as the
/// fallback while the brand is unknown.
///
/// The Mastercard SVG has a square 58×58 viewBox with the card artwork
/// occupying only 58×40 of it — inside a wide `width × width*2/3` box it
/// renders visibly smaller than the wide-viewBox Visa wordmark. A square box
/// lets its artwork fill the full width like Visa does.
class CardBrandIcon extends StatelessWidget {
  const CardBrandIcon({
    super.key,
    required this.brand,
    this.width = 36,
    this.placeholderSize = 28,
    this.mutedPlaceholder = false,
  });

  final String? brand;

  /// Width of the brand mark box (the Mastercard box is squared off it).
  final double width;

  /// Size of the generic glyph shown when [brand] is null.
  final double placeholderSize;

  /// Renders the null-brand glyph in the hint color (onSurface @ 40%) so it
  /// reads as part of a field's placeholder state rather than as content.
  final bool mutedPlaceholder;

  @override
  Widget build(BuildContext context) {
    final asset = switch (brand) {
      'VISA' => 'assets/icons/visa.svg',
      'MASTER' => 'assets/icons/mastercard.svg',
      _ => null,
    };
    if (asset == null) {
      return Icon(
        Icons.credit_card,
        size: mutedPlaceholder ? null : placeholderSize,
        color: mutedPlaceholder
            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
            : null,
      );
    }
    return SizedBox(
      width: width,
      height: brand == 'MASTER' ? width : width * 2 / 3,
      child: SvgPicture.asset(asset, fit: BoxFit.contain),
    );
  }
}
