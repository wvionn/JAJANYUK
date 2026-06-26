import 'package:equatable/equatable.dart';

class VendorEntity extends Equatable {
  final String id;
  final String? campusId;
  final String name;
  final String? description;
  final String? logoUrl;
  final String location;
  final String phone;
  final String openTime;
  final String closeTime;
  final bool isOpen;
  final String? estimatedProcessTime;
  final String verificationStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const VendorEntity({
    required this.id,
    this.campusId,
    required this.name,
    this.description,
    this.logoUrl,
    required this.location,
    required this.phone,
    required this.openTime,
    required this.closeTime,
    required this.isOpen,
    this.estimatedProcessTime,
    required this.verificationStatus,
    required this.createdAt,
    this.updatedAt,
  });

  VendorEntity copyWith({
    String? id,
    String? campusId,
    String? name,
    String? description,
    String? logoUrl,
    String? location,
    String? phone,
    String? openTime,
    String? closeTime,
    bool? isOpen,
    String? estimatedProcessTime,
    String? verificationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorEntity(
      id: id ?? this.id,
      campusId: campusId ?? this.campusId,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      isOpen: isOpen ?? this.isOpen,
      estimatedProcessTime: estimatedProcessTime ?? this.estimatedProcessTime,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        campusId,
        name,
        description,
        logoUrl,
        location,
        phone,
        openTime,
        closeTime,
        isOpen,
        estimatedProcessTime,
        verificationStatus,
        createdAt,
        updatedAt,
      ];
}
