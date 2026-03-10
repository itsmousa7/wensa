// lib/features/places/presentation/widgets/place_details/place_details_helpers.dart

/// Splits "HH:MM" (24h) into ("H:MM", "AM"|"PM").
/// e.g. "13:30" → ("1:30", "PM")
(String, String) splitAmPm(String hhmm) {
  try {
    final p = hhmm.split(':');
    int h = int.parse(p[0]);
    final m = int.parse(p[1]);
    final period = h >= 12 ? 'PM' : 'AM';
    if (h == 0) h = 12;
    else if (h > 12) h -= 12;
    return ('$h:${m.toString().padLeft(2, '0')}', period);
  } catch (_) {
    return (hhmm, '');
  }
}

/// Normalises an Instagram handle or URL to a full https URL.
/// "@handle" | "handle" → "https://www.instagram.com/handle/"
String instagramUrl(String raw) {
  final t = raw.trim();
  if (t.startsWith('http')) return t;
  return 'https://www.instagram.com/${t.startsWith('@') ? t.substring(1) : t}/';
}

/// Compact number: 1200 → "1.2K", 2500000 → "2.5M"
String compactNumber(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}