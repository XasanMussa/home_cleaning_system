import 'package:json_annotation/json_annotation.dart';
import 'package:hcs_booking_system/models/user.dart';
import 'package:hcs_booking_system/models/cleaning_package.dart';

part 'booking.g.dart';

enum BookingStatus { pending, confirmed, inProgress, completed, cancelled }

enum PaymentStatus { pending, completed, failed }

@JsonSerializable()
class Booking {
  final int? id;
  @JsonKey(name: 'customer_id')
  final String customerId;
  @JsonKey(name: 'employee_id')
  final String? employeeId;
  @JsonKey(name: 'package_id')
  final int packageId;
  @JsonKey(name: 'scheduled_date')
  final DateTime scheduledDate;
  final String address;
  final String? location;
  final String? description;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'payment_status')
  final String paymentStatus;
  @JsonKey(name: 'payment_reference')
  final String? paymentReference;
  @JsonKey(name: 'payment_amount')
  final double? paymentAmount;
  @JsonKey(name: 'payment_method')
  final String? paymentMethod;
  @JsonKey(name: 'payment_phone_number')
  final String? paymentPhoneNumber;

  @JsonKey(ignore: true)
  User? customer;

  @JsonKey(ignore: true)
  User? employee;

  @JsonKey(ignore: true)
  CleaningPackage? package;

  Booking({
    this.id,
    required this.customerId,
    this.employeeId,
    required this.packageId,
    required this.scheduledDate,
    required this.address,
    this.location,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.paymentStatus,
    this.paymentReference,
    this.paymentAmount,
    this.paymentMethod,
    this.paymentPhoneNumber,
  });

  BookingStatus get bookingStatus => BookingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == status,
        orElse: () => BookingStatus.pending,
      );

  PaymentStatus get paymentStatusEnum => PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == paymentStatus,
        orElse: () => PaymentStatus.pending,
      );

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);

  Map<String, dynamic> toJson() => _$BookingToJson(this);
}
