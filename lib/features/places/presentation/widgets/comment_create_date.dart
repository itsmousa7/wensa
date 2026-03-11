import 'package:flutter/material.dart';

class TimeAgo extends StatelessWidget {
  const TimeAgo({super.key, required this.iso, this.isAr = false});
  final String? iso;
  final bool isAr;

  String _format() {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso!).toUtc();
      final diff = DateTime.now().toUtc().difference(dt).abs();

      if (isAr) {
        if (diff.inSeconds < 60) return 'منذ ${diff.inSeconds}ث';
        if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes}د';
        if (diff.inHours < 24) return 'منذ ${diff.inHours}س';
        if (diff.inDays < 7) return 'منذ ${diff.inDays}ي';
        if (diff.inDays < 30) return 'منذ ${(diff.inDays / 7).floor()}أ';
        if (diff.inDays < 365) return 'منذ ${(diff.inDays / 30).floor()}ش';
        return 'منذ ${(diff.inDays / 365).floor()}سن';
      }

      if (diff.inSeconds < 60) return '${diff.inSeconds}s';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
      if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo';
      return '${(diff.inDays / 365).floor()}y';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Text(
      _format(),
      style: tt.labelMedium?.copyWith(
        color: cs.outline.withValues(alpha: 0.45),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
