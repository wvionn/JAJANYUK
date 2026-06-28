import '../../domain/entities/order_entity.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.customerId,
    required super.vendorId,
    required super.totalPrice,
    required super.orderStatus,
    required super.paymentStatus,
    super.note,
    required super.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      vendorId: json['vendor_id'] as String,
      totalPrice: (json['total_price'] as num).toDouble(),
      orderStatus: json['order_status'] as String,
      paymentStatus: json['payment_status'] as String,
      note: json['note'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'vendor_id': vendorId,
    'total_price': totalPrice,
    'order_status': orderStatus,
    'payment_status': paymentStatus,
    'note': note,
    'created_at': createdAt.toIso8601String(),
  };
}