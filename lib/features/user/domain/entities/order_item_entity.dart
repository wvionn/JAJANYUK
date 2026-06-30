import 'package:equatable/equatable.dart';

class OrderItemEntity extends Equatable {
  final String name;
  final int quantity;
  final double price;
  final double subtotal;

  const OrderItemEntity({
    required this.name,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  @override
  List<Object?> get props => [name, quantity, price, subtotal];
}
