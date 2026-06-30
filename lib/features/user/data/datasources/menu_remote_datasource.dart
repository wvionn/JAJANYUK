import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_model.dart';
import '../models/vendor_model.dart';

class MenuRemoteDatasource {
  final SupabaseClient _client;

  MenuRemoteDatasource(this._client);

  // Remote data source for Menus and Vendors using Supabase client.

  Future<List<VendorModel>> getVendors() async {
    final response = await _client.from('vendors').select();
    return (response as List).map((json) => VendorModel.fromJson(json)).toList();
  }

  Stream<List<VendorModel>> watchVendors() {
    return _client
        .from('vendors')
        .stream(primaryKey: ['id'])
        .map((list) => list.map((json) => VendorModel.fromJson(json)).toList());
  }

  Future<List<MenuModel>> getMenusByVendor(String vendorId) async {
    final response = await _client.from('menus').select().eq('vendor_id', vendorId);
    return (response as List).map((json) => MenuModel.fromJson(json)).toList();
  }

  Future<List<MenuModel>> searchMenus(String query) async {
    final response = await _client.from('menus').select().ilike('name', '%$query%');
    return (response as List).map((json) => MenuModel.fromJson(json)).toList();
  }

  Future<List<MenuModel>> getMenusByCategory(String category) async {
    final response = await _client.from('menus').select();
    final allMenus = (response as List).map((json) => MenuModel.fromJson(json)).toList();
    return allMenus.where((m) => m.category == category).toList();
  }

  Future<List<MenuModel>> getAllMenus() async {
    final response = await _client.from('menus').select();
    return (response as List).map((json) => MenuModel.fromJson(json)).toList();
  }
}