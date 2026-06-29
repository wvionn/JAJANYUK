import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/vendor_entity.dart';
import '../providers/menu_provider.dart';
import '../providers/cart_provider.dart';
import 'cart_page.dart';
import 'menu_detail_page.dart';
import 'chat_page.dart';
import '../../../../core/utils/currency_formatter.dart';

class VendorDetailPage extends ConsumerStatefulWidget {
  final VendorEntity vendor;
  const VendorDetailPage({super.key, required this.vendor});

  @override
  ConsumerState<VendorDetailPage> createState() => _VendorDetailPageState();
}

class _VendorDetailPageState extends ConsumerState<VendorDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(menuNotifierProvider.notifier).loadMenusByVendor(widget.vendor.id));
  }

  Color _getCategoryColor(String? cat) {
    switch (cat) {
      case 'Mie Goreng': return const Color(0xFFFFF9E6);
      case 'Kopi': return const Color(0xFFF2F2F2);
      case 'Nasi Goreng': return const Color(0xFFFFF2E6);
      case 'Dimsum': return const Color(0xFFFFEAEB);
      default: return const Color(0xFFE8F0FE);
    }
  }

  IconData _getCategoryIcon(String? cat) {
    switch (cat) {
      case 'Mie Goreng': return Icons.rice_bowl;
      case 'Kopi': return Icons.coffee;
      case 'Nasi Goreng': return Icons.dinner_dining;
      case 'Dimsum': return Icons.bakery_dining;
      default: return Icons.fastfood;
    }
  }

  Color _getCategoryIconColor(String? cat) {
    switch (cat) {
      case 'Mie Goreng': return const Color(0xFFF39C12);
      case 'Kopi': return const Color(0xFF7D5A50);
      case 'Nasi Goreng': return const Color(0xFFE67E22);
      case 'Dimsum': return const Color(0xFFE74C3C);
      default: return const Color(0xFF4F7FFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CartState>(cartNotifierProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(cartNotifierProvider.notifier).clearError();
      }
    });

    final menuState = ref.watch(menuNotifierProvider);
    final cartState = ref.watch(cartNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ──
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF4F7FFF),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              // Chat button
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                tooltip: 'Chat penjual',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      vendorId: widget.vendor.id,
                      vendorName: widget.vendor.name,
                    ),
                  ),
                ),
              ),
              // Cart button
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
                  ),
                  if (cartState.totalItems > 0)
                    Positioned(
                      right: 6, top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text('${cartState.totalItems}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.vendor.logoUrl != null
                      ? Image.network(widget.vendor.logoUrl!, fit: BoxFit.cover)
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF4F7FFF), Color(0xFF8BA7FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.storefront, size: 80, color: Colors.white54),
                        ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Vendor Info ──
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.vendor.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (widget.vendor.description != null)
                    Text(widget.vendor.description!,
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Rating
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9E6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 14),
                            SizedBox(width: 4),
                            Text('4.8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Time
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.access_time, color: Color(0xFF4F7FFF), size: 14),
                            SizedBox(width: 4),
                            Text('5-10 min', style: TextStyle(color: Color(0xFF4F7FFF), fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (widget.vendor.location != null)
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.vendor.location!,
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Chat with seller button
                  OutlinedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Chat dengan Penjual'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4F7FFF),
                      side: const BorderSide(color: Color(0xFF4F7FFF)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          vendorId: widget.vendor.id,
                          vendorName: widget.vendor.name,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Menu Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text('Daftar Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  if (!menuState.isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F7FFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${menuState.menus.length} item',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Menu List ──
          if (menuState.isLoading)
            const SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ))
          else if (menuState.menus.isEmpty)
            const SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('Belum ada menu tersedia', style: TextStyle(color: Colors.grey))),
            ))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final menu = menuState.menus[index];
                    final qty = cartState.getQuantity(menu.id);
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MenuDetailPage(
                            menu: menu,
                            vendorName: widget.vendor.name,
                            vendorId: widget.vendor.id,
                          ),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Menu image / placeholder
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: menu.imageUrl != null
                                  ? Image.network(menu.imageUrl!, width: 85, height: 85, fit: BoxFit.cover)
                                  : Container(
                                      width: 85, height: 85,
                                      color: _getCategoryColor(menu.category),
                                      child: Icon(_getCategoryIcon(menu.category),
                                          color: _getCategoryIconColor(menu.category), size: 36),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(menu.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  if (menu.description != null)
                                    Text(
                                      menu.description!,
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        menu.price.toRupiah(),
                                        style: const TextStyle(
                                          color: Color(0xFFE67E22),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      // Qty control
                                      Row(
                                        children: [
                                          if (qty > 0) ...[
                                            GestureDetector(
                                              onTap: () => ref.read(cartNotifierProvider.notifier).removeFromCart(menu),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF4F7FFF), shape: BoxShape.circle),
                                                child: const Icon(Icons.remove, color: Colors.white, size: 14),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                          GestureDetector(
                                            onTap: () => ref.read(cartNotifierProvider.notifier).addToCart(menu),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF4F7FFF), shape: BoxShape.circle),
                                              child: const Icon(Icons.add, color: Colors.white, size: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: menuState.menus.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // Floating cart button
      bottomNavigationBar: cartState.totalItems > 0
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              color: Colors.white,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F7FFF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      '${cartState.totalItems} item  •  ${cartState.totalPrice.toRupiah()}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(width: 10),
                    const Text('→', style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
