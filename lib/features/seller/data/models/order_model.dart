import '../../domain/entities/order_entity.dart';

class OrderItemModel extends OrderItemEntity {
  const OrderItemModel({
    required super.id,
    required super.orderId,
    required super.menuId,
    super.menuItemName,
    required super.quantity,
    required super.price,
    required super.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final menu = json['menus'] as Map<String, dynamic>? ?? json['menu_items'] as Map<String, dynamic>?;
    final priceVal = (json['price'] as num?)?.toDouble() ?? 0.0;
    final qty = json['quantity'] as int? ?? 1;
    return OrderItemModel(
      id: json['id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      menuId: json['menu_id'] as String? ?? json['menu_item_id'] as String? ?? '',
      menuItemName: menu?['name'] as String? ?? json['menu_item_name'] as String? ?? '',
      quantity: qty,
      price: priceVal,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? (priceVal * qty),
    );
  }
}

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.customerId,
    super.buyerName,
    super.buyerPhone,
    required super.vendorId,
    required super.totalPrice,
    required super.orderStatus,
    required super.paymentStatus,
    super.note,
    required super.createdAt,
    super.updatedAt,
    required super.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final buyer = json['buyer'] as Map<String, dynamic>?;
    final rawItems = json['order_items'] as List<dynamic>? ?? [];

    return OrderModel(
      id: json['id'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? json['user_id'] as String? ?? json['buyer_id'] as String? ?? '',
      buyerName: buyer?['name'] as String? ?? buyer?['full_name'] as String?,
      buyerPhone: buyer?['phone'] as String? ?? buyer?['phone_number'] as String?,
      vendorId: json['vendor_id'] as String? ?? json['seller_id'] as String? ?? '',
      totalPrice: (json['total_price'] as num?)?.toDouble() ??
          (json['total_amount'] as num?)?.toDouble() ??
          0.0,
      orderStatus: json['order_status'] as String? ?? json['status'] as String? ?? 'pending',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      note: json['note'] as String? ?? json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
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

