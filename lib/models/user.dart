import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String email;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  final String role; // admin, employee, customer
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => [firstName, lastName]
      .where((name) => name != null && name.isNotEmpty)
      .join(' ');

  bool get isAdmin => role == 'admin';
  bool get isEmployee => role == 'employee';
  bool get isCustomer => role == 'customer';

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
