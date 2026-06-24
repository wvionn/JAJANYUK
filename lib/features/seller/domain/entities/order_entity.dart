import 'package:equatable/equatable.dart';

class OrderItemEntity extends Equatable {
  final String id;
  final String orderId;
  final String menuItemId;
  final String? menuItemName;
  final int quantity;
  final double price;

  const OrderItemEntity({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    this.menuItemName,
    required this.quantity,
    required this.price,
  });

  double get subtotal => price * quantity;

  @override
  List<Object?> get props =>
      [id, orderId, menuItemId, menuItemName, quantity, price];
}

class OrderEntity extends Equatable {
  final String id;
  final String userId;
  final String? buyerName;
  final String? buyerPhone;
  final String sellerId;
  final double totalPrice;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<OrderItemEntity> items;

  const OrderEntity({
    required this.id,
    required this.userId,
    this.buyerName,
    this.buyerPhone,
    required this.sellerId,
    required this.totalPrice,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    required this.items,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        buyerName,
        buyerPhone,
        sellerId,
        totalPrice,
        status,
        notes,
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
