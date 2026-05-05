import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../auth/data/models/user_model.dart';

abstract class AdminRemoteDataSource {
  Future<UserModel> registerSeller({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  });

  Future<List<UserModel>> getAllSellers();
  Future<void> updateSellerStatus({
    required String sellerId,
    required bool isActive,
  });
  Future<void> deleteSeller(String sellerId);
  Future<Map<String, dynamic>> getPlatformStats();
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final SupabaseClient supabaseClient;

  AdminRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<UserModel> registerSeller({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      // Admin creates seller account using Supabase Admin API
      // Note: This requires admin privileges
      final response = await supabaseClient.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
        ),
      );

      if (response.user == null) {
        throw ServerException('Failed to create seller account');
      }

      // Insert seller profile data
      final profileData = {
        'id': response.user!.id,
        'email': email,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'role': 'seller',
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
  Future<void> updateSellerStatus({
    required String sellerId,
    required bool isActive,
  }) async {
    try {
      await supabaseClient
          .from('users')
          .update({'is_active': isActive})
          .eq('id', sellerId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteSeller(String sellerId) async {
    try {
      // Delete user from auth
      await supabaseClient.auth.admin.deleteUser(sellerId);

      // Delete user profile
      await supabaseClient.from('users').delete().eq('id', sellerId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> getPlatformStats() async {
    try {
      // Get counts for different entities
      final sellersCount = await supabaseClient
          .from('users')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('role', 'seller');

      final buyersCount = await supabaseClient
          .from('users')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('role', 'buyer');

      final ordersCount = await supabaseClient
          .from('orders')
          .select('id', const FetchOptions(count: CountOption.exact));

      return {
        'sellers_count': sellersCount.count,
        'buyers_count': buyersCount.count,
        'orders_count': ordersCount.count,
      };
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
