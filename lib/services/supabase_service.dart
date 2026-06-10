import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  late SupabaseClient _client;

  SupabaseClient get client => _client;

  /// Initialize Supabase
  Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    _client = Supabase.instance.client;
  }

  /// Get current user
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  /// Check if user is logged in
  bool isUserLoggedIn() {
    return _client.auth.currentUser != null;
  }

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Get data from table
  Future<List<Map<String, dynamic>>> getTableData(String tableName) async {
    final response = await _client.from(tableName).select();
    return response;
  }

  /// Insert data to table
  Future<Map<String, dynamic>> insertData(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.from(tableName).insert(data).select();
    return response.first;
  }

  /// Update data in table
  Future<void> updateData(
    String tableName,
    Map<String, dynamic> data,
    String columnName,
    dynamic value,
  ) async {
    await _client.from(tableName).update(data).eq(columnName, value);
  }

  /// Delete data from table
  Future<void> deleteData(
    String tableName,
    String columnName,
    dynamic value,
  ) async {
    await _client.from(tableName).delete().eq(columnName, value);
  }

  /// Query with filter
  Future<List<Map<String, dynamic>>> queryData(
    String tableName,
    String columnName,
    dynamic value,
  ) async {
    final response =
        await _client.from(tableName).select().eq(columnName, value);
    return response;
  }
}
