import 'package:equatable/equatable.dart';

class MenuItemEntity extends Equatable {
  final String id;
  final String vendorId;
  final String name;
  final String? description;
  final double price;
  final String category;
  final String? imageUrl;
  final int stock;
  final int estimatedTime;
  final String? label;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MenuItemEntity({
    required this.id,
    required this.vendorId,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    required this.stock,
    required this.estimatedTime,
    this.label,
    required this.isAvailable,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        vendorId,
        name,
        description,
        price,
        category,
        imageUrl,
        stock,
        estimatedTime,
        label,
        isAvailable,
        createdAt,
        updatedAt,
      ];
}

