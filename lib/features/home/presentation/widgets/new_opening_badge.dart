import 'package:flutter/material.dart';

Container newOpeningBadge(bool isAr, BuildContext context) {
  return feedBadge(
    isAr: isAr,
    context: context,
    color: Theme.of(context).colorScheme.primary,
    text: isAr ? 'افتتح مؤخراً' : 'Just Opened',
  );
}

Container feedBadge({
  required bool isAr,
  required BuildContext context,
  required Color color,
  required String text,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(999),
    ),
    alignment: Alignment.center,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        fontFamily: 'Ibm-Bold',
        height: 1.4,
      ),
    ),
  );
}
