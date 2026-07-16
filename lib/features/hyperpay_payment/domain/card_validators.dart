/// Pure validation helpers for the HyperPay custom card form.
/// Brand support is intentionally VISA/MASTER only (Wensa scope).
library;

/// Detects the card brand from the leading digits.
/// VISA starts with 4; Mastercard with 51–55 or 2221–2720.
String? detectBrand(String digits) {
  if (digits.isEmpty) return null;
  if (digits.startsWith('4')) return 'VISA';
  final two = digits.length >= 2 ? int.tryParse(digits.substring(0, 2)) : null;
  if (two != null && two >= 51 && two <= 55) return 'MASTER';
  final four = digits.length >= 4 ? int.tryParse(digits.substring(0, 4)) : null;
  if (four != null && four >= 2221 && four <= 2720) return 'MASTER';
  return null;
}

bool luhnCheck(String digits) {
  if (digits.length < 12 || !RegExp(r'^\d+$').hasMatch(digits)) return false;
  var sum = 0;
  var alternate = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var n = int.parse(digits[i]);
    if (alternate) {
      n *= 2;
      if (n > 9) n = (n % 10) + 1;
    }
    sum += n;
    alternate = !alternate;
  }
  return sum % 10 == 0;
}

bool isValidExpiry(String mm, String yy) {
  final month = int.tryParse(mm);
  final year = int.tryParse(normalizeYear(yy));
  if (month == null || year == null || month < 1 || month > 12) return false;
  final now = DateTime.now();
  if (year < now.year) return false;
  if (year == now.year && month < now.month) return false;
  return true;
}

String normalizeYear(String yy) => yy.length == 2 ? '20$yy' : yy;

bool isValidCvv(String cvv) => RegExp(r'^\d{3}$').hasMatch(cvv);

/// Requires a first and last name (e.g. "John Doe") totalling at least 3
/// characters.
bool isValidHolderName(String name) {
  final trimmed = name.trim();
  if (trimmed.length < 3) return false;
  final parts = trimmed.split(RegExp(r'\s+'));
  return parts.length >= 2 && parts.every((part) => part.isNotEmpty);
}
