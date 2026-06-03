// lib/features/notifications/domain/models/app_notification.dart

enum NotificationKind {
  hourly,
  concert,
  membership,
  broadcastGeneral,
  broadcastNewEvent,
  broadcastNewPlace,
  broadcastPromo,
  unknown;

  static NotificationKind fromString(String raw) => switch (raw) {
        'hourly' => NotificationKind.hourly,
        'concert' => NotificationKind.concert,
        'membership' => NotificationKind.membership,
        'broadcast_general' => NotificationKind.broadcastGeneral,
        'broadcast_new_event' => NotificationKind.broadcastNewEvent,
        'broadcast_new_place' => NotificationKind.broadcastNewPlace,
        'broadcast_promo' => NotificationKind.broadcastPromo,
        _ => NotificationKind.unknown,
      };

  bool get isReminder =>
      this == NotificationKind.hourly ||
      this == NotificationKind.concert ||
      this == NotificationKind.membership;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
    required this.data,
    required this.readAt,
    required this.createdAt,
  });

  final String id;
  final NotificationKind kind;
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  String? get bookingId => data['booking_id'] as String?;
  String? get membershipId => data['membership_id'] as String?;

  /// Resolve the in-app navigation target for this notification, if any.
  /// Booking reminders open the ticket directly; membership reminders open
  /// the membership ticket (which the ticket detail page accepts via the
  /// `m_` prefix). Broadcasts have no target — tapping just dismisses.
  String? get tapRoute {
    switch (kind) {
      case NotificationKind.hourly:
      case NotificationKind.concert:
        final id = bookingId;
        return (id != null && id.isNotEmpty) ? '/bookings/$id' : null;
      case NotificationKind.membership:
        final id = membershipId;
        return (id != null && id.isNotEmpty) ? '/bookings/m_$id' : null;
      case NotificationKind.broadcastGeneral:
      case NotificationKind.broadcastNewEvent:
      case NotificationKind.broadcastNewPlace:
      case NotificationKind.broadcastPromo:
      case NotificationKind.unknown:
        return null;
    }
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      kind: NotificationKind.fromString(json['kind'] as String? ?? ''),
      titleEn: json['title_en'] as String? ?? '',
      titleAr: json['title_ar'] as String? ?? '',
      bodyEn: json['body_en'] as String? ?? '',
      bodyAr: json['body_ar'] as String? ?? '',
      data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String).toLocal(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}
