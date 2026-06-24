import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../../../core/errors/exceptions.dart';
import '../../../auth/data/models/user_model.dart';
import '../models/campus_model.dart';
import '../models/transaction_report_model.dart';

abstract class AdminRemoteDataSource {
  // ── User Management ──
  Future<List<UserModel>> getAllUsers();
  Future<List<UserModel>> getUsersByRole(String role);
  Future<void> updateUserStatus(
      {required String userId, required bool isActive});
  Future<void> deleteUser(String userId);

  // ── Seller Management ──
  Future<UserModel> registerSeller({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? campusId,
  });
  Future<List<UserModel>> getAllSellers();
  Future<void> updateSellerStatus(
      {required String sellerId, required bool isActive});
  Future<void> deleteSeller(String sellerId);

  // ── Campus Management ──
  Future<List<CampusModel>> getAllCampuses();
  Future<CampusModel> createCampus(
      {required String name, String? address, String? city});
  Future<void> updateCampus({
    required String campusId,
    String? name,
    String? address,
    String? city,
    bool? isActive,
  });
  Future<void> deleteCampus(String campusId);

  // ── Reports ──
  Future<PlatformStatsModel> getPlatformStats();
  Future<List<TransactionReportModel>> getTransactionReports({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  });
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final SupabaseClient supabaseClient;

  AdminRemoteDataSourceImpl({required this.supabaseClient});

  // ── User Management ──

  @override
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await supabaseClient
          .from('users')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final response = await supabaseClient
          .from('users')
          .select()
          .eq('role', role)
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateUserStatus(
      {required String userId, required bool isActive}) async {
    try {
      await supabaseClient.from('users').update({
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', userId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await supabaseClient.auth.admin.deleteUser(userId);
      await supabaseClient.from('users').delete().eq('id', userId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ── Seller Management ──

  @override
  Future<UserModel> registerSeller({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? campusId,
  }) async {
    try {
      final response = await supabaseClient.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
        ),
      );

      if (response.user == null) {
        throw ServerException('Gagal membuat akun seller');
      }

      final profileData = {
        'id': response.user!.id,
        'email': email,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'role': 'seller',
        'campus_id': campusId,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      await supabaseClient.from('users').insert(profileData);

      return UserModel.fromJson({...profileData, 'updated_at': null});
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<UserModel>> getAllSellers() async {
    try {
      final response = await supabaseClient
          .from('users')
          .select()
          .eq('role', 'seller')
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateSellerStatus(
      {required String sellerId, required bool isActive}) async {
    try {
      await supabaseClient.from('users').update({
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', sellerId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteSeller(String sellerId) async {
    try {
      await supabaseClient.auth.admin.deleteUser(sellerId);
      await supabaseClient.from('users').delete().eq('id', sellerId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ── Campus Management ──

  @override
  Future<List<CampusModel>> getAllCampuses() async {
    try {
      final response = await supabaseClient
          .from('campuses')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => CampusModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<CampusModel> createCampus(
      {required String name, String? address, String? city}) async {
    try {
      final data = {
        'name': name,
        'address': address,
        'city': city,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };
      final response =
          await supabaseClient.from('campuses').insert(data).select().single();
      return CampusModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateCampus({
    required String campusId,
    String? name,
    String? address,
    String? city,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String()
      };
      if (name != null) data['name'] = name;
      if (address != null) data['address'] = address;
      if (city != null) data['city'] = city;
      if (isActive != null) data['is_active'] = isActive;

      await supabaseClient.from('campuses').update(data).eq('id', campusId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteCampus(String campusId) async {
    try {
      await supabaseClient.from('campuses').delete().eq('id', campusId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ── Reports ──

  @override
  Future<PlatformStatsModel> getPlatformStats() async {
    try {
      final sellersRes =
          await supabaseClient.from('users').select('id').eq('role', 'seller');
      final buyersRes =
          await supabaseClient.from('users').select('id').eq('role', 'buyer');
      final campusesRes = await supabaseClient.from('campuses').select('id');

      List ordersRes = [];
      List pendingRes = [];
      List completedRes = [];
      double totalRevenue = 0;

      try {
        ordersRes =
            await supabaseClient.from('orders').select('id, total_amount');
        pendingRes = await supabaseClient
            .from('orders')
            .select('id')
            .eq('status', 'pending');
        completedRes = await supabaseClient
            .from('orders')
            .select('id, total_amount')
            .eq('status', 'completed');
        totalRevenue = completedRes.fold(
          0.0,
          (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0.0),
        );
      } catch (_) {
        // orders table might not exist yet
      }

      return PlatformStatsModel(
        totalSellers: (sellersRes as List).length,
        totalBuyers: (buyersRes as List).length,
        totalOrders: ordersRes.length,
        totalCampuses: (campusesRes as List).length,
        totalRevenue: totalRevenue,
        pendingOrders: pendingRes.length,
        completedOrders: completedRes.length,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<TransactionReportModel>> getTransactionReports({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      var query = supabaseClient.from('orders').select(
        '''
        id, total_amount, status, payment_method, created_at,
        buyer:users!orders_buyer_id_fkey(full_name, email),
        seller:users!orders_seller_id_fkey(full_name),
        order_items(product_name, quantity, price)
        ''',
      );

      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((json) => TransactionReportModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
