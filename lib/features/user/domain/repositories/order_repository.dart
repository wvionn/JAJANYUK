import '../entities/cart_item_entity.dart';
import '../entities/order_entity.dart';

abstract class OrderRepository {
  Future<OrderEntity> createOrder({
    required String vendorId,
    required List<CartItemEntity> items,
    String? note,
  });
  Future<List<OrderEntity>> getMyOrders();
}