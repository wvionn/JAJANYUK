import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/transaction_entity.dart';
import '../providers/seller_provider.dart';

class SellerReportsPage extends ConsumerWidget {
  const SellerReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sellerTransactionReportProvider);
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

    // Calculate today's stats from transaction list
    final today = DateTime.now();
    final todayTxs = state.transactions.where((tx) {
      final date = tx.transactionDate;
      return date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    }).toList();

    final todayCompleted = todayTxs
        .where((tx) => tx.paymentStatus == 'paid' || tx.orderStatus == 'completed')
        .toList();

    final todayRevenue = todayCompleted.fold<double>(
        0.0, (sum, tx) => sum + tx.totalAmount);

    // Filter overall counts for the cards
    final totalCompletedCount = state.transactions
        .where((tx) => tx.orderStatus == 'completed' || tx.paymentStatus == 'paid')
        .length;
    final totalCancelledCount = state.transactions
        .where((tx) => tx.orderStatus == 'cancelled' || tx.paymentStatus == 'failed')
        .length;

    final filterStatusChips = [
      {'label': 'Semua', 'value': 'all'},
      {'label': 'Berhasil', 'value': 'paid'},
      {'label': 'Menunggu', 'value': 'pending'},
      {'label': 'Gagal/Batal', 'value': 'failed'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Transaksi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Stat Highlights Card Section
          _buildStatsCards(
            todayTransactions: todayTxs.length,
            todayRevenue: todayRevenue,
            totalCompleted: totalCompletedCount,
            totalCancelled: totalCancelledCount,
            formatter: formatter,
          ),
          
          // Filters Area (Date range & Payment Status)
          _buildFiltersArea(context, state, filterStatusChips, ref),

          // Transaction list
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? _buildError(state.error!, ref)
                    : state.transactions.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(sellerTransactionReportProvider.notifier)
                                .loadReports(),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: state.transactions.length,
                              itemBuilder: (ctx, i) => _TransactionCard(
                                tx: state.transactions[i],
                                formatter: formatter,
                                dateFormatter: dateFormatter,
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards({
    required int todayTransactions,
    required double todayRevenue,
    required int totalCompleted,
    required int totalCancelled,
    required NumberFormat formatter,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Today's main summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B8DEE), Color(0xFF7BA5F4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pendapatan Hari Ini',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(todayRevenue),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transaksi Hari Ini: $todayTransactions',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.trending_up_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Additional stats counters (Completed / Cancelled)
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  'Pesanan Selesai',
                  totalCompleted.toString(),
                  AppColors.success,
                  Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStatCard(
                  'Pesanan Dibatalkan',
                  totalCancelled.toString(),
                  AppColors.error,
                  Icons.cancel_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersArea(
    BuildContext context,
    SellerTransactionState state,
    List<Map<String, String>> chips,
    WidgetRef ref,
  ) {
    final hasActiveDates = state.startDate != null || state.endDate != null;
    final dateRangeLabel = hasActiveDates
        ? '${DateFormat('dd/MM').format(state.startDate!)} - ${DateFormat('dd/MM').format(state.endDate!)}'
        : 'Pilih Tanggal';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Date Range picker & Clear dates button row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDateRange(context, state, ref),
                  icon: const Icon(Icons.date_range_outlined, size: 16),
                  label: Text(dateRangeLabel, style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (hasActiveDates) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => ref
                      .read(sellerTransactionReportProvider.notifier)
                      .clearFilters(),
                  icon: const Icon(Icons.clear_all_rounded, color: AppColors.error),
                  tooltip: 'Reset Filter',
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // Status Chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: chips.map((c) {
                final isSelected = state.filterStatus == c['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c['label']!),
                    selected: isSelected,
                    onSelected: (_) => ref
                        .read(sellerTransactionReportProvider.notifier)
                        .setFilter(c['value']!),
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(
    BuildContext context,
    SellerTransactionState state,
    WidgetRef ref,
  ) async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: state.startDate != null && state.endDate != null
          ? DateTimeRange(start: state.startDate!, end: state.endDate!)
          : null,
      builder: (ctx, child) {
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

    if (selected != null) {
      ref
          .read(sellerTransactionReportProvider.notifier)
          .setDateRange(selected.start, selected.end);
    }
  }

  Widget _buildError(String message, WidgetRef ref) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: AppColors.textSecondary)),
            TextButton(
              onPressed: () => ref
                  .read(sellerTransactionReportProvider.notifier)
                  .loadReports(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.query_stats_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text(
              'Tidak ada transaksi ditemukan',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const Text(
              'Sesuaikan filter atau tanggal pencarian',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
}

class _TransactionCard extends StatelessWidget {
  final TransactionEntity tx;
  final NumberFormat formatter;
  final DateFormat dateFormatter;

  const _TransactionCard({
    required this.tx,
    required this.formatter,
    required this.dateFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(tx.paymentStatus);
    final statusLabel = _statusLabel(tx.paymentStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: ID, Date, Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ID: TX-${tx.id.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateFormatter.format(tx.transactionDate),
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // Row 2: Customer Name, Payment Method, Amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pembeli', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    Text(
                      tx.buyerName ?? 'Pelanggan',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Metode', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  Text(
                    tx.paymentMethod.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Nominal', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  Text(
                    formatter.format(tx.totalAmount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (tx.orderStatus != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('Status Order: ', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                Text(
                  _orderStatusLabel(tx.orderStatus!),
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.w600,
                    color: _orderStatusColor(tx.orderStatus!),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
      default:
        return AppColors.error;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Berhasil';
      case 'pending':
        return 'Menunggu';
      case 'failed':
      default:
        return 'Gagal/Batal';
    }
  }

  String _orderStatusLabel(String status) {
    const labels = {
      'pending': 'Menunggu Konfirmasi',
      'processing': 'Diproses',
      'ready': 'Siap Diambil',
      'completed': 'Selesai',
      'cancelled': 'Dibatalkan',
    };
    return labels[status.toLowerCase()] ?? status;
  }

  Color _orderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'processing':
        return AppColors.info;
      case 'ready':
        return AppColors.success;
      case 'completed':
        return AppColors.orderCompleted;
      case 'cancelled':
      default:
        return AppColors.error;
    }
  }
}
