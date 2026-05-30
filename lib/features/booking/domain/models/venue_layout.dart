import 'package:freezed_annotation/freezed_annotation.dart';
import 'venue_section.dart';

part 'venue_layout.freezed.dart';
part 'venue_layout.g.dart';

/// Full venue layout for an event — the canvas, optional background image,
/// and all drawn sections. Returned by the `event_venue_layout` RPC.
@freezed
abstract class VenueLayout with _$VenueLayout {
  const factory VenueLayout({
    @Default('') String seatMapId,
    @Default(1200) double canvasWidth,
    @Default(800) double canvasHeight,
    String? backgroundImageUrl,
    @Default(<VenueSection>[]) List<VenueSection> sections,
  }) = _VenueLayout;

  factory VenueLayout.fromJson(Map<String, dynamic> json) =>
      _venueLayoutFromJson(json);
}

VenueLayout _venueLayoutFromJson(Map<String, dynamic> json) {
  final rawSections = (json['sections'] as List?) ?? const [];
  return VenueLayout(
    seatMapId: json['seat_map_id'] ?? '',
    canvasWidth: (json['canvas_width'] as num?)?.toDouble() ?? 1200,
    canvasHeight: (json['canvas_height'] as num?)?.toDouble() ?? 800,
    backgroundImageUrl: json['background_image_url'],
    sections: rawSections
        .map((e) => VenueSection.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
  );
}

extension VenueLayoutX on VenueLayout {
  bool get isEmpty => seatMapId.isEmpty || sections.isEmpty;
}
