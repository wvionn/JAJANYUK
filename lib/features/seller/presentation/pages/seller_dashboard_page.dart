import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../admin/presentation/providers/admin_provider.dart';
import '../providers/seller_provider.dart';
import '../../domain/entities/transaction_entity.dart';

class SellerDashboardPage extends ConsumerWidget {
  const SellerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.valueOrNull;
    final sellerName = currentUser?.fullName ?? currentUser?.email ?? 'Seller';

    final vendorAsync = ref.watch(vendorProfileProvider);
    final campusAsync = ref.watch(campusNotifierProvider);
    final ordersState = ref.watch(ordersNotifierProvider);
    final menuState = ref.watch(menuNotifierProvider);
    final txState = ref.watch(sellerTransactionReportProvider);


    final vendor = vendorAsync.valueOrNull;
    final campuses = campusAsync.valueOrNull ?? [];
    
    // Find campus name
    String campusName = 'Kantin Kampus';
    if (vendor != null && campuses.isNotEmpty) {
      final match = campuses.where((c) => c.id == vendor.campusId).firstOrNull;
      if (match != null) {
        campusName = match.name;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, sellerName, vendorAsync, campusName, ref),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(sellerProfileFutureProvider);
                  ref.read(ordersNotifierProvider.notifier).loadOrders();
                  ref.read(menuNotifierProvider.notifier).loadMenu();
                  ref.read(sellerTransactionReportProvider.notifier).loadReports();
                  final vId = ref.read(currentVendorIdProvider);
                  if (vId != null && vId.isNotEmpty) {
                    ref.read(vendorProfileProvider.notifier).loadVendorProfile(vId);
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shop Status Card
                      if (vendor != null) _buildStatusCard(context, vendor, ref),
                      const SizedBox(height: 16),

                      // Stats Section
                      const Text(
                        'Ringkasan Bisnis Hari Ini',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatsGrid(ordersState, menuState),
                      const SizedBox(height: 20),

                      // Sales Chart
                      if (!txState.isLoading) ...[
                        const Text(
                          'Tren Penjualan Toko',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SellerDashboardCharts(transactions: txState.transactions),
                        const SizedBox(height: 24),
                      ],

                      // Menu Utama
                      const Text(
                        'Menu Utama',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuGrid(context, ordersState),
                      const SizedBox(height: 24),
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

  Widget _buildHeader(
    BuildContext context,
    String sellerName,
    AsyncValue<dynamic> vendorAsync,
    String campusName,
    WidgetRef ref,
  ) {
    final vendor = vendorAsync.valueOrNull;
    final storeName = vendor?.name ?? 'Toko Kantin';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
      child: Column(
        children: [
          Row(
            children: [
              // Store photo/logo or fallback store icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: vendor?.logoUrl != null && vendor!.logoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          vendor.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.store_rounded,
                              color: AppColors.secondary,
                              size: 28),
                        ),
                      )
                    : const Icon(Icons.store_rounded,
                        color: AppColors.secondary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Seller: $sellerName',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.school_rounded,
                            color: Colors.white60, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            campusName,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showLogoutDialog(context, ref),
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                tooltip: 'Logout',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, dynamic vendor, WidgetRef ref) {
    final isOpen = vendor.isOpen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          Icon(
            isOpen ? Icons.check_circle_rounded : Icons.do_not_disturb_on_rounded,
            color: isOpen ? AppColors.success : AppColors.textSecondary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOpen ? 'Toko Buka' : 'Toko Tutup',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isOpen ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
                Text(
                  isOpen
                      ? 'Pelanggan dapat melakukan pesanan'
                      : 'Pelanggan tidak dapat memesan',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: isOpen,
            onChanged: (val) async {
              final err = await ref
                  .read(vendorProfileProvider.notifier)
                  .toggleOpenStatus(val);
              if (context.mounted && err != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err), backgroundColor: AppColors.error),
                );
              }
            },
            activeThumbColor: AppColors.success,
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(OrdersState ordersState, MenuState menuState) {
    final pendingCount = ordersState.countByStatus('pending');
    final processingCount = ordersState.countByStatus('processing');
    final cancelledCount = ordersState.countByStatus('cancelled');

    // Today completed count & revenue
    final today = DateTime.now();
    final completedToday = ordersState.orders.where((o) {
      if (o.orderStatus != 'completed') return false;
      final localCreated = o.createdAt.toLocal();
      return localCreated.year == today.year &&
          localCreated.month == today.month &&
          localCreated.day == today.day;
    }).toList();
    final completedCount = completedToday.length;
    final earningsToday =
        completedToday.fold<double>(0.0, (sum, o) => sum + o.totalPrice);

    final activeMenus = menuState.items.where((i) => i.isAvailable).length;

    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: [
        _StatCard(
          label: 'Pesanan Masuk',
          value: pendingCount.toString(),
          icon: Icons.receipt_outlined,
          color: AppColors.warning,
          badge: pendingCount > 0,
        ),
        _StatCard(
          label: 'Sedang Diproses',
          value: processingCount.toString(),
          icon: Icons.restaurant_outlined,
          color: AppColors.info,
        ),
        _StatCard(
          label: 'Selesai Hari Ini',
          value: completedCount.toString(),
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.success,
        ),
        _StatCard(
          label: 'Pendapatan Hari Ini',
          value: formatter.format(earningsToday),
          icon: Icons.monetization_on_outlined,
          color: const Color(0xFF10B981),
          isSmallText: true,
        ),
        _StatCard(
          label: 'Menu Aktif',
          value: '$activeMenus/${menuState.items.length}',
          icon: Icons.menu_book_outlined,
          color: AppColors.primary,
        ),
        _StatCard(
          label: 'Pesanan Batal',
          value: cancelledCount.toString(),
          icon: Icons.cancel_outlined,
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildMenuGrid(BuildContext context, OrdersState ordersState) {
    final pendingCount = ordersState.countByStatus('pending');

    final menus = [
      const _SellerMenu(
        title: 'Kelola Menu',
        subtitle: 'Atur & tambah menu kantin',
        icon: Icons.restaurant_menu_rounded,
        color: AppColors.primary,
        route: RouteNames.sellerMenu,
      ),
      _SellerMenu(
        title: 'Pesanan Masuk',
        subtitle: pendingCount > 0
            ? '$pendingCount menunggu'
            : 'Pantau pesanan baru',
        icon: Icons.assignment_rounded,
        color: AppColors.secondary,
        route: RouteNames.sellerOrders,
        badge: pendingCount,
      ),
      const _SellerMenu(
        title: 'Profil Toko',
        subtitle: 'Ubah jam & detail kedai',
        icon: Icons.storefront_rounded,
        color: Colors.teal,
        route: RouteNames.sellerProfile,
      ),
      const _SellerMenu(
        title: 'Laporan Transaksi',
        subtitle: 'Rekap penghasilan toko',
        icon: Icons.analytics_outlined,
        color: Colors.purple,
        route: RouteNames.sellerReports,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: menus.length,
      itemBuilder: (ctx, i) => _buildMenuCard(context, menus[i]),
    );
  }

  Widget _buildMenuCard(BuildContext context, _SellerMenu menu) {
    return InkWell(
      onTap: () => context.push(menu.route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: menu.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(menu.icon, color: menu.color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  menu.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  menu.subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: menu.badge > 0
                        ? AppColors.warning
                        : AppColors.textSecondary,
                    fontWeight: menu.badge > 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (menu.badge > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    menu.badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
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

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Yakin ingin keluar dari akun seller?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go(RouteNames.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
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
  final bool isSmallText;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.badge = false,
    this.isSmallText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: badge
            ? Border.all(color: color.withValues(alpha: 0.5), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmallText ? 13 : 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary, height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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

class SellerDashboardCharts extends StatefulWidget {
  final List<TransactionEntity> transactions;

  const SellerDashboardCharts({super.key, required this.transactions});

  @override
  State<SellerDashboardCharts> createState() => _SellerDashboardChartsState();
}

class _SellerDashboardChartsState extends State<SellerDashboardCharts>
    with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  String _selectedRange = '7days'; // '7days', '30days', 'custom'
  DateTimeRange? _customDateRange;
  late PageController _pageController;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuart,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _triggerAnimation() {
    _animController.reset();
    _animController.forward();
  }

  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.secondary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedRange = 'custom';
        _customDateRange = picked;
      });
      _triggerAnimation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (_selectedRange == '30days') {
      startDate = now.subtract(const Duration(days: 29));
      startDate = DateTime(startDate.year, startDate.month, startDate.day);
    } else if (_selectedRange == 'custom' && _customDateRange != null) {
      startDate = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
      endDate = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
    } else {
      startDate = now.subtract(const Duration(days: 6));
      startDate = DateTime(startDate.year, startDate.month, startDate.day);
    }

    final int daysCount = endDate.difference(startDate).inDays + 1;
    final List<DateTime> dates = List.generate(
      daysCount,
      (index) => startDate.add(Duration(days: index)),
    );

    final totalData = <String, int>{};
    final qrisData = <String, int>{};
    final cashData = <String, int>{};

    for (final d in dates) {
      final key = DateFormat('yyyy-MM-dd').format(d);
      totalData[key] = 0;
      qrisData[key] = 0;
      cashData[key] = 0;
    }

    for (final r in widget.transactions) {
      final key = DateFormat('yyyy-MM-dd').format(r.createdAt.toLocal());
      if (totalData.containsKey(key)) {
        totalData[key] = totalData[key]! + 1;
        if (r.paymentMethod.toLowerCase() == 'qris') {
          qrisData[key] = qrisData[key]! + 1;
        } else {
          cashData[key] = cashData[key]! + 1;
        }
      }
    }

    int maxVal = 5;
    if (_currentPage == 0) {
      for (final val in totalData.values) {
        if (val > maxVal) maxVal = val;
      }
    } else {
      for (final val in qrisData.values) {
        if (val > maxVal) maxVal = val;
      }
      for (final val in cashData.values) {
        if (val > maxVal) maxVal = val;
      }
    }
    maxVal = ((maxVal + 4) ~/ 5) * 5;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildRangeChip('7 Hari', '7days'),
              const SizedBox(width: 8),
              _buildRangeChip('30 Hari', '30days'),
              const SizedBox(width: 8),
              _buildRangeChip(
                _selectedRange == 'custom' && _customDateRange != null
                    ? '${DateFormat('dd/MM').format(_customDateRange!.start)}-${DateFormat('dd/MM').format(_customDateRange!.end)}'
                    : 'Kustom',
                'custom',
                onTap: _selectCustomRange,
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 200,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                _triggerAnimation();
              },
              children: [
                _buildChartSlide(
                  title: 'Banyak Transaksi',
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, _) => CustomPaint(
                      size: Size.infinite,
                      painter: SellerChartPainter(
                        dates: dates,
                        singleData: totalData,
                        maxVal: maxVal,
                        animationValue: _animation.value,
                      ),
                    ),
                  ),
                ),
                _buildChartSlide(
                  title: 'Metode Pembayaran',
                  legend: Row(
                    children: [
                      _legendItem('QRIS', Colors.blue),
                      const SizedBox(width: 10),
                      _legendItem('Tunai', Colors.orange),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, _) => CustomPaint(
                      size: Size.infinite,
                      painter: SellerChartPainter(
                        dates: dates,
                        qrisData: qrisData,
                        cashData: cashData,
                        maxVal: maxVal,
                        animationValue: _animation.value,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) => _buildIndicatorDot(index)),
          ),

        ],
      ),
    );
  }

  Widget _buildRangeChip(String label, String value, {VoidCallback? onTap}) {
    final isSelected = _selectedRange == value;
    return GestureDetector(
      onTap: onTap ?? () {
        if (_selectedRange != value) {
          setState(() {
            _selectedRange = value;
          });
          _triggerAnimation();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.secondary.withValues(alpha: 0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.secondary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildChartSlide({
    required String title,
    Widget? legend,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            if (legend != null) legend,
          ],
        ),
        const SizedBox(height: 12),
        Expanded(child: child),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildIndicatorDot(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: isActive ? 14 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? AppColors.secondary : Colors.grey[300],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class SellerChartPainter extends CustomPainter {
  final List<DateTime> dates;
  final Map<String, int>? singleData;
  final Map<String, int>? qrisData;
  final Map<String, int>? cashData;
  final int maxVal;
  final double animationValue;

  SellerChartPainter({
    required this.dates,
    this.singleData,
    this.qrisData,
    this.cashData,
    required this.maxVal,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    const double paddingLeft = 20.0;
    const double paddingBottom = 20.0;
    const double paddingTop = 10.0;
    const double paddingRight = 10.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    final int divisions = 4;
    for (int i = 0; i <= divisions; i++) {
      final double y = paddingTop + chartHeight - (i * chartHeight / divisions);
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      final int value = (i * maxVal / divisions).round();
      textPainter.text = TextSpan(
        text: value.toString(),
        style: TextStyle(color: Colors.grey[500], fontSize: 8, fontWeight: FontWeight.w500),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    final double stepX = chartWidth / (dates.length - 1);
    for (int i = 0; i < dates.length; i++) {
      final double x = paddingLeft + (i * stepX);
      
      canvas.drawLine(
        Offset(x, paddingTop),
        Offset(x, paddingTop + chartHeight),
        gridPaint,
      );

      bool shouldDrawLabel = false;
      if (dates.length <= 7) {
        shouldDrawLabel = true;
      } else if (dates.length <= 15) {
        shouldDrawLabel = i % 2 == 0;
      } else {
        shouldDrawLabel = i % 5 == 0 || i == dates.length - 1;
      }

      if (shouldDrawLabel) {
        final date = dates[i];
        textPainter.text = TextSpan(
          text: DateFormat('dd/MM').format(date),
          style: TextStyle(color: Colors.grey[500], fontSize: 8, fontWeight: FontWeight.w500),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, paddingTop + chartHeight + 6),
        );
      }
    }

    if (singleData != null) {
      _drawLine(
        canvas,
        stepX,
        paddingLeft,
        paddingTop,
        chartHeight,
        singleData!,
        AppColors.secondary,
        AppColors.secondary.withValues(alpha: 0.08),
      );
    } else {
      if (qrisData != null) {
        _drawLine(
          canvas,
          stepX,
          paddingLeft,
          paddingTop,
          chartHeight,
          qrisData!,
          Colors.blue,
          Colors.blue.withValues(alpha: 0.08),
        );
      }
      if (cashData != null) {
        _drawLine(
          canvas,
          stepX,
          paddingLeft,
          paddingTop,
          chartHeight,
          cashData!,
          Colors.orange,
          Colors.orange.withValues(alpha: 0.08),
        );
      }
    }
  }

  void _drawLine(
    Canvas canvas,
    double stepX,
    double paddingLeft,
    double paddingTop,
    double chartHeight,
    Map<String, int> data,
    Color strokeColor,
    Color fillColor,
  ) {
    final path = Path();
    final fillPath = Path();
    final List<Offset> points = [];

    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final val = data[dateStr] ?? 0;
      final double x = paddingLeft + (i * stepX);
      final double y = paddingTop + chartHeight - (val * chartHeight / maxVal) * animationValue;
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, paddingTop + chartHeight);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawPath(path, linePaint);

    final dotOuterPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;
    final dotInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final p in points) {
      canvas.drawCircle(p, 3.5, dotOuterPaint);
      canvas.drawCircle(p, 1.5, dotInnerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SellerChartPainter oldDelegate) {
    return oldDelegate.dates != dates ||
        oldDelegate.singleData != singleData ||
        oldDelegate.qrisData != qrisData ||
        oldDelegate.cashData != cashData ||
        oldDelegate.maxVal != maxVal ||
        oldDelegate.animationValue != animationValue;
  }
}
