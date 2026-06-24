import '../../domain/entities/order_entity.dart';

class OrderItemModel extends OrderItemEntity {
  const OrderItemModel({
    required super.id,
    required super.orderId,
    required super.menuItemId,
    super.menuItemName,
    required super.quantity,
    required super.price,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final menuItem = json['menu_items'] as Map<String, dynamic>?;
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      menuItemId: json['menu_item_id'] as String,
      menuItemName:
          menuItem?['name'] as String? ?? json['menu_item_name'] as String?,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }
}

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.userId,
    super.buyerName,
    super.buyerPhone,
    required super.sellerId,
    required super.totalPrice,
    required super.status,
    super.notes,
    required super.createdAt,
    super.updatedAt,
    required super.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final buyer = json['buyer'] as Map<String, dynamic>?;
    final rawItems = json['order_items'] as List<dynamic>? ?? [];

    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      buyerName: buyer?['name'] as String? ?? buyer?['full_name'] as String?,
      buyerPhone:
          buyer?['phone'] as String? ?? buyer?['phone_number'] as String?,
      sellerId: json['seller_id'] as String,
      totalPrice: (json['total_price'] as num?)?.toDouble() ??
          (json['total_amount'] as num?)?.toDouble() ??
          0.0,
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      items: rawItems
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.orderId,
    required super.senderId,
    super.senderName,
    required super.message,
    required super.isRead,
    required super.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    return ChatMessageModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: sender?['name'] as String? ?? sender?['full_name'] as String?,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'order_id': orderId,
        'sender_id': senderId,
        'message': message,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };
}
