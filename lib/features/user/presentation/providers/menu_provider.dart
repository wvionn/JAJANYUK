import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/menu_remote_datasource.dart';
import '../../data/repositories/menu_repository_impl.dart';
import '../../domain/entities/menu_entity.dart';
import '../../domain/entities/vendor_entity.dart';
import '../../domain/repositories/menu_repository.dart';

// ── DI ──

final menuRemoteDatasourceProvider = Provider<MenuRemoteDatasource>((ref) {
  return MenuRemoteDatasource(Supabase.instance.client);
});

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepositoryImpl(ref.watch(menuRemoteDatasourceProvider));
});

// ── Vendors ──

class VendorState {
  final List<VendorEntity> vendors;
  final bool isLoading;
  final String? error;

  const VendorState({
    this.vendors = const [],
    this.isLoading = true,
    this.error,
  });

  VendorState copyWith({
    List<VendorEntity>? vendors,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return VendorState(
      vendors: vendors ?? this.vendors,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class VendorNotifier extends StateNotifier<VendorState> {
  final MenuRepository _repository;
  StreamSubscription? _subscription;

  VendorNotifier(this._repository) : super(const VendorState()) {
    _subscribeToVendors();
  }

  void _subscribeToVendors() {
    state = state.copyWith(isLoading: true, clearError: true);
    _subscription = _repository.watchVendors().listen(
      (vendors) {
        state = state.copyWith(vendors: vendors, isLoading: false);
      },
      onError: (e) {
        state = state.copyWith(isLoading: false, error: e.toString());
      },
    );
  }

  Future<void> loadVendors() async {
    // Re-subscribe to refresh data
    _subscription?.cancel();
    _subscribeToVendors();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final vendorNotifierProvider = StateNotifierProvider<VendorNotifier, VendorState>((ref) {
  return VendorNotifier(ref.watch(menuRepositoryProvider));
});

// ── Menus by Vendor ──

class MenuState {
  final List<MenuEntity> menus;
  final bool isLoading;
  final String? error;

  const MenuState({
    this.menus = const [],
    this.isLoading = false,
    this.error,
  });

  MenuState copyWith({
    List<MenuEntity>? menus,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MenuState(
      menus: menus ?? this.menus,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MenuNotifier extends StateNotifier<MenuState> {
  final MenuRepository _repository;

  MenuNotifier(this._repository) : super(const MenuState());

  Future<void> loadMenusByVendor(String vendorId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final menus = await _repository.getMenusByVendor(vendorId);
      state = state.copyWith(menus: menus, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMenusByCategory(String category) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final menus = await _repository.getMenusByCategory(category);
      state = state.copyWith(menus: menus, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final menuNotifierProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  return MenuNotifier(ref.watch(menuRepositoryProvider));
});

// ── Search ──

class SearchState {
  final List<MenuEntity> results;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    List<MenuEntity>? results,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final MenuRepository _repository;

  SearchNotifier(this._repository) : super(const SearchState());

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const SearchState();
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await _repository.searchMenus(query);
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final searchNotifierProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.watch(menuRepositoryProvider));
});

final allMenusProvider = FutureProvider<List<MenuEntity>>((ref) async {
  return ref.watch(menuRemoteDatasourceProvider).getAllMenus();
});