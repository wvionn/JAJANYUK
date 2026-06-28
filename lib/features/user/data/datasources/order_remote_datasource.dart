import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../../domain/entities/cart_item_entity.dart';

class OrderRemoteDatasource {
  final SupabaseClient _client;

  OrderRemoteDatasource(this._client);

  Future<OrderModel> createOrder({
    required String vendorId,
    required List<CartItemEntity> items,
    String? note,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final totalPrice = items.fold(0.0, (sum, item) => sum + item.subtotal);

    // Buat order
    final orderResponse = await _client.from('orders').insert({
      'customer_id': userId,
      'vendor_id': vendorId,
      'total_price': totalPrice,
      'order_status': 'pending',
      'payment_status': 'unpaid',
      'note': note,
    }).select().single();

    final orderId = orderResponse['id'] as String;

    // Buat order items
    final orderItems = items.map((item) => {
      'order_id': orderId,
      'menu_id': item.menu.id,
      'quantity': item.quantity,
      'price': item.menu.price,
      'subtotal': item.subtotal,
    }).toList();

    await _client.from('order_items').insert(orderItems);

    return OrderModel.fromJson(orderResponse);
  }

  Future<List<OrderModel>> getMyOrders() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('orders')
        .select()
        .eq('customer_id', userId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => OrderModel.fromJson(e)).toList();
  }
}