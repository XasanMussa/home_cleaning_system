import 'package:json_annotation/json_annotation.dart';

part 'cleaning_package.g.dart';

@JsonSerializable()
class CleaningPackage {
  final int id;
  final String name;
  final String description;
  final double price;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  final List<String> services;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const CleaningPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.services,
    required this.createdAt,
    required this.updatedAt,
  });

  Duration get duration => Duration(minutes: durationMinutes);

  factory CleaningPackage.fromJson(Map<String, dynamic> json) =>
      _$CleaningPackageFromJson(json);

  Map<String, dynamic> toJson() => _$CleaningPackageToJson(this);
}
