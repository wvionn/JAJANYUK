import 'package:equatable/equatable.dart';

class OrderItemEntity extends Equatable {
  final String id;
  final String orderId;
  final String menuId;
  final String? menuItemName;
  final int quantity;
  final double price;
  final double subtotal;

  const OrderItemEntity({
    required this.id,
    required this.orderId,
    required this.menuId,
    this.menuItemName,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  @override
  List<Object?> get props =>
      [id, orderId, menuId, menuItemName, quantity, price, subtotal];
}

class OrderEntity extends Equatable {
  final String id;
  final String customerId;
  final String? buyerName;
  final String? buyerPhone;
  final String vendorId;
  final double totalPrice;
  final String orderStatus;
  final String paymentStatus;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<OrderItemEntity> items;

  const OrderEntity({
    required this.id,
    required this.customerId,
    this.buyerName,
    this.buyerPhone,
    required this.vendorId,
    required this.totalPrice,
    required this.orderStatus,
    required this.paymentStatus,
    this.note,
    required this.createdAt,
    this.updatedAt,
    required this.items,
  });

  @override
  List<Object?> get props => [
        id,
        customerId,
        buyerName,
        buyerPhone,
        vendorId,
        totalPrice,
        orderStatus,
        paymentStatus,
        note,
        createdAt,
        updatedAt,
        items,
      ];
}

class ChatMessageEntity extends Equatable {
  final String id;
  final String orderId;
  final String senderId;
  final String? senderName;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const ChatMessageEntity({
    required this.id,
    required this.orderId,
    required this.senderId,
    this.senderName,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, orderId, senderId, senderName, message, isRead, createdAt];
}

