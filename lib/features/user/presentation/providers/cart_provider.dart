import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/entities/menu_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';

// ── DI ──

final orderRemoteDatasourceProvider = Provider<OrderRemoteDatasource>((ref) {
  return OrderRemoteDatasource(Supabase.instance.client);
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(ref.watch(orderRemoteDatasourceProvider));
});

// ── Cart ──

class CartState {
  final List<CartItemEntity> items;
  final bool isLoading;
  final String? error;
  final OrderEntity? lastOrder;

  const CartState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.lastOrder,
  });

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => items.fold(0.0, (sum, item) => sum + item.subtotal);
  String? get vendorId => items.isNotEmpty ? items.first.menu.vendorId : null;

  int getQuantity(String menuId) {
    final index = items.indexWhere((item) => item.menu.id == menuId);
    return index >= 0 ? items[index].quantity : 0;
  }

  CartState copyWith({
    List<CartItemEntity>? items,
    bool? isLoading,
    String? error,
    OrderEntity? lastOrder,
    bool clearError = false,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastOrder: lastOrder ?? this.lastOrder,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final OrderRepository _repository;

  CartNotifier(this._repository) : super(const CartState());

  void addToCart(MenuEntity menu) {
    final items = [...state.items];
    if (items.isNotEmpty && items.first.menu.vendorId != menu.vendorId) {
      state = state.copyWith(error: 'Hanya bisa memesan dari satu warung dalam satu pesanan.');
      return;
    }
    final index = items.indexWhere((item) => item.menu.id == menu.id);
    if (index >= 0) {
      items[index] = CartItemEntity(menu: menu, quantity: items[index].quantity + 1);
    } else {
      items.add(CartItemEntity(menu: menu, quantity: 1));
    }
    state = state.copyWith(items: items, clearError: true);
  }

  void removeFromCart(MenuEntity menu) {
    final items = [...state.items];
    final index = items.indexWhere((item) => item.menu.id == menu.id);
    if (index >= 0) {
      if (items[index].quantity > 1) {
        items[index] = CartItemEntity(menu: menu, quantity: items[index].quantity - 1);
      } else {
        items.removeAt(index);
      }
    }
    state = state.copyWith(items: items, clearError: true);
  }

  void clearCart() {
    state = const CartState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> checkout({String? note}) async {
    if (state.items.isEmpty || state.vendorId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final order = await _repository.createOrder(
        vendorId: state.vendorId!,
        items: state.items,
        note: note,
      );
      state = CartState(lastOrder: order);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final cartNotifierProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref.watch(orderRepositoryProvider));
});

final orderHistoryProvider = FutureProvider<List<OrderEntity>>((ref) async {
  return ref.watch(orderRepositoryProvider).getMyOrders();
});