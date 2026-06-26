import '../../domain/entities/seller_profile_entity.dart';

class SellerProfileModel extends SellerProfileEntity {
  const SellerProfileModel({
    required super.id,
    required super.userId,
    required super.vendorId,
    required super.sellerName,
    super.phone,
    required super.role,
    required super.createdAt,
    super.updatedAt,
  });

  factory SellerProfileModel.fromJson(Map<String, dynamic> json) {
    return SellerProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vendorId: json['vendor_id'] as String,
      sellerName: json['seller_name'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'seller',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'vendor_id': vendorId,
        'seller_name': sellerName,
        'phone': phone,
        'role': role,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
