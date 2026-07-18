/// A saved HyperPay card token (bookings.user_payment_tokens row).
/// The OPPWA registration id itself never reaches the client beyond this
/// opaque row id — charges go through the charge-saved-card edge function.
class SavedCard {
  const SavedCard({
    required this.id,
    this.brand,
    this.last4,
    this.expMonth,
    this.expYear,
  });

  final String id;
  final String? brand; // VISA / MASTER
  final String? last4;
  final String? expMonth;
  final String? expYear;

  factory SavedCard.fromJson(Map<String, dynamic> json) => SavedCard(
    id: json['id'] as String,
    brand: json['brand'] as String?,
    last4: json['last4'] as String?,
    expMonth: json['exp_month'] as String?,
    expYear: json['exp_year'] as String?,
  );

  /// "Visa •••• 4242" style label.
  String get displayName {
    final b = switch (brand) {
      'VISA' => 'Visa',
      'MASTER' => 'Mastercard',
      _ => brand ?? 'Card',
    };
    return last4 == null ? b : '$b •••• $last4';
  }

  /// "12/27" or null when expiry is unknown.
  String? get expiryLabel {
    if (expMonth == null || expYear == null) return null;
    final year = expYear!.length == 4 ? expYear!.substring(2) : expYear!;
    return '${expMonth!.padLeft(2, '0')}/$year';
  }
}
