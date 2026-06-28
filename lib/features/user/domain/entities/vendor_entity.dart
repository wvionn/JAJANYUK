import 'package:equatable/equatable.dart';

class VendorEntity extends Equatable {
  final String id;
  final String? campusId;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? location;
  final String? phone;

  const VendorEntity({
    required this.id,
    this.campusId,
    required this.name,
    this.description,
    this.logoUrl,
    this.location,
    this.phone,
  });

  @override
  List<Object?> get props => [id, campusId, name, description, logoUrl, location, phone];
}