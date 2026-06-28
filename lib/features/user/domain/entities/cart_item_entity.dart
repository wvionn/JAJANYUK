import 'package:equatable/equatable.dart';
import 'menu_entity.dart';

class CartItemEntity extends Equatable {
  final MenuEntity menu;
  final int quantity;

  const CartItemEntity({
    required this.menu,
    required this.quantity,
  });

  double get subtotal => menu.price * quantity;

  @override
  List<Object?> get props => [menu, quantity];
}