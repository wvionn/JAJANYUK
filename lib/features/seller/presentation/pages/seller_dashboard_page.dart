import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/seller_provider.dart';

class SellerDashboardPage extends ConsumerWidget {
  const SellerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final ordersState = ref.watch(ordersNotifierProvider);
    final menuState = ref.watch(menuNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, user?.email ?? 'Seller'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.read(ordersNotifierProvider.notifier).loadOrders();
                  ref.read(menuNotifierProvider.notifier).loadMenu();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats row
                      _buildStatsRow(ordersState, menuState),
                      const SizedBox(height: 28),

                      // Menu utama
                      const Text(
                        'Menu Utama',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMenuGrid(context, ordersState),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String email) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFA842B), Color(0xFFFF9F4D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.store_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selamat Datang',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text('Penjual Kantin JAJANYUK',
                    style: TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(OrdersState ordersState, MenuState menuState) {
    final pendingCount = ordersState.countByStatus('pending');
    final processingCount = ordersState.countByStatus('processing');
    final menuCount = menuState.items.length;
    final activeMenu = menuState.items.where((i) => i.available).length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Pesanan Masuk',
            value: pendingCount.toString(),
            icon: Icons.receipt_outlined,
            color: AppColors.warning,
            badge: pendingCount > 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Diproses',
            value: processingCount.toString(),
            icon: Icons.restaurant_outlined,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Menu Aktif',
            value: '$activeMenu/$menuCount',
            icon: Icons.menu_book_outlined,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuGrid(BuildContext context, OrdersState ordersState) {
    final pendingCount = ordersState.countByStatus('pending');

    final menus = [
      _SellerMenu(
        title: 'Kelola Menu',
        subtitle: 'Tambah & edit menu kantin',
        icon: Icons.menu_book_rounded,
        color: AppColors.primary,
        route: RouteNames.sellerMenu,
      ),
      _SellerMenu(
        title: 'Pesanan Masuk',
        subtitle: pendingCount > 0
            ? '$pendingCount pesanan menunggu'
            : 'Pantau semua pesanan',
        icon: Icons.receipt_long_rounded,
        color: AppColors.secondary,
        route: RouteNames.sellerOrders,
        badge: pendingCount,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.0,
      ),
      itemCount: menus.length,
      itemBuilder: (ctx, i) => _buildMenuCard(context, menus[i]),
    );
  }

  Widget _buildMenuCard(BuildContext context, _SellerMenu menu) {
    return GestureDetector(
      onTap: () => context.push(menu.route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: menu.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(menu.icon, color: menu.color, size: 30),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    menu.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      menu.subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: menu.badge > 0
                            ? AppColors.warning
                            : AppColors.textSecondary,
                        fontWeight: menu.badge > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (menu.badge > 0)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    menu.badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari akun seller?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go(RouteNames.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool badge;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: badge
            ? Border.all(color: color.withValues(alpha: 0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _SellerMenu {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final int badge;

  const _SellerMenu({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    this.badge = 0,
  });
}
