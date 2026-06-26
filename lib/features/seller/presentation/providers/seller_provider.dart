import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/seller_remote_datasource.dart';
import '../../data/repositories/seller_repository_impl.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/vendor_entity.dart';
import '../../domain/entities/seller_profile_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/seller_repository.dart';

// ── Dependency Injection ──

final sellerRemoteDataSourceProvider = Provider<SellerRemoteDataSource>((ref) {
  return SellerRemoteDataSourceImpl(
    supabaseClient: Supabase.instance.client,
  );
});

final sellerRepositoryProvider = Provider<SellerRepository>((ref) {
  return SellerRepositoryImpl(
    remoteDataSource: ref.watch(sellerRemoteDataSourceProvider),
  );
});

// ── Current Seller ID & Profile ──

final currentSellerIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

final sellerProfileFutureProvider = FutureProvider<SellerProfileEntity?>((ref) async {
  final userId = ref.watch(currentSellerIdProvider);
  if (userId == null) return null;
  final repository = ref.watch(sellerRepositoryProvider);
  final result = await repository.getSellerProfile(userId);
  return result.fold(
    (failure) => throw failure.message,
    (profile) => profile,
  );
});

final currentVendorIdProvider = Provider<String?>((ref) {
  return ref.watch(sellerProfileFutureProvider).valueOrNull?.vendorId;
});

// ── Vendor Profile Notifier ──

class VendorProfileNotifier extends StateNotifier<AsyncValue<VendorEntity?>> {
  final SellerRepository _repository;
  final Ref _ref;

  VendorProfileNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _ref.listen<String?>(currentVendorIdProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        loadVendorProfile(next);
      } else {
        state = const AsyncValue.data(null);
      }
    });

    final vendorId = _ref.read(currentVendorIdProvider);
    if (vendorId != null && vendorId.isNotEmpty) {
      loadVendorProfile(vendorId);
    }
  }

  Future<void> loadVendorProfile(String vendorId) async {
    state = const AsyncValue.loading();
    final result = await _repository.getVendorProfile(vendorId);
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (vendor) => state = AsyncValue.data(vendor),
    );
  }

  Future<String?> updateProfile(VendorEntity vendor) async {
    final result = await _repository.updateVendorProfile(vendor);
    return result.fold(
      (failure) => failure.message,
      (updatedVendor) {
        state = AsyncValue.data(updatedVendor);
        return null;
      },
    );
  }

  Future<String?> toggleOpenStatus(bool isOpen) async {
    final current = state.valueOrNull;
    if (current == null) return 'Profil vendor belum dimuat';
    final updated = current.copyWith(isOpen: isOpen);
    return await updateProfile(updated);
  }
}

final vendorProfileProvider =
    StateNotifierProvider<VendorProfileNotifier, AsyncValue<VendorEntity?>>((ref) {
  return VendorProfileNotifier(ref.watch(sellerRepositoryProvider), ref);
});

// ── Menu Notifier ──

class MenuState {
  final List<MenuItemEntity> items;
  final bool isLoading;
  final String? error;

  const MenuState({
    this.items = const [],
    this.isLoading = true,
    this.error,
  });

  MenuState copyWith({
    List<MenuItemEntity>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MenuState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MenuNotifier extends StateNotifier<MenuState> {
  final SellerRepository _repository;
  final String vendorId;

  MenuNotifier(this._repository, this.vendorId) : super(const MenuState()) {
    if (vendorId.isNotEmpty) {
      loadMenu();
    }
  }

  Future<void> loadMenu() async {
    if (vendorId.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getMenuItems(vendorId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (items) => state = state.copyWith(items: items, isLoading: false),
    );
  }

  Future<String?> addItem({
    required String name,
    String? description,
    required double price,
    required String category,
    required int stock,
    required int estimatedTime,
    String? label,
    bool isAvailable = true,
  }) async {
    if (vendorId.isEmpty) return 'Vendor ID tidak ditemukan';
    final result = await _repository.addMenuItem(
      vendorId: vendorId,
      name: name,
      description: description,
      price: price,
      category: category,
      stock: stock,
      estimatedTime: estimatedTime,
      label: label,
      isAvailable: isAvailable,
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        loadMenu();
        return null;
      },
    );
  }

  Future<String?> updateItem({
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
    final result = await _repository.updateMenuItem(
      menuItemId: menuItemId,
      name: name,
      description: description,
      price: price,
      category: category,
      stock: stock,
      estimatedTime: estimatedTime,
      label: label,
      isAvailable: isAvailable,
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        loadMenu();
        return null;
      },
    );
  }

  Future<bool> deleteItem(String menuItemId) async {
    final result = await _repository.deleteMenuItem(menuItemId);
    return result.fold(
      (_) => false,
      (_) {
        loadMenu();
        return true;
      },
    );
  }
}

final menuNotifierProvider =
    StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  final vendorId = ref.watch(currentVendorIdProvider) ?? '';
  return MenuNotifier(ref.watch(sellerRepositoryProvider), vendorId);
});

// ── Orders Notifier ──

class OrdersState {
  final List<OrderEntity> orders;
  final bool isLoading;
  final String? error;
  final String filterStatus;

  const OrdersState({
    this.orders = const [],
    this.isLoading = true,
    this.error,
    this.filterStatus = 'all',
  });

  OrdersState copyWith({
    List<OrderEntity>? orders,
    bool? isLoading,
    String? error,
    String? filterStatus,
    bool clearError = false,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filterStatus: filterStatus ?? this.filterStatus,
    );
  }

  List<OrderEntity> get filteredOrders {
    if (filterStatus == 'all') return orders;
    return orders.where((o) => o.orderStatus == filterStatus).toList();
  }

  int countByStatus(String status) =>
      orders.where((o) => o.orderStatus == status).length;
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  final SellerRepository _repository;
  final String vendorId;

  OrdersNotifier(this._repository, this.vendorId) : super(const OrdersState()) {
    if (vendorId.isNotEmpty) {
      loadOrders();
    }
  }

  Future<void> loadOrders() async {
    if (vendorId.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getOrders(vendorId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (orders) => state = state.copyWith(orders: orders, isLoading: false),
    );
  }

  void setFilter(String status) {
    state = state.copyWith(filterStatus: status);
  }

  Future<bool> updateStatus(String orderId, String newStatus) async {
    final result = await _repository.updateOrderStatus(
      orderId: orderId,
      status: newStatus,
    );
    return result.fold(
      (_) => false,
      (_) {
        loadOrders();
        return true;
      },
    );
  }
}

final ordersNotifierProvider =
    StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final vendorId = ref.watch(currentVendorIdProvider) ?? '';
  return OrdersNotifier(ref.watch(sellerRepositoryProvider), vendorId);
});

// ── Transaction Reports Notifier ──

class SellerTransactionState {
  final List<TransactionEntity> transactions;
  final bool isLoading;
  final String? error;
  final String filterStatus;
  final DateTime? startDate;
  final DateTime? endDate;

  const SellerTransactionState({
    this.transactions = const [],
    this.isLoading = true,
    this.error,
    this.filterStatus = 'all',
    this.startDate,
    this.endDate,
  });

  SellerTransactionState copyWith({
    List<TransactionEntity>? transactions,
    bool? isLoading,
    String? error,
    String? filterStatus,
    DateTime? startDate,
    DateTime? endDate,
    bool clearError = false,
    bool clearDates = false,
  }) {
    return SellerTransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filterStatus: filterStatus ?? this.filterStatus,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
    );
  }
}

class SellerTransactionNotifier extends StateNotifier<SellerTransactionState> {
  final SellerRepository _repository;
  final String vendorId;

  SellerTransactionNotifier(this._repository, this.vendorId)
      : super(const SellerTransactionState()) {
    if (vendorId.isNotEmpty) {
      loadReports();
    }
  }

  Future<void> loadReports({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (vendorId.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);

    final currentFilterStatus = status ?? state.filterStatus;
    final from = startDate ?? state.startDate;
    final to = endDate ?? state.endDate;

    final result = await _repository.getTransactionReports(
      vendorId,
      status: currentFilterStatus == 'all' ? null : currentFilterStatus,
      startDate: from,
      endDate: to,
    );

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (reports) => state = state.copyWith(
        transactions: reports,
        isLoading: false,
        filterStatus: currentFilterStatus,
        startDate: from,
        endDate: to,
      ),
    );
  }

  void setFilter(String status) {
    loadReports(status: status);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    loadReports(startDate: start, endDate: end);
  }

  void clearFilters() {
    state = state.copyWith(filterStatus: 'all', clearDates: true);
    loadReports(status: 'all');
  }
}

final sellerTransactionReportProvider =
    StateNotifierProvider<SellerTransactionNotifier, SellerTransactionState>((ref) {
  final vendorId = ref.watch(currentVendorIdProvider) ?? '';
  return SellerTransactionNotifier(ref.watch(sellerRepositoryProvider), vendorId);
});

// ── Chat Notifier ──

class ChatNotifier extends StateNotifier<AsyncValue<List<ChatMessageEntity>>> {
  final SellerRepository _repository;
  final String orderId;
  final String currentUserId;

  ChatNotifier(this._repository, this.orderId, this.currentUserId)
      : super(const AsyncValue.loading()) {
    loadMessages();
  }

  Future<void> loadMessages() async {
    final result = await _repository.getChatMessages(orderId);
    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (msgs) => state = AsyncValue.data(msgs),
    );
  }

  Future<bool> sendMessage(String message) async {
    if (message.trim().isEmpty) return false;
    final result = await _repository.sendMessage(
      orderId: orderId,
      senderId: currentUserId,
      message: message.trim(),
    );
    return result.fold(
      (_) => false,
      (_) {
        loadMessages();
        return true;
      },
    );
  }
}

// Per-order chat provider
final chatNotifierProvider = StateNotifierProvider.family<ChatNotifier,
    AsyncValue<List<ChatMessageEntity>>, String>((ref, orderId) {
  final userId = ref.watch(currentSellerIdProvider) ?? '';
  return ChatNotifier(
    ref.watch(sellerRepositoryProvider),
    orderId,
    userId,
  );
});
