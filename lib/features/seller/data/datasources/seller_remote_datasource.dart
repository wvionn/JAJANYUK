import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';

abstract class SellerRemoteDataSource {
  Future<List<MenuItemModel>> getMenuItems(String sellerId);
  Future<MenuItemModel> addMenuItem({
    required String sellerId,
    required String name,
    String? description,
    required double price,
    String? category,
    bool available,
  });
  Future<MenuItemModel> updateMenuItem({
    required String menuItemId,
    String? name,
    String? description,
    double? price,
    String? category,
    bool? available,
  });
  Future<void> deleteMenuItem(String menuItemId);

  Future<List<OrderModel>> getOrders(String sellerId);
  Future<void> updateOrderStatus(
      {required String orderId, required String status});

  Future<List<ChatMessageModel>> getChatMessages(String orderId);
  Future<ChatMessageModel> sendMessage({
    required String orderId,
    required String senderId,
    required String message,
  });
  Stream<List<ChatMessageModel>> watchChatMessages(String orderId);
  Stream<List<OrderModel>> watchOrders(String sellerId);
}

class SellerRemoteDataSourceImpl implements SellerRemoteDataSource {
  final SupabaseClient supabaseClient;

  SellerRemoteDataSourceImpl({required this.supabaseClient});

  // ── Menu ──

  @override
  Future<List<MenuItemModel>> getMenuItems(String sellerId) async {
    try {
      final res = await supabaseClient
          .from('menu_items')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);
      return (res as List).map((j) => MenuItemModel.fromJson(j)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<MenuItemModel> addMenuItem({
    required String sellerId,
    required String name,
    String? description,
    required double price,
    String? category,
    bool available = true,
  }) async {
    try {
      final data = {
        'seller_id': sellerId,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'available': available,
        'created_at': DateTime.now().toIso8601String(),
      };
      final res = await supabaseClient
          .from('menu_items')
          .insert(data)
          .select()
          .single();
      return MenuItemModel.fromJson(res);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<MenuItemModel> updateMenuItem({
    required String menuItemId,
    String? name,
    String? description,
    double? price,
    String? category,
    bool? available,
  }) async {
    try {
      final data = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price;
      if (category != null) data['category'] = category;
      if (available != null) data['available'] = available;

      final res = await supabaseClient
          .from('menu_items')
          .update(data)
          .eq('id', menuItemId)
          .select()
          .single();
      return MenuItemModel.fromJson(res);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteMenuItem(String menuItemId) async {
    try {
      await supabaseClient.from('menu_items').delete().eq('id', menuItemId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ── Orders ──

  @override
  Future<List<OrderModel>> getOrders(String sellerId) async {
    try {
      final res = await supabaseClient.from('orders').select('''
            *,
            buyer:users!orders_user_id_fkey(name, full_name, phone, phone_number),
            order_items(id, menu_item_id, quantity, price, menu_items(name))
          ''').eq('seller_id', sellerId).order('created_at', ascending: false);
      return (res as List).map((j) => OrderModel.fromJson(j)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      await supabaseClient.from('orders').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ── Chat ──

  @override
  Future<List<ChatMessageModel>> getChatMessages(String orderId) async {
    try {
      final res = await supabaseClient
          .from('chat_messages')
          .select(
              '*, sender:users!chat_messages_sender_id_fkey(name, full_name)')
          .eq('order_id', orderId)
          .order('created_at');
      return (res as List).map((j) => ChatMessageModel.fromJson(j)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ChatMessageModel> sendMessage({
    required String orderId,
    required String senderId,
    required String message,
  }) async {
    try {
      final data = {
        'order_id': orderId,
        'sender_id': senderId,
        'message': message,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };
      final res = await supabaseClient
          .from('chat_messages')
          .insert(data)
          .select()
          .single();
      return ChatMessageModel.fromJson(res);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<List<ChatMessageModel>> watchChatMessages(String orderId) {
    return supabaseClient
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .order('created_at')
        .map((list) => list.map((j) => ChatMessageModel.fromJson(j)).toList());
  }

  @override
  Stream<List<OrderModel>> watchOrders(String sellerId) {
    return supabaseClient
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false)
        .map((list) => list.map((j) => OrderModel.fromJson(j)).toList());
  }
}
