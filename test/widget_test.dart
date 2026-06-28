import 'package:flutter_test/flutter_test.dart';
import 'package:esa_eats/features/user/presentation/providers/cart_provider.dart';
import 'package:esa_eats/features/user/domain/entities/menu_entity.dart';
import 'package:esa_eats/features/user/domain/repositories/order_repository.dart';
import 'package:esa_eats/features/user/domain/entities/order_entity.dart';
import 'package:esa_eats/features/user/domain/entities/cart_item_entity.dart';

class FakeOrderRepository implements OrderRepository {
  @override
  Future<OrderEntity> createOrder({
    required String vendorId,
    required List<CartItemEntity> items,
    String? note,
  }) async {
    return OrderEntity(
      id: 'test_order_id',
      customerId: 'test_customer_id',
      vendorId: vendorId,
      totalPrice: items.fold(0.0, (sum, item) => sum + item.subtotal),
      orderStatus: 'pending',
      paymentStatus: 'pending',
      note: note,
      createdAt: DateTime.parse('2026-06-28T12:00:00Z'),
    );
  }

  @override
  Future<List<OrderEntity>> getMyOrders() async {
    return [];
  }
}

void main() {
  group('CartNotifier Tests', () {
    late FakeOrderRepository repository;
    late CartNotifier cartNotifier;

    setUp(() {
      repository = FakeOrderRepository();
      cartNotifier = CartNotifier(repository);
    });

    const menu1 = MenuEntity(
      id: 'menu_1',
      vendorId: 'vendor_a',
      name: 'Nasi Goreng',
      price: 15000,
      category: 'Nasi Goreng',
    );

    const menu2 = MenuEntity(
      id: 'menu_2',
      vendorId: 'vendor_a',
      name: 'Es Teh',
      price: 5000,
      category: 'Minuman',
    );

    const menuDifferentVendor = MenuEntity(
      id: 'menu_3',
      vendorId: 'vendor_b',
      name: 'Bakso',
      price: 20000,
      category: 'Makanan',
    );

    test('initial state should be empty', () {
      expect(cartNotifier.state.items, isEmpty);
      expect(cartNotifier.state.totalItems, 0);
      expect(cartNotifier.state.totalPrice, 0.0);
      expect(cartNotifier.state.vendorId, isNull);
    });

    test('addToCart adds item and increments quantity', () {
      cartNotifier.addToCart(menu1);
      expect(cartNotifier.state.items.length, 1);
      expect(cartNotifier.state.items.first.menu, menu1);
      expect(cartNotifier.state.items.first.quantity, 1);
      expect(cartNotifier.state.totalItems, 1);
      expect(cartNotifier.state.totalPrice, 15000.0);
      expect(cartNotifier.state.vendorId, 'vendor_a');

      // Add same item again
      cartNotifier.addToCart(menu1);
      expect(cartNotifier.state.items.length, 1);
      expect(cartNotifier.state.items.first.quantity, 2);
      expect(cartNotifier.state.totalItems, 2);
      expect(cartNotifier.state.totalPrice, 30000.0);
    });

    test('addToCart rejects items from different vendors', () {
      cartNotifier.addToCart(menu1);
      expect(cartNotifier.state.error, isNull);

      cartNotifier.addToCart(menuDifferentVendor);
      expect(cartNotifier.state.items.length, 1);
      expect(cartNotifier.state.error, 'Hanya bisa memesan dari satu warung dalam satu pesanan.');
    });

    test('removeFromCart decrements quantity and removes item', () {
      cartNotifier.addToCart(menu1);
      cartNotifier.addToCart(menu1);
      expect(cartNotifier.state.items.first.quantity, 2);

      cartNotifier.removeFromCart(menu1);
      expect(cartNotifier.state.items.first.quantity, 1);

      cartNotifier.removeFromCart(menu1);
      expect(cartNotifier.state.items, isEmpty);
      expect(cartNotifier.state.totalItems, 0);
    });

    test('clearCart empties the cart', () {
      cartNotifier.addToCart(menu1);
      cartNotifier.addToCart(menu2);
      expect(cartNotifier.state.items.length, 2);

      cartNotifier.clearCart();
      expect(cartNotifier.state.items, isEmpty);
      expect(cartNotifier.state.totalItems, 0);
      expect(cartNotifier.state.totalPrice, 0.0);
    });

    test('checkout sets lastOrder and clears items on success', () async {
      cartNotifier.addToCart(menu1);
      cartNotifier.addToCart(menu2);

      await cartNotifier.checkout(note: 'Pedas ya');
      expect(cartNotifier.state.lastOrder, isNotNull);
      expect(cartNotifier.state.lastOrder!.vendorId, 'vendor_a');
      expect(cartNotifier.state.lastOrder!.totalPrice, 20000.0);
      expect(cartNotifier.state.lastOrder!.note, 'Pedas ya');
      expect(cartNotifier.state.items, isEmpty);
    });
  });
}
