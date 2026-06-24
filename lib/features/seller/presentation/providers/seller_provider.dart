import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/seller_remote_datasource.dart';
import '../../data/repositories/seller_repository_impl.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/seller_repository.dart';

// ── DI ──

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

// ── Current Seller ID ──

final currentSellerIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
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
  final String sellerId;

  MenuNotifier(this._repository, this.sellerId) : super(const MenuState()) {
    loadMenu();
  }

  Future<void> loadMenu() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getMenuItems(sellerId);
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
    String? category,
    bool available = true,
  }) async {
    final result = await _repository.addMenuItem(
      sellerId: sellerId,
      name: name,
      description: description,
      price: price,
      category: category,
      available: available,
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
    bool? available,
  }) async {
    final result = await _repository.updateMenuItem(
      menuItemId: menuItemId,
      name: name,
      description: description,
      price: price,
      category: category,
      available: available,
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
  final sellerId = ref.watch(currentSellerIdProvider) ?? '';
  return MenuNotifier(ref.watch(sellerRepositoryProvider), sellerId);
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
    return orders.where((o) => o.status == filterStatus).toList();
  }

  int countByStatus(String status) =>
      orders.where((o) => o.status == status).length;
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  final SellerRepository _repository;
  final String sellerId;

  OrdersNotifier(this._repository, this.sellerId) : super(const OrdersState()) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getOrders(sellerId);
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
  final sellerId = ref.watch(currentSellerIdProvider) ?? '';
  return OrdersNotifier(ref.watch(sellerRepositoryProvider), sellerId);
});

// ── Chat ──

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
