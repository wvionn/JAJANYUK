import 'supabase_service.dart';

class UserService {
  final SupabaseService _supabase = SupabaseService();

  /// Get user role
  Future<String?> getUserRole(String userId) async {
    try {
      final response = await _supabase.queryData('users', 'id', userId);
      if (response.isNotEmpty) {
        return response.first['role'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user role: $e');
    }
  }

  /// Check if user is admin
  Future<bool> isAdmin(String userId) async {
    final role = await getUserRole(userId);
    return role == 'admin';
  }

  /// Check if user is seller
  Future<bool> isSeller(String userId) async {
    final role = await getUserRole(userId);
    return role == 'seller';
  }

  /// Check if user is buyer
  Future<bool> isBuyer(String userId) async {
    final role = await getUserRole(userId);
    return role == 'buyer';
  }

  /// Get current user role
  Future<String?> getCurrentUserRole() async {
    final user = _supabase.getCurrentUser();
    if (user == null) return null;
    return await getUserRole(user.id);
  }

  /// Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    final user = _supabase.getCurrentUser();
    if (user == null) return false;
    return await isAdmin(user.id);
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase.queryData('users', 'id', userId);
      if (response.isNotEmpty) {
        return response.first;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _supabase.getCurrentUser();
    if (user == null) return null;
    return await getUserProfile(user.id);
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? phone,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.updateData('users', updateData, 'id', userId);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Update user role (admin only)
  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    try {
      // Check if current user is admin
      final isCurrentAdmin = await isCurrentUserAdmin();
      if (!isCurrentAdmin) {
        throw Exception('Only admin can update user role');
      }

      await _supabase.updateData(
        'users',
        {'role': role, 'updated_at': DateTime.now().toIso8601String()},
        'id',
        userId,
      );
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  /// Get all users (admin only)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final isCurrentAdmin = await isCurrentUserAdmin();
      if (!isCurrentAdmin) {
        throw Exception('Only admin can view all users');
      }

      return await _supabase.getTableData('users');
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  /// Get all sellers
  Future<List<Map<String, dynamic>>> getAllSellers() async {
    try {
      return await _supabase.queryData('users', 'role', 'seller');
    } catch (e) {
      throw Exception('Failed to get sellers: $e');
    }
  }

  /// Get all buyers
  Future<List<Map<String, dynamic>>> getAllBuyers() async {
    try {
      return await _supabase.queryData('users', 'role', 'buyer');
    } catch (e) {
      throw Exception('Failed to get buyers: $e');
    }
  }

  /// Deactivate user (admin only)
  Future<void> deactivateUser(String userId) async {
    try {
      final isCurrentAdmin = await isCurrentUserAdmin();
      if (!isCurrentAdmin) {
        throw Exception('Only admin can deactivate users');
      }

      await _supabase.updateData(
        'users',
        {'is_active': false, 'updated_at': DateTime.now().toIso8601String()},
        'id',
        userId,
      );
    } catch (e) {
      throw Exception('Failed to deactivate user: $e');
    }
  }

  /// Activate user (admin only)
  Future<void> activateUser(String userId) async {
    try {
      final isCurrentAdmin = await isCurrentUserAdmin();
      if (!isCurrentAdmin) {
        throw Exception('Only admin can activate users');
      }

      await _supabase.updateData(
        'users',
        {'is_active': true, 'updated_at': DateTime.now().toIso8601String()},
        'id',
        userId,
      );
    } catch (e) {
      throw Exception('Failed to activate user: $e');
    }
  }
}
