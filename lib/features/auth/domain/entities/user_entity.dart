import 'package:equatable/equatable.dart';
import '../../../../core/constants/enums.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final UserRole role;
  final String? campusId;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    required this.role,
    this.campusId,
    this.profileImageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    phoneNumber,
    role,
    campusId,
    profileImageUrl,
    createdAt,
    updatedAt,
  ];
}
