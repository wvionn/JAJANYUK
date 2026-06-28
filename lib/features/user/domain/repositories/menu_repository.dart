import '../entities/menu_entity.dart';
import '../entities/vendor_entity.dart';

abstract class MenuRepository {
  Future<List<VendorEntity>> getVendors();
  Future<List<MenuEntity>> getMenusByVendor(String vendorId);
  Future<List<MenuEntity>> searchMenus(String query);
  Future<List<MenuEntity>> getMenusByCategory(String category);
}