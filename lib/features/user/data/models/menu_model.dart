import '../../domain/entities/menu_entity.dart';

class MenuModel extends MenuEntity {
  const MenuModel({
    required super.id,
    required super.vendorId,
    required super.name,
    super.description,
    required super.price,
    super.category,
    super.imageUrl,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final dbCategory = json['category'] as String?;
    
    String? uiCategory = dbCategory;
    final lowerName = name.toLowerCase();
    if (lowerName.contains('mie') || lowerName.contains('ramyeon') || lowerName.contains('japchae') || lowerName.contains('noodle')) {
      uiCategory = 'Mie Goreng';
    } else if (lowerName.contains('kopi') || lowerName.contains('teh') || lowerName.contains('jus') || lowerName.contains('boba') || lowerName.contains('shake') || lowerName.contains('latte') || lowerName.contains('americano') || dbCategory == 'Minuman') {
      uiCategory = 'Kopi';
    } else if (lowerName.contains('dimsum') || lowerName.contains('tteokbokki') || lowerName.contains('kimbap') || lowerName.contains('dog') || lowerName.contains('pisang') || lowerName.contains('cireng') || lowerName.contains('tahu') || lowerName.contains('kentang') || lowerName.contains('sosis') || lowerName.contains('risol') || dbCategory == 'Snack') {
      uiCategory = 'Dimsum';
    } else {
      uiCategory = 'Nasi Goreng';
    }

    return MenuModel(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      name: name,
      description: json['description'] as String?,
 
     price: (json['price'] as num).toDouble(),
      category: uiCategory,
      imageUrl: json['image_url'] as String?,
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
  };
}