import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/menu_provider.dart';
import '../providers/cart_provider.dart';
import '../../data/models/vendor_model.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

    final searchState = ref.watch(searchNotifierProvider);
    final cartState = ref.watch(cartNotifierProvider);
    final vendorState = ref.watch(vendorNotifierProvider);

    // Show all search results
    final filteredResults = searchState.results;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Cari menu...',
            border: InputBorder.none,
          ),
          onChanged: (value) => ref.read(searchNotifierProvider.notifier).search(value),
        ),
      ),
      body: searchState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredResults.isEmpty
              ? Center(
                  child: Text(
                    _controller.text.isEmpty ? 'Ketik untuk mencari menu' : 'Menu tidak ditemukan di kampus Anda',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredResults.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final menu = filteredResults[index];
                    final qty = cartState.getQuantity(menu.id);

                    // Find vendor
                    final vendor = vendorState.vendors.firstWhere(
                      (v) => v.id == menu.vendorId,
                      orElse: () => const VendorModel(id: '', name: 'Warung'),
                    );

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: menu.imageUrl != null
                                ? Image.network(menu.imageUrl!, width: 70, height: 70, fit: BoxFit.cover)
                                : Container(width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.fastfood, color: Colors.grey)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(menu.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  vendor.name,
                                  style: const TextStyle(color: Color(0xFF4F7FFF), fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                                if (menu.description != null)
                                  Text(
                                    menu.description!,
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                Text('Rp ${menu.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              if (qty > 0) ...[
                                GestureDetector(
                                  onTap: () => ref.read(cartNotifierProvider.notifier).removeFromCart(menu),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Color(0xFF4F7FFF), shape: BoxShape.circle),
                                    child: const Icon(Icons.remove, color: Colors.white, size: 16),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                              GestureDetector(
                                onTap: () {
                                  ref.read(cartNotifierProvider.notifier).addToCart(menu);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${menu.name} ditambahkan ke keranjang'),
                                      duration: const Duration(seconds: 1),
                                      backgroundColor: const Color(0xFF4F7FFF),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Color(0xFF4F7FFF), shape: BoxShape.circle),
                                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
