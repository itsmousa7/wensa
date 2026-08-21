/// Mirrors the edge functions' merchantTransactionId formulas so the UI can
/// always show a transaction id — mandatory for support — even when the server
/// response doesn't echo one back (e.g. an edge function that hasn't been
/// redeployed yet). The authoritative id replaces this whenever the server
/// does return one.
///
///   create-booking     → `booking-{booking_id}` / `booking-venue-{group_id}`
///   create-membership  → `membership-{membership_id}`
///
/// All capped at 32 chars, matching the call sites' `.slice(0, 32)`.
///
/// [kind] is one of: booking | concert_group | membership.
String merchantTxnFallback({required String kind, required String id}) {
  final String value;
  switch (kind) {
    case 'concert_group':
      value = 'booking-venue-$id';
    case 'membership':
      value = 'membership-$id';
    default:
      value = 'booking-$id';
  }
  return value.length > 32 ? value.substring(0, 32) : value;
}
