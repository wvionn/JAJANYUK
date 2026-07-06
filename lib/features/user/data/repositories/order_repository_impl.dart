import '../../domain/entities/cart_item_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_item_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDatasource _datasource;

  OrderRepositoryImpl(this._datasource);

  @override
  Future<OrderEntity> createOrder({
    required String vendorId,
    required List<CartItemEntity> items,
    String? note,
  }) async {
    return await _datasource.createOrder(
      vendorId: vendorId,
      items: items,
      note: note,
    );
  }

  @override
  Future<List<OrderEntity>> getMyOrders() async {
    return await _datasource.getMyOrders();
  }

  @override
  Future<List<OrderItemEntity>> getOrderItems(String orderId) async {
    return await _datasource.getOrderItems(orderId);
  }

  @override
  Future<void> updateOrderNote({required String orderId, required String newNote}) async {
    await _datasource.updateOrderNote(orderId: orderId, newNote: newNote);
  }
}