import '../../domain/entities/vendor_entity.dart';

class VendorModel extends VendorEntity {
  const VendorModel({
    required super.id,
    super.campusId,
    required super.name,
    super.description,
    super.logoUrl,
    required super.location,
    required super.phone,
    required super.openTime,
    required super.closeTime,
    required super.isOpen,
    super.estimatedProcessTime,
    required super.verificationStatus,
    required super.createdAt,
    super.updatedAt,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] as String,
      campusId: json['campus_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      location: json['location'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      openTime: json['open_time'] as String? ?? '08:00',
      closeTime: json['close_time'] as String? ?? '17:00',
      isOpen: json['is_open'] as bool? ?? true,
      estimatedProcessTime: json['estimated_process_time'] as String?,
      verificationStatus: json['verification_status'] as String? ?? 'Belum Terverifikasi',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'campus_id': campusId,
        'name': name,
        'description': description,
        'logo_url': logoUrl,
        'location': location,
        'phone': phone,
        'open_time': openTime,
        'close_time': closeTime,
        'is_open': isOpen,
        'estimated_process_time': estimatedProcessTime,
        'verification_status': verificationStatus,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
