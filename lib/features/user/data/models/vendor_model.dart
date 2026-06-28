import '../../domain/entities/vendor_entity.dart';

class VendorModel extends VendorEntity {
  const VendorModel({
    required super.id,
    super.campusId,
    required super.name,
    super.description,
    super.logoUrl,
    super.location,
    super.phone,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] as String,
      campusId: json['campus_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      location: json['location'] as String?,
      phone: json['phone'] as String?,
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
  };
}