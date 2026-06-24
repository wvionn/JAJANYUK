import 'package:equatable/equatable.dart';

class CampusEntity extends Equatable {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CampusEntity({
    required this.id,
    required this.name,
    this.address,
    this.city,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props =>
      [id, name, address, city, isActive, createdAt, updatedAt];
}
