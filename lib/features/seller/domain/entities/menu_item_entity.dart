import 'package:equatable/equatable.dart';

class MenuItemEntity extends Equatable {
  final String id;
  final String sellerId;
  final String name;
  final String? description;
  final double price;
  final String? category;
  final String? imageUrl;
  final bool available;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MenuItemEntity({
    required this.id,
    required this.sellerId,
    required this.name,
    this.description,
    required this.price,
    this.category,
    this.imageUrl,
    required this.available,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        sellerId,
        name,
        description,
        price,
        category,
        imageUrl,
        available,
        createdAt,
        updatedAt,
      ];
}
