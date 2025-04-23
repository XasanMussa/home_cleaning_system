// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cleaning_package.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CleaningPackage _$CleaningPackageFromJson(Map<String, dynamic> json) =>
    CleaningPackage(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      services:
          (json['services'] as List<dynamic>).map((e) => e as String).toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$CleaningPackageToJson(CleaningPackage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'duration_minutes': instance.durationMinutes,
      'services': instance.services,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
