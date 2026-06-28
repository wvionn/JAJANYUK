import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';
import '../../../../core/theme/app_colors.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  DateTime _selectedDate = DateTime.now();
  bool _isDailyView = true; // true = Daily, false = Monthly
  bool _isCountMetric = true; // true = Jumlah Pembelian, false = Total Pengeluaran
  int? _selectedBarIndex;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final List<String> _monthsName = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Analisis Pembelian',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(orderHistoryProvider);
            },
          )
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Gagal memuat data: $err'),
            ],
          ),
        ),
        data: (orders) {
          // Filter orders for the selected period
          final filteredOrders = orders.where((order) {
            if (_isDailyView) {
              // Daily view filters by the selected month and year
              return order.createdAt.month == _selectedDate.month &&
                  order.createdAt.year == _selectedDate.year;
            } else {
              // Monthly view filters by the selected year
              return order.createdAt.year == _selectedDate.year;
            }
          }).toList();

          // Calculate summary statistics
          double totalSpent = 0;
          int totalTransactions = filteredOrders.length;
          for (final order in filteredOrders) {
            totalSpent += order.totalPrice;
          }

          // Build chart data
          final List<ChartDataPoint> chartData = _generateChartData(filteredOrders);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Selector Section (Time & View Mode Toggle)
                _buildSelectors(context),
                const SizedBox(height: 20),

                // 2. Summary Cards
                _buildSummaryCards(totalSpent, totalTransactions),
                const SizedBox(height: 24),

                // 3. Chart Container
                _buildChartSection(chartData),
                const SizedBox(height: 24),

                // 4. Detail Order List of selected timeframe
                _buildDetailsSection(filteredOrders),
              ],
            ),
          );
        },
      ),
    );
  }

  // Generate chart datapoints based on filters
  List<ChartDataPoint> _generateChartData(List<dynamic> filteredOrders) {
    final List<ChartDataPoint> data = [];

    if (_isDailyView) {
      // Days in the selected month
      final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        final dayOrders = filteredOrders.where((o) => o.createdAt.day == i).toList();
        final double count = dayOrders.length.toDouble();
        final double spent = dayOrders.fold(0.0, (sum, o) => sum + o.totalPrice);

        data.add(ChartDataPoint(
          label: i.toString(),
          count: count,
          spent: spent,
          subtitle: '${i} ${_monthsName[_selectedDate.month - 1]}',
          rawOrdersCount: dayOrders.length,
        ));
      }
    } else {
      // Months in the selected year
      for (int i = 1; i <= 12; i++) {
        final monthOrders = filteredOrders.where((o) => o.createdAt.month == i).toList();
        final double count = monthOrders.length.toDouble();
        final double spent = monthOrders.fold(0.0, (sum, o) => sum + o.totalPrice);

        data.add(ChartDataPoint(
          label: _monthsName[i - 1].substring(0, 3),
          count: count,
          spent: spent,
          subtitle: '${_monthsName[i - 1]} ${_selectedDate.year}',
          rawOrdersCount: monthOrders.length,
        ));
      }
    }

    return data;
  }

  Widget _buildSelectors(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Timeframe Type: Daily / Monthly Toggle
          Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  isActive: _isDailyView,
                  label: 'Harian (Per Bulan)',
                  icon: Icons.calendar_view_day,
                  onTap: () {
                    setState(() {
                      _isDailyView = true;
                      _selectedBarIndex = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildToggleButton(
                  isActive: !_isDailyView,
                  label: 'Bulanan (Per Tahun)',
                  icon: Icons.calendar_view_month,
                  onTap: () {
                    setState(() {
                      _isDailyView = false;
                      _selectedBarIndex = null;
                    });
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Date / Period Picker trigger
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isDailyView ? 'Periode Bulan' : 'Periode Tahun',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isDailyView
                        ? '${_monthsName[_selectedDate.month - 1]} ${_selectedDate.year}'
                        : '${_selectedDate.year}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _selectPeriod(context),
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(_isDailyView ? 'Ubah Bulan' : 'Ubah Tahun'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required bool isActive,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppColors.primary : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppColors.primary : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double totalSpent, int totalTransactions) {
    return Row(
      children: [
        // Total Spent Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.orange, size: 20),
                ),
                const SizedBox(height: 12),
                const Text('Total Belanja', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  currencyFormatter.format(totalSpent),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Total Transactions Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shopping_bag, color: Colors.green, size: 20),
                ),
                const SizedBox(height: 12),
                const Text('Total Pembelian', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  '$totalTransactions Transaksi',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(List<ChartDataPoint> chartData) {
    // Find max value in data to scale the heights
    double maxValue = 0;
    for (final pt in chartData) {
      final double val = _isCountMetric ? pt.count : pt.spent;
      if (val > maxValue) maxValue = val;
    }
    if (maxValue == 0) maxValue = 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metric type toggler & Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isCountMetric ? 'Grafik Jumlah Pembelian' : 'Grafik Total Belanja',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              // Mini dropdown/toggle for metric
              PopupMenuButton<bool>(
                initialValue: _isCountMetric,
                onSelected: (val) {
                  setState(() {
                    _isCountMetric = val;
                    _selectedBarIndex = null;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: true,
                    child: Text('Jumlah Transaksi (Kali)'),
                  ),
                  const PopupMenuItem(
                    value: false,
                    child: Text('Total Pengeluaran (Rupiah)'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _isCountMetric ? 'Transaksi' : 'Pengeluaran',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Interactive Graph Component
          SizedBox(
            height: 220,
            child: chartData.isEmpty || (chartData.every((element) => (_isCountMetric ? element.count : element.spent) == 0))
                ? const Center(
                    child: Text(
                      'Tidak ada data pembelian pada periode ini.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : Row(
                    children: [
                      // Y Axis scale indicators
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_formatYLabel(maxValue), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(_formatYLabel(maxValue * 0.75), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(_formatYLabel(maxValue * 0.5), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(_formatYLabel(maxValue * 0.25), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          const Text('0', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 18), // Placeholder to align with X labels
                        ],
                      ),
                      const SizedBox(width: 8),

                      // Chart bars area
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(chartData.length, (index) {
                                  final pt = chartData[index];
                                  final double value = _isCountMetric ? pt.count : pt.spent;
                                  final isSelected = _selectedBarIndex == index;
                                  final double percentage = value / maxValue;
                                  // Max height is constraint height minus labels
                                  final double barMaxHeight = constraints.maxHeight - 32;
                                  final double barHeight = (percentage * barMaxHeight).clamp(4.0, barMaxHeight);

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (_selectedBarIndex == index) {
                                          _selectedBarIndex = null;
                                        } else {
                                          _selectedBarIndex = index;
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      color: Colors.transparent,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          // Tooltip if selected
                                          if (isSelected)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                              margin: const EdgeInsets.only(bottom: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.black87,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                _isCountMetric
                                                    ? '${value.toInt()} Transaksi'
                                                    : currencyFormatter.format(value),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                          else
                                            const SizedBox(height: 18),

                                          // Bar
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            width: 14,
                                            height: barHeight,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isSelected
                                                    ? [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)]
                                                    : [Colors.blue[300]!, Colors.blue[100]!],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(height: 6),

                                          // Label
                                          Text(
                                            pt.label,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? AppColors.primary : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          if (_selectedBarIndex != null && _selectedBarIndex! < chartData.length) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Detail ${chartData[_selectedBarIndex!].subtitle}: '
                    '${chartData[_selectedBarIndex!].rawOrdersCount} transaksi '
                    '(total ${currencyFormatter.format(chartData[_selectedBarIndex!].spent)})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            )
          ],
        ],
      ),
    );
  }

  String _formatYLabel(double val) {
    if (_isCountMetric) {
      return val.toInt().toString();
    } else {
      if (val >= 1000000) {
        return '${(val / 1000000).toStringAsFixed(1)}M';
      } else if (val >= 1000) {
        return '${(val / 1000).toStringAsFixed(0)}K';
      }
      return val.toInt().toString();
    }
  }

  Widget _buildDetailsSection(List<dynamic> filteredOrders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Detail Pesanan Periode Ini',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${filteredOrders.length} Pesanan',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filteredOrders.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Tidak ada transaksi.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredOrders.length > 5 ? 5 : filteredOrders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final order = filteredOrders[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pesanan #${order.id.substring(0, 8)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt),
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                    Text(
                      currencyFormatter.format(order.totalPrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        if (filteredOrders.length > 5) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              '*Menampilkan 5 pesanan terakhir',
              style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
            ),
          ),
        ]
      ],
    );
  }

  // Show dialog to choose Month/Year or Year depending on view mode
  Future<void> _selectPeriod(BuildContext context) async {
    if (_isDailyView) {
      // Choose Month and Year
      int tempYear = _selectedDate.year;
      int tempMonth = _selectedDate.month;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Pilih Bulan & Tahun'),
            content: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Year selection row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tahun:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                setDialogState(() => tempYear--);
                              },
                            ),
                            Text('$tempYear', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setDialogState(() => tempYear++);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Months grid
                    SizedBox(
                      width: 280,
                      height: 180,
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final isSelected = tempMonth == (index + 1);
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                tempMonth = index + 1;
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _monthsName[index].substring(0, 3),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(tempYear, tempMonth);
                    _selectedBarIndex = null;
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Pilih', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    } else {
      // Choose Year only
      int tempYear = _selectedDate.year;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Pilih Tahun'),
            content: StatefulBuilder(
              builder: (context, setDialogState) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        setDialogState(() => tempYear--);
                      },
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$tempYear',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setDialogState(() => tempYear++);
                      },
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(tempYear, _selectedDate.month);
                    _selectedBarIndex = null;
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Pilih', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }
  }
}

class ChartDataPoint {
  final String label;
  final double count;
  final double spent;
  final String subtitle;
  final int rawOrdersCount;

  ChartDataPoint({
    required this.label,
    required this.count,
    required this.spent,
    required this.subtitle,
    required this.rawOrdersCount,
  });
}
