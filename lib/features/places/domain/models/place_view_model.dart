import 'package:freezed_annotation/freezed_annotation.dart';

part 'place_view_model.freezed.dart';
part 'place_view_model.g.dart';

@freezed
abstract class PlaceViewModel with _$PlaceViewModel {
  const factory PlaceViewModel({
    @Default('') String id,
    @Default('') String placeId,
    @Default('') String userId,
    String? viewedAt,
  }) = _PlaceViewModel;

  factory PlaceViewModel.fromJson(Map<String, dynamic> json) => PlaceViewModel(
    id: json['id'] ?? '',
    placeId: json['place_id'] ?? '',
    userId: json['user_id'] ?? '',
    viewedAt: json['viewed_at'],
  );
}