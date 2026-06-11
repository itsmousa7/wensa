// lib/core/share/share_link.dart
//
// Centralized share URLs + captions. The base URL is a placeholder until a
// real domain + deep linking is set up — change kShareBaseUrl in one place.

/// Base URL for shareable links. Placeholder until a real domain is purchased
/// and universal/app links are configured.
const String kShareBaseUrl = 'https://wensa.app';

String placeShareUrl(String id) => '$kShareBaseUrl/placeDetails?placeId=$id';

String eventShareUrl(String id) => '$kShareBaseUrl/eventDetails?eventId=$id';

String placeShareCaption({
  required String name,
  required String id,
  required bool isAr,
}) => isAr
    ? 'شِف $name على ونسة!\n${placeShareUrl(id)}'
    : 'Check out $name on Wensa!\n${placeShareUrl(id)}';

String eventShareCaption({
  required String name,
  required String id,
  required bool isAr,
}) => isAr
    ? 'شِف $name على ونسة!\n${eventShareUrl(id)}'
    : 'Check out $name on Wensa!\n${eventShareUrl(id)}';

String ticketShareCaption({required String name, required bool isAr}) => isAr
    ? 'تذكرتي إلى $name عبر ونسة 🎟️'
    : 'My ticket to $name via Wensa 🎟️';
