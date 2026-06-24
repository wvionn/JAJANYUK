import '../../domain/entities/menu_item_entity.dart';

class MenuItemModel extends MenuItemEntity {
  const MenuItemModel({
    required super.id,
    required super.sellerId,
    required super.name,
    super.description,
    required super.price,
    super.category,
    super.imageUrl,
    required super.available,
    required super.createdAt,
    super.updatedAt,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String?,
      imageUrl: json['image_url'] as String?,
      available: json['available'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'seller_id': sellerId,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'image_url': imageUrl,
        'available': available,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
