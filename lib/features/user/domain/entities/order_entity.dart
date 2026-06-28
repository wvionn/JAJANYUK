import 'package:equatable/equatable.dart';

class OrderEntity extends Equatable {
  final String id;
  final String customerId;
  final String vendorId;
  final double totalPrice;
  final String orderStatus;
  final String paymentStatus;
  final String? note;
  final DateTime createdAt;

  const OrderEntity({
    required this.id,
    required this.customerId,
    required this.vendorId,
    required this.totalPrice,
    required this.orderStatus,
    required this.paymentStatus,
    this.note,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, customerId, vendorId, totalPrice, orderStatus, paymentStatus, note, createdAt];
}