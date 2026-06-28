import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../user/presentation/providers/cart_provider.dart';
import '../../../../core/theme/app_colors.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  DateTime _selectedDate = DateTime.now();
  // 0 = Harian, 1 = Mingguan, 2 = Bulanan
  int _viewMode = 2;
  bool _isCountMetric = true;
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
        title: const Text('Analisis Pembelian',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(orderHistoryProvider),
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
          final filteredOrders = _filterOrders(orders);
          double totalSpent = filteredOrders.fold(0.0, (sum, o) => sum + o.totalPrice);
          int totalTransactions = filteredOrders.length;
          final chartData = _generateChartData(orders);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSelectors(context),
                const SizedBox(height: 20),
                _buildSummaryCards(totalSpent, totalTransactions),
                const SizedBox(height: 24),
                _buildChartSection(chartData),
                const SizedBox(height: 24),
                _buildDetailsSection(filteredOrders),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  List<dynamic> _filterOrders(List<dynamic> orders) {
    return orders.where((order) {
      final dt = (order.createdAt as DateTime).toLocal();
      if (_viewMode == 0) {
        // Harian: filter by exact date
        return dt.year == _selectedDate.year &&
            dt.month == _selectedDate.month &&
            dt.day == _selectedDate.day;
      } else if (_viewMode == 1) {
        // Mingguan: filter by week in selected month
        return dt.year == _selectedDate.year &&
            dt.month == _selectedDate.month;
      } else {
        // Bulanan: filter by year
        return dt.year == _selectedDate.year;
      }
    }).toList();
  }

  List<ChartDataPoint> _generateChartData(List<dynamic> allOrders) {
    final List<ChartDataPoint> data = [];

    if (_viewMode == 0) {
      // Harian: tampilkan per jam (0-23)
      final dayOrders = allOrders.where((o) {
        final dt = o.createdAt as DateTime;
        return dt.year == _selectedDate.year &&
            dt.month == _selectedDate.month &&
            dt.day == _selectedDate.day;
      }).toList();

      for (int h = 0; h < 24; h++) {
        final hourOrders = dayOrders.where((o) => (o.createdAt as DateTime).hour == h).toList();
        data.add(ChartDataPoint(
          label: '$h',
          count: hourOrders.length.toDouble(),
          spent: hourOrders.fold(0.0, (sum, o) => sum + o.totalPrice),
          subtitle: 'Jam $h:00 - ${h + 1}:00',
          rawOrdersCount: hourOrders.length,
        ));
      }
    } else if (_viewMode == 1) {
      // Mingguan: tampilkan per minggu dalam bulan
      final monthOrders = allOrders.where((o) {
        final dt = o.createdAt as DateTime;
        return dt.year == _selectedDate.year && dt.month == _selectedDate.month;
      }).toList();

      final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
      int weekNum = 1;
      for (int startDay = 1; startDay <= daysInMonth; startDay += 7) {
        final endDay = (startDay + 6).clamp(1, daysInMonth);
        final weekOrders = monthOrders.where((o) {
          final day = (o.createdAt as DateTime).day;
          return day >= startDay && day <= endDay;
        }).toList();
        data.add(ChartDataPoint(
          label: 'M$weekNum',
          count: weekOrders.length.toDouble(),
          spent: weekOrders.fold(0.0, (sum, o) => sum + o.totalPrice),
          subtitle: 'Minggu $weekNum ($startDay-$endDay ${_monthsName[_selectedDate.month - 1]})',
          rawOrdersCount: weekOrders.length,
        ));
        weekNum++;
      }
    } else {
      // Bulanan: per bulan dalam tahun
      final yearOrders = allOrders.where((o) =>
          (o.createdAt as DateTime).year == _selectedDate.year).toList();

      for (int i = 1; i <= 12; i++) {
        final monthOrders = yearOrders.where((o) =>
            (o.createdAt as DateTime).month == i).toList();
        data.add(ChartDataPoint(
          label: _monthsName[i - 1].substring(0, 3),
          count: monthOrders.length.toDouble(),
          spent: monthOrders.fold(0.0, (sum, o) => sum + o.totalPrice),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // 3 mode toggle
          Row(
            children: [
              Expanded(child: _buildToggleButton(isActive: _viewMode == 0, label: 'Harian', icon: Icons.today, onTap: () => setState(() { _viewMode = 0; _selectedBarIndex = null; }))),
              const SizedBox(width: 6),
              Expanded(child: _buildToggleButton(isActive: _viewMode == 1, label: 'Mingguan', icon: Icons.view_week, onTap: () => setState(() { _viewMode = 1; _selectedBarIndex = null; }))),
              const SizedBox(width: 6),
              Expanded(child: _buildToggleButton(isActive: _viewMode == 2, label: 'Bulanan', icon: Icons.calendar_month, onTap: () => setState(() { _viewMode = 2; _selectedBarIndex = null; }))),
            ],
          ),
          const Divider(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _viewMode == 0 ? 'Tanggal' : _viewMode == 1 ? 'Bulan & Tahun' : 'Tahun',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _viewMode == 0
                        ? DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate)
                        : _viewMode == 1
                            ? '${_monthsName[_selectedDate.month - 1]} ${_selectedDate.year}'
                            : '${_selectedDate.year}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _selectPeriod(context),
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(_viewMode == 0 ? 'Ubah Tanggal' : _viewMode == 1 ? 'Ubah Bulan' : 'Ubah Tahun'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({required bool isActive, required String label, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? AppColors.primary : Colors.grey[300]!, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: isActive ? AppColors.primary : Colors.grey[600]),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? AppColors.primary : Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double totalSpent, int totalTransactions) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.orange, size: 20)),
              const SizedBox(height: 12),
              const Text('Total Belanja', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(currencyFormatter.format(totalSpent), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.shopping_bag, color: Colors.green, size: 20)),
              const SizedBox(height: 12),
              const Text('Total Pembelian', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text('$totalTransactions Transaksi', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(List<ChartDataPoint> chartData) {
    double maxValue = chartData.fold(0.0, (max, pt) {
      final val = _isCountMetric ? pt.count : pt.spent;
      return val > max ? val : max;
    });
    if (maxValue == 0) maxValue = 1.0;

    final hasData = chartData.any((pt) => (_isCountMetric ? pt.count : pt.spent) > 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _isCountMetric ? 'Grafik Jumlah Pembelian' : 'Grafik Total Belanja',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              PopupMenuButton<bool>(
                initialValue: _isCountMetric,
                onSelected: (val) => setState(() { _isCountMetric = val; _selectedBarIndex = null; }),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: true, child: Text('Jumlah Transaksi')),
                  const PopupMenuItem(value: false, child: Text('Total Pengeluaran')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    Text(_isCountMetric ? 'Transaksi' : 'Pengeluaran', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const Icon(Icons.arrow_drop_down, size: 16),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: !hasData
                ? const Center(child: Text('Tidak ada data pada periode ini.', style: TextStyle(color: Colors.grey)))
                : Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_formatYLabel(maxValue), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(_formatYLabel(maxValue * 0.75), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(_formatYLabel(maxValue * 0.5), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(_formatYLabel(maxValue * 0.25), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          const Text('0', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 40),
                        ],
                      ),
                      const SizedBox(width: 8),
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
                                  final double barMaxHeight = constraints.maxHeight - 50;
                                  final double barHeight = value == 0 ? 2 : (value / maxValue * barMaxHeight).clamp(2.0, barMaxHeight);

                                  return GestureDetector(
                                    onTap: () => setState(() {
                                      _selectedBarIndex = _selectedBarIndex == index ? null : index;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      color: Colors.transparent,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (isSelected)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                              margin: const EdgeInsets.only(bottom: 4),
                                              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                                              child: Text(
                                                _isCountMetric ? '${value.toInt()} Transaksi' : currencyFormatter.format(value),
                                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                              ),
                                            )
                                          else
                                            const SizedBox(height: 20),
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
                                          const SizedBox(height: 4),
                                          Text(pt.label, style: TextStyle(fontSize: 9, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppColors.primary : Colors.grey[600])),
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
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Detail ${chartData[_selectedBarIndex!].subtitle}: ${chartData[_selectedBarIndex!].rawOrdersCount} transaksi (${currencyFormatter.format(chartData[_selectedBarIndex!].spent)})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatYLabel(double val) {
    if (_isCountMetric) return val.toInt().toString();
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(0)}K';
    return val.toInt().toString();
  }

  Widget _buildDetailsSection(List<dynamic> filteredOrders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Detail Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${filteredOrders.length} Pesanan', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 12),
        if (filteredOrders.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Tidak ada transaksi.', style: TextStyle(color: Colors.grey))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredOrders.length > 10 ? 10 : filteredOrders.length,
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
                        Text('Pesanan #${order.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                    Text(currencyFormatter.format(order.totalPrice),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                  ],
                ),
              );
            },
          ),
        if (filteredOrders.length > 10) ...[
          const SizedBox(height: 8),
          Center(child: Text('*Menampilkan 10 pesanan terakhir', style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic))),
        ],
      ],
    );
  }

  Future<void> _selectPeriod(BuildContext context) async {
    if (_viewMode == 0) {
      // Pilih tanggal spesifik
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        setState(() { _selectedDate = picked; _selectedBarIndex = null; });
      }
    } else if (_viewMode == 1) {
      // Pilih bulan & tahun
      int tempYear = _selectedDate.year;
      int tempMonth = _selectedDate.month;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pilih Bulan & Tahun'),
          content: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tahun:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(children: [
                      IconButton(icon: const Icon(Icons.remove), onPressed: () => setDialogState(() => tempYear--)),
                      Text('$tempYear', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.add), onPressed: () => setDialogState(() => tempYear++)),
                    ]),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                SizedBox(
                  width: 280,
                  height: 180,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final isSelected = tempMonth == (index + 1);
                      return GestureDetector(
                        onTap: () => setDialogState(() => tempMonth = index + 1),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: isSelected ? AppColors.primary : Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                          child: Text(_monthsName[index].substring(0, 3), style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                setState(() { _selectedDate = DateTime(tempYear, tempMonth); _selectedBarIndex = null; });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Pilih', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      // Pilih tahun
      int tempYear = _selectedDate.year;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pilih Tahun'),
          content: StatefulBuilder(
            builder: (context, setDialogState) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.remove), onPressed: () => setDialogState(() => tempYear--)),
                const SizedBox(width: 16),
                Text('$tempYear', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                IconButton(icon: const Icon(Icons.add), onPressed: () => setDialogState(() => tempYear++)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                setState(() { _selectedDate = DateTime(tempYear, _selectedDate.month); _selectedBarIndex = null; });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Pilih', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
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