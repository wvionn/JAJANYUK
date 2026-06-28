import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/vendor_model.dart';
import '../providers/menu_provider.dart';
import '../providers/cart_provider.dart';
import 'vendor_detail_page.dart';
import 'search_page.dart';
import 'cart_page.dart';
import 'menu_detail_page.dart';
import 'chat_list_page.dart';
import '../../../onboarding/presentation/pages/campus_selection_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UserHomePage extends ConsumerStatefulWidget {
  const UserHomePage({super.key});

  @override
  ConsumerState<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends ConsumerState<UserHomePage> {
  final List<String> categories = ['Mie Goreng', 'Kopi', 'Nasi Goreng', 'Dimsum'];
  String _selectedCategory = 'Semua';

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Mie Goreng':
        return Icons.rice_bowl;
      case 'Kopi':
        return Icons.coffee;
      case 'Nasi Goreng':
        return Icons.dinner_dining;
      case 'Dimsum':
        return Icons.bakery_dining;
      default:
        return Icons.restaurant;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Mie Goreng':
        return const Color(0xFFFFF9E6);
      case 'Kopi':
        return const Color(0xFFF2F2F2);
      case 'Nasi Goreng':
        return const Color(0xFFFFF2E6);
      case 'Dimsum':
        return const Color(0xFFFFEAEB);
      default:
        return const Color(0xFFE8F0FE);
    }
  }

  Color _getCategoryIconColor(String category) {
    switch (category) {
      case 'Mie Goreng':
        return const Color(0xFFF39C12);
      case 'Kopi':
        return const Color(0xFF7D5A50);
      case 'Nasi Goreng':
        return const Color(0xFFE67E22);
      case 'Dimsum':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF4F7FFF);
    }
  }

  Color _getRecommendationBgColor(String category) {
    switch (category) {
      case 'Mie Goreng':
        return const Color(0xFFE8F4FD); // Light blue
      case 'Nasi Goreng':
        return const Color(0xFFFEE8EC); // Light pink
      case 'Dimsum':
        return const Color(0xFFF3EAFB); // Light purple
      default:
        return const Color(0xFFE8F0FE);
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

    final vendorState = ref.watch(vendorNotifierProvider);
    final cartState = ref.watch(cartNotifierProvider);
    final menuState = ref.watch(menuNotifierProvider);
    final allMenusAsync = ref.watch(allMenusProvider);

    // Resolve Campus Name
    final rawCampusId = ref.watch(authStateProvider).valueOrNull?.campusId ?? ref.watch(selectedCampusIdProvider);
    final campusesAsync = ref.watch(onboardingCampusesProvider);
    
    String campusName = 'Memuat Kampus...';
    String? effectiveCampusId = rawCampusId;

    campusesAsync.whenData((campuses) {
      if (rawCampusId != null && campuses.isNotEmpty) {
        // Cek apakah campusId user valid dan ada di list campuses
        final isValidCampus = campuses.any((c) => c.id == rawCampusId);
        
        if (!isValidCampus) {
          // Fallback ke Kampus Bekasi jika ID tidak valid
          effectiveCampusId = 'bc3287ef-8742-4863-b3b3-993155e13ecc';
        }

        final campus = campuses.firstWhere(
          (c) => c.id == effectiveCampusId,
          orElse: () => campuses.firstWhere(
            (c) => c.name.toLowerCase().contains('bekasi'),
            orElse: () => campuses.first,
          ),
        );
        campusName = campus.name;
      } else if (rawCampusId == null) {
        campusName = 'Kampus Umum';
      }
    });

    // Filter Vendors by selected campus (BYPASSED UNTUK TESTING)
    final filteredVendors = vendorState.vendors;

    // Filter Menus for category by selected campus vendors (BYPASSED UNTUK TESTING)
    final filteredMenus = menuState.menus;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EsaEats',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF4F7FFF), size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    campusName,
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.normal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.black),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatListPage()),
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
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
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(vendorNotifierProvider);
          ref.invalidate(allMenusProvider);
          if (_selectedCategory != 'Semua') {
            ref.read(menuNotifierProvider.notifier).loadMenusByCategory(_selectedCategory);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Cari menu atau stan...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Kategori Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = 'Semua';
                      });
                    },
                    child: const Text(
                      'See all',
                      style: TextStyle(color: Color(0xFF4F7FFF), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Kategori List (Vertical Tiles in Row)
              SizedBox(
                height: 95,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                        ref.read(menuNotifierProvider.notifier).loadMenusByCategory(cat);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(cat),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF4F7FFF) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _getCategoryIcon(cat),
                              color: _getCategoryIconColor(cat),
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF4F7FFF) : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              if (_selectedCategory == 'Semua') ...[
                // Rekomendasi untuk kamu
                const Text('Rekomendasi untuk kamu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                allMenusAsync.when(
                  loading: () => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
                  error: (err, _) => Center(child: Text('Gagal memuat rekomendasi: $err')),
                  data: (allMenus) {
                    // Filter recommendations by campus vendors (BYPASSED UNTUK TESTING)
                    final filteredRecs = allMenus;

                    if (filteredRecs.isEmpty) {
                      return const Center(child: Text('Belum ada menu rekomendasi di kampus ini'));
                    }

                    return SizedBox(
                      height: 175,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: filteredRecs.length > 5 ? 5 : filteredRecs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final menu = filteredRecs[index];
                          final vendor = vendorState.vendors.firstWhere(
                            (v) => v.id == menu.vendorId,
                            orElse: () => const VendorModel(id: '', name: 'Warung'),
                          );
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MenuDetailPage(
                                  menu: menu,
                                  vendorName: vendor.name,
                                  vendorId: vendor.id,
                                ),
                              ),
                            ),
                            child: Container(
                              width: 140,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top half with category color / icon
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: _getRecommendationBgColor(menu.category ?? ''),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          _getCategoryIcon(menu.category ?? ''),
                                          color: _getCategoryIconColor(menu.category ?? ''),
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Bottom half details
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          menu.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          vendor.name,
                                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Rp. ${menu.price.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                color: Color(0xFFE67E22),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => ref.read(cartNotifierProvider.notifier).addToCart(menu),
                                              child: Container(
                                                padding: const EdgeInsets.all(3),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF4F7FFF),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.add, color: Colors.white, size: 14),
                                              ),
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
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Daftar Stan Makanan
                const Text('Daftar Stan Makanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (vendorState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (vendorState.error != null)
                  Center(child: Text(vendorState.error!))
                else if (filteredVendors.isEmpty)
                  const Center(child: Text('Belum ada stan tersedia di kampus ini'))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredVendors.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final vendor = filteredVendors[index];
                      final stanNumber = index + 1;

                      // Make mockup tags from location/description
                      final mocktags = vendor.description != null && vendor.description!.isNotEmpty
                          ? vendor.description!.split(',').take(3).join(' • ')
                          : 'Makanan • Minuman • Cemilan';

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => VendorDetailPage(vendor: vendor)),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Large Banner Image / Placeholder
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: vendor.logoUrl != null
                                    ? Image.network(
                                        vendor.logoUrl!,
                                        height: 130,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 130,
                                        width: double.infinity,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Color(0xFFE8F0FE), Color(0xFFC3D8FA)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: const Icon(Icons.storefront, size: 50, color: Color(0xFF4F7FFF)),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Stan $stanNumber: ${vendor.name}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      mocktags,
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        // Star rating
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        const Text('4.8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        const SizedBox(width: 12),
                                        // Time badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('5-10 min', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        ),
                                        const SizedBox(width: 12),
                                        // Location
                                        const Icon(Icons.location_on_outlined, color: Colors.grey, size: 14),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            vendor.location ?? 'Area Kampus',
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
                  ),
              ] else ...[
                // Menu List for Category
                Text('Menu $_selectedCategory', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (menuState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (menuState.error != null)
                  Center(child: Text(menuState.error!))
                else if (filteredMenus.isEmpty)
                  const Center(child: Text('Belum ada menu di kategori ini'))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredMenus.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final menu = filteredMenus[index];
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
                                  ? Image.network(menu.imageUrl!, width: 80, height: 80, fit: BoxFit.cover)
                                  : Container(
                                      width: 80,
                                      height: 80,
                                      color: const Color(0xFFF5F5F5),
                                      child: const Icon(Icons.fastfood, color: Colors.grey),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(menu.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(
                                    vendor.name,
                                    style: const TextStyle(color: Color(0xFF4F7FFF), fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  if (menu.description != null)
                                    Text(
                                      menu.description!,
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp. ${menu.price.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                                  ),
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
                                  onTap: () => ref.read(cartNotifierProvider.notifier).addToCart(menu),
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}