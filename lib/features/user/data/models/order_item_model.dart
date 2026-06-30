import '../../domain/entities/order_item_entity.dart';

class OrderItemModel extends OrderItemEntity {
  const OrderItemModel({
    required super.name,
    required super.quantity,
    required super.price,
    required super.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final menu = json['menus'] as Map<String, dynamic>?;
    return OrderItemModel(
      name: menu?['name'] as String? ?? 'Menu Makanan',
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
