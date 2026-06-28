import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final String id;
  final String orderId;
  final String vendorId;
  final String? customerId;
  final String? buyerName;
  final String paymentMethod;
  final String paymentStatus;
  final double totalAmount;
  final DateTime transactionDate;
  final DateTime createdAt;
  final String? orderStatus; // for displaying in reports page

  const TransactionEntity({
    required this.id,
    required this.orderId,
    required this.vendorId,
    this.customerId,
    this.buyerName,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.totalAmount,
    required this.transactionDate,
    required this.createdAt,
    this.orderStatus,
  });

  @override
  List<Object?> get props => [
        id,
        orderId,
        vendorId,
        customerId,
        buyerName,
        paymentMethod,
        paymentStatus,
        totalAmount,
        transactionDate,
        createdAt,
        orderStatus,
      ];
}
