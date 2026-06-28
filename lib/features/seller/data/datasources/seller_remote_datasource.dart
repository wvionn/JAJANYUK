import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../models/vendor_model.dart';
import '../models/seller_profile_model.dart';
import '../models/transaction_model.dart';

abstract class SellerRemoteDataSource {
  // ── Menu ──
  Future<List<MenuItemModel>> getMenuItems(String vendorId);
  Future<MenuItemModel> addMenuItem({
    required String vendorId,
    required String name,
    String? description,
    required double price,
    required String category,
    required int stock,
    required int estimatedTime,
    String? label,
    bool isAvailable,
  });
  Future<MenuItemModel> updateMenuItem({
    required String menuItemId,
    String? name,
    String? description,
    double? price,
    String? category,
    int? stock,
    int? estimatedTime,
    String? label,
    bool? isAvailable,
  });
  Future<void> deleteMenuItem(String menuItemId);

  // ── Orders ──
  Future<List<OrderModel>> getOrders(String vendorId);
  Future<void> updateOrderStatus(
      {required String orderId, required String status});
  Stream<List<OrderModel>> watchOrders(String vendorId);

  // ── Chat ──
  Future<List<ChatMessageModel>> getChatMessages(String orderId);
  Future<ChatMessageModel> sendMessage({
    required String orderId,
    required String senderId,
    required String message,
  });
  Stream<List<ChatMessageModel>> watchChatMessages(String orderId);

  // ── Vendor & Seller Profile ──
  Future<SellerProfileModel> getSellerProfile(String userId);
  Future<VendorModel> getVendorProfile(String vendorId);
  Future<VendorModel> updateVendorProfile(VendorModel vendor);

  // ── Transaction Reports ──
  Future<List<TransactionModel>> getTransactionReports({
    required String vendorId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  });
}

class SellerRemoteDataSourceImpl implements SellerRemoteDataSource {
  final SupabaseClient supabaseClient;

  SellerRemoteDataSourceImpl({required this.supabaseClient});

  // ── Menu ──

  @override
  Future<List<MenuItemModel>> getMenuItems(String vendorId) async {
    try {
      final res = await supabaseClient
          .from('menus')
          .select()
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false);
      return (res as List).map((j) => MenuItemModel.fromJson(j)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<MenuItemModel> addMenuItem({
    required String vendorId,
    required String name,
    String? description,
    required double price,
    required String category,
    required int stock,
    required int estimatedTime,
    String? label,
    bool isAvailable = true,
  }) async {
    try {
      final data = {
        'vendor_id': vendorId,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'stock': stock,
        'estimated_time': estimatedTime,
        'label': label,
        'is_available': isAvailable,
        'created_at': DateTime.now().toIso8601String(),
      };
      final res = await supabaseClient
          .from('menus')
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
    int? stock,
    int? estimatedTime,
    String? label,
    bool? isAvailable,
  }) async {
    try {
      final data = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price;
      if (category != null) data['category'] = category;
      if (stock != null) data['stock'] = stock;
      if (estimatedTime != null) data['estimated_time'] = estimatedTime;
      if (label != null) data['label'] = label;
      if (isAvailable != null) data['is_available'] = isAvailable;

      final res = await supabaseClient
          .from('menus')
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
      await supabaseClient.from('menus').delete().eq('id', menuItemId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ── Orders ──

  @override
  Future<List<OrderModel>> getOrders(String vendorId) async {
    try {
      final res = await supabaseClient.from('orders').select('''
            *,
            buyer:users!orders_customer_id_fkey(name, full_name, phone, phone_number),
            order_items(id, order_id, menu_id, quantity, price, subtotal, menus(name))
          ''').eq('vendor_id', vendorId).order('created_at', ascending: false);
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
      // If setting to completed, we should also log the transaction if not already logged!
      // To ensure that transaction reporting works seamlessly, when updating order status to 'completed',
      // we'll make sure there is a record in the transactions table.
      await supabaseClient.from('orders').update({
        'order_status': status,
        'payment_status': status == 'completed' ? 'paid' : 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      if (status == 'completed' || status == 'cancelled') {
        try {
          // Fetch order details first
          final orderRes = await supabaseClient
              .from('orders')
              .select('customer_id, vendor_id, total_price, payment_method')
              .eq('id', orderId)
              .single();
          
          final customerId = orderRes['customer_id'] as String?;
          final vendorId = orderRes['vendor_id'] as String?;
          final totalPrice = (orderRes['total_price'] as num?)?.toDouble() ?? 0.0;
          final payMethod = orderRes['payment_method'] as String? ?? 'cash';

          // Insert into transactions
          await supabaseClient.from('transactions').insert({
            'order_id': orderId,
            'vendor_id': vendorId,
            'customer_id': customerId,
            'payment_method': payMethod,
            'payment_status': status == 'completed' ? 'paid' : 'failed',
            'total_amount': totalPrice,
            'transaction_date': DateTime.now().toIso8601String(),
          });
        } catch (txErr) {
          // transaction record might already exist or trigger handles it, ignore
        }
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<List<OrderModel>> watchOrders(String vendorId) {
    return supabaseClient
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('vendor_id', vendorId)
        .order('created_at', ascending: false)
        .map((list) => list.map((j) => OrderModel.fromJson(j)).toList());
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

  // ── Vendor & Seller Profile ──

  @override
  Future<SellerProfileModel> getSellerProfile(String userId) async {
    try {
      final res = await supabaseClient
          .from('seller_profiles')
          .select()
          .eq('user_id', userId)
          .single();
      return SellerProfileModel.fromJson(res);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<VendorModel> getVendorProfile(String vendorId) async {
    try {
      final res = await supabaseClient
          .from('vendors')
          .select()
          .eq('id', vendorId)
          .single();
      return VendorModel.fromJson(res);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<VendorModel> updateVendorProfile(VendorModel vendor) async {
    try {
      final data = vendor.toJson();
      data.remove('created_at'); // don't overwrite created_at
      data['updated_at'] = DateTime.now().toIso8601String();
      
      final res = await supabaseClient
          .from('vendors')
          .update(data)
          .eq('id', vendor.id)
          .select()
          .single();
      return VendorModel.fromJson(res);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ── Transaction Reports ──

  @override
  Future<List<TransactionModel>> getTransactionReports({
    required String vendorId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      var query = supabaseClient.from('transactions').select('''
            *,
            buyer:users!transactions_customer_id_fkey(name, full_name),
            orders!transactions_order_id_fkey(order_status)
          ''').eq('vendor_id', vendorId);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        // Include the entire end day
        final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        query = query.lte('created_at', endOfDay.toIso8601String());
      }
      if (status != null && status != 'all') {
        query = query.eq('payment_status', status);
      }

      final res = await query.order('created_at', ascending: false);
      return (res as List).map((j) => TransactionModel.fromJson(j)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

