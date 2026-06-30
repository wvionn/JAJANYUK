import '../../domain/entities/menu_entity.dart';
import '../../domain/entities/vendor_entity.dart';
import '../../domain/repositories/menu_repository.dart';
import '../datasources/menu_remote_datasource.dart';

class MenuRepositoryImpl implements MenuRepository {
  final MenuRemoteDatasource _datasource;

  MenuRepositoryImpl(this._datasource);

  @override
  Future<List<VendorEntity>> getVendors() async {
    return await _datasource.getVendors();
  }

  @override
  Stream<List<VendorEntity>> watchVendors() {
    return _datasource.watchVendors();
  }

  @override
  Future<List<MenuEntity>> getMenusByVendor(String vendorId) async {
    return await _datasource.getMenusByVendor(vendorId);
  }

  @override
  Future<List<MenuEntity>> searchMenus(String query) async {
    return await _datasource.searchMenus(query);
  }

  @override
  Future<List<MenuEntity>> getMenusByCategory(String category) async {
    return await _datasource.getMenusByCategory(category);
  }
}