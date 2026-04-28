import 'package:flutter/material.dart';

/// Displays a label that automatically switches between Arabic and English
/// based on the current locale.
///
/// Falls back to the other language if the preferred one is empty.
class BilingualLabel extends StatelessWidget {
  const BilingualLabel({
    super.key,
    required this.ar,
    required this.en,
    this.style,
    this.overflow,
    this.maxLines,
  });

  /// Arabic label text
  final String ar;

  /// English label text
  final String en;

  /// Text style to apply
  final TextStyle? style;

  /// How to handle overflow
  final TextOverflow? overflow;

  /// Maximum number of lines
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';
    final text = isArabic
        ? (ar.isNotEmpty ? ar : en)
        : (en.isNotEmpty ? en : ar);
    return Text(
      text,
      style: style,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
