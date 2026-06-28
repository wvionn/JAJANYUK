import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/transaction_report_entity.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_stat_card.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(platformStatsProvider);
    final reportState = ref.watch(transactionReportNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, ref),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(platformStatsProvider);
                  await ref.read(transactionReportNotifierProvider.notifier).loadReports();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Grid
                      statsAsync.when(
                        loading: () => _buildStatsLoading(),
                        error: (_, __) => _buildStatsError(ref),
                        data: (stats) => Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AdminStatCard(
                                    label: 'Total Seller',
                                    value: stats.totalSellers.toString(),
                                    icon: Icons.store_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AdminStatCard(
                                    label: 'Total Pembeli',
                                    value: stats.totalBuyers.toString(),
                                    icon: Icons.people_rounded,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: AdminStatCard(
                                    label: 'Total Order',
                                    value: stats.totalOrders.toString(),
                                    icon: Icons.receipt_long_rounded,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AdminStatCard(
                                    label: 'Kampus',
                                    value: stats.totalCampuses.toString(),
                                    icon: Icons.school_rounded,
                                    color: AppColors.info,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Platform Sales Chart
                      const Text(
                        'Tren Penjualan Platform',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!reportState.isLoading)
                        AdminDashboardCharts(reports: reportState.reports)
                      else
                        const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      const SizedBox(height: 28),

                      // Menu Section
                      const Text(
                        'Menu Utama',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMenuGrid(context),
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

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final displayName = user?.fullName ?? user?.email ?? 'Admin';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
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
            child: const Icon(Icons.admin_panel_settings,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat Datang',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Administrator JAJANYUK',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
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
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    final menus = [
      _AdminMenu(
        title: 'Kelola User',
        subtitle: 'Lihat & atur data pengguna',
        icon: Icons.manage_accounts_rounded,
        color: AppColors.primary,
        route: RouteNames.adminUsers,
      ),
      _AdminMenu(
        title: 'Kelola Kantin',
        subtitle: 'Daftar & atur seller kantin',
        icon: Icons.store_rounded,
        color: AppColors.secondary,
        route: RouteNames.adminSellers,
      ),
      _AdminMenu(
        title: 'Laporan Transaksi',
        subtitle: 'Pantau riwayat transaksi',
        icon: Icons.bar_chart_rounded,
        color: AppColors.success,
        route: RouteNames.adminTransactions,
      ),
      _AdminMenu(
        title: 'Cabang Kampus',
        subtitle: 'Kelola lokasi kampus',
        icon: Icons.school_rounded,
        color: AppColors.info,
        route: RouteNames.adminCampuses,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return _buildMenuCard(context, menu);
      },
    );
  }

  Widget _buildMenuCard(BuildContext context, _AdminMenu menu) {
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
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                menu.subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsLoading() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _shimmerCard()),
            const SizedBox(width: 12),
            Expanded(child: _shimmerCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _shimmerCard()),
            const SizedBox(width: 12),
            Expanded(child: _shimmerCard()),
          ],
        ),
      ],
    );
  }

  Widget _shimmerCard() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildStatsError(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Gagal memuat statistik',
                style: TextStyle(color: AppColors.error)),
          ),
          TextButton(
            onPressed: () => ref.invalidate(platformStatsProvider),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Apakah kamu yakin ingin keluar dari akun admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authStateProvider.notifier).logout();
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

class _AdminMenu {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _AdminMenu({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class AdminDashboardCharts extends StatefulWidget {
  final List<TransactionReportEntity> reports;

  const AdminDashboardCharts({super.key, required this.reports});

  @override
  State<AdminDashboardCharts> createState() => _AdminDashboardChartsState();
}

class _AdminDashboardChartsState extends State<AdminDashboardCharts>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animController;
  late Animation<double> _animation;

  int _currentPage = 0;
  String _selectedRange = '7days';
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
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
              primary: AppColors.primary,
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

    for (final r in widget.reports) {
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
                  title: 'Total Transaksi Platform',
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, _) => CustomPaint(
                      painter: AdminChartPainter(
                        dates: dates,
                        singleData: totalData,
                        maxVal: maxVal,
                        animationValue: _animation.value,
                      ),
                    ),
                  ),
                ),
                _buildChartSlide(
                  title: 'Metode Pembayaran Platform',
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
                      painter: AdminChartPainter(
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
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
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
        color: isActive ? AppColors.primary : Colors.grey[300],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class AdminChartPainter extends CustomPainter {
  final List<DateTime> dates;
  final Map<String, int>? singleData;
  final Map<String, int>? qrisData;
  final Map<String, int>? cashData;
  final int maxVal;
  final double animationValue;

  AdminChartPainter({
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
      ..color = Colors.grey[150]!
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

    // Draw horizontal grid lines and Y axis labels
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
        AppColors.primary,
        AppColors.primary.withValues(alpha: 0.08),
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
  bool shouldRepaint(covariant AdminChartPainter oldDelegate) {
    return oldDelegate.dates != dates ||
        oldDelegate.singleData != singleData ||
        oldDelegate.qrisData != qrisData ||
        oldDelegate.cashData != cashData ||
        oldDelegate.maxVal != maxVal ||
        oldDelegate.animationValue != animationValue;
  }
}
