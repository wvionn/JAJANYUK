import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.orderId,
    required super.vendorId,
    super.customerId,
    super.buyerName,
    required super.paymentMethod,
    required super.paymentStatus,
    required super.totalAmount,
    required super.transactionDate,
    required super.createdAt,
    super.orderStatus,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final buyer = json['buyer'] as Map<String, dynamic>?;
    final orderObj = json['orders'] as Map<String, dynamic>?;
    final orderStatusVal = orderObj?['order_status'] as String? ?? json['order_status'] as String?;
    
    // Safety fallback: if order is completed, payment_status must be 'paid'
    var payStatus = json['payment_status'] as String? ?? 'pending';
    if (orderStatusVal == 'completed') {
      payStatus = 'paid';
    }

    return TransactionModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      vendorId: json['vendor_id'] as String,
      customerId: json['customer_id'] as String?,
      buyerName: buyer?['name'] as String? ?? buyer?['full_name'] as String?,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      paymentStatus: payStatus,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'] as String)
          : DateTime.parse(json['created_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      orderStatus: orderStatusVal,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'vendor_id': vendorId,
        'customer_id': customerId,
        'payment_method': paymentMethod,
        'payment_status': paymentStatus,
        'total_amount': totalAmount,
        'transaction_date': transactionDate.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
