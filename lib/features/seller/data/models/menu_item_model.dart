import '../../domain/entities/menu_item_entity.dart';

class MenuItemModel extends MenuItemEntity {
  const MenuItemModel({
    required super.id,
    required super.vendorId,
    required super.name,
    super.description,
    required super.price,
    required super.category,
    super.imageUrl,
    required super.stock,
    required super.estimatedTime,
    super.label,
    required super.isAvailable,
    required super.createdAt,
    super.updatedAt,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'Makanan',
      imageUrl: json['image_url'] as String?,
      stock: json['stock'] as int? ?? 0,
      estimatedTime: json['estimated_time'] as int? ?? 10,
      label: json['label'] as String?,
      isAvailable: json['is_available'] as bool? ?? json['available'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vendor_id': vendorId,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'image_url': imageUrl,
        'stock': stock,
        'estimated_time': estimatedTime,
        'label': label,
        'is_available': isAvailable,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}

