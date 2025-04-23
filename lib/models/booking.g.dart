// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Booking _$BookingFromJson(Map<String, dynamic> json) => Booking(
      id: (json['id'] as num?)?.toInt(),
      customerId: json['customer_id'] as String,
      employeeId: json['employee_id'] as String?,
      packageId: (json['package_id'] as num).toInt(),
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      address: json['address'] as String,
      location: json['location'] as String?,
      description: json['description'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      paymentStatus: json['payment_status'] as String,
      paymentReference: json['payment_reference'] as String?,
      paymentAmount: (json['payment_amount'] as num?)?.toDouble(),
      paymentMethod: json['payment_method'] as String?,
      paymentPhoneNumber: json['payment_phone_number'] as String?,
    );

Map<String, dynamic> _$BookingToJson(Booking instance) => <String, dynamic>{
      'id': instance.id,
      'customer_id': instance.customerId,
      'employee_id': instance.employeeId,
      'package_id': instance.packageId,
      'scheduled_date': instance.scheduledDate.toIso8601String(),
      'address': instance.address,
      'location': instance.location,
      'description': instance.description,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'payment_status': instance.paymentStatus,
      'payment_reference': instance.paymentReference,
      'payment_amount': instance.paymentAmount,
      'payment_method': instance.paymentMethod,
      'payment_phone_number': instance.paymentPhoneNumber,
    };
