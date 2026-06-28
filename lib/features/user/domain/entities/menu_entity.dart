import 'package:equatable/equatable.dart';

class MenuEntity extends Equatable {
  final String id;
  final String vendorId;
  final String name;
  final String? description;
  final double price;
  final String? category;
  final String? imageUrl;

  const MenuEntity({
    required this.id,
    required this.vendorId,
    required this.name,
    this.description,
    required this.price,
    this.category,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, vendorId, name, description, price, category, imageUrl];
}