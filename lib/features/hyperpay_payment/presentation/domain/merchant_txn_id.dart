/// Mirrors create-booking's merchantTransactionId formula
/// (`booking-{id}` / `booking-venue-{groupId}`, capped at 32 chars) so the UI
/// can always show a transaction id — mandatory for support — even when the
/// server response doesn't echo one back (e.g. an edge function that hasn't
/// been redeployed yet). The authoritative id replaces this whenever the
/// server does return one.
///
/// [kind] is one of: booking | concert_group | membership.
String merchantTxnFallback({required String kind, required String id}) {
  final value = kind == 'concert_group' ? 'booking-venue-$id' : 'booking-$id';
  return value.length > 32 ? value.substring(0, 32) : value;
}
