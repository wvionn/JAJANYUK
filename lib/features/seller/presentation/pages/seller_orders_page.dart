import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/order_entity.dart';
import '../providers/seller_provider.dart';

class SellerOrdersPage extends ConsumerWidget {
  const SellerOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ordersNotifierProvider);

    final statusFilters = [
      {'label': 'Semua', 'value': 'all'},
      {'label': 'Menunggu', 'value': 'pending'},
      {'label': 'Diproses', 'value': 'processing'},
      {'label': 'Siap', 'value': 'ready'},
      {'label': 'Selesai', 'value': 'completed'},
      {'label': 'Dibatalkan', 'value': 'cancelled'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pesanan Masuk'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            color: AppColors.secondary,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: statusFilters.map((f) {
                  final isSelected = state.filterStatus == f['value'];
                  final count = f['value'] == 'all'
                      ? state.orders.length
                      : state.countByStatus(f['value']!);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label:
                          Text('${f['label']} ${count > 0 ? "($count)" : ""}'),
                      selected: isSelected,
                      onSelected: (_) => ref
                          .read(ordersNotifierProvider.notifier)
                          .setFilter(f['value']!),
                      selectedColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.secondary : Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 12,
                      ),
                      checkmarkColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _buildError(state.error!, ref)
              : state.filteredOrders.isEmpty
                  ? _buildEmpty(state.filterStatus)
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(ordersNotifierProvider.notifier)
                          .loadOrders(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.filteredOrders.length,
                        itemBuilder: (ctx, i) =>
                            _OrderCard(order: state.filteredOrders[i]),
                      ),
                    ),
    );
  }

  Widget _buildError(String message, WidgetRef ref) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message.contains('does not exist') ||
                        message.contains('relation')
                    ? 'Belum ada pesanan tersedia.\nTunggu pembeli melakukan order.'
                    : message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(ordersNotifierProvider.notifier).loadOrders(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );

  Widget _buildEmpty(String filter) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              filter == 'all'
                  ? 'Belum ada pesanan'
                  : 'Tidak ada pesanan berstatus ini',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pesanan baru akan muncul di sini',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
}

class _OrderCard extends ConsumerWidget {
  final OrderEntity order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final timeFormatter = DateFormat('dd MMM, HH:mm');
    final statusColor = _statusColor(order.status);
    final statusLabel = _statusLabel(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: order.status == 'pending'
            ? Border.all(
                color: AppColors.warning.withValues(alpha: 0.5), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
                  child: Text(
                    (order.buyerName?.isNotEmpty == true
                            ? order.buyerName![0]
                            : '?')
                        .toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.buyerName ?? 'Pembeli',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '#${order.id.substring(0, 8).toUpperCase()} • ${timeFormatter.format(order.createdAt)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(label: statusLabel, color: statusColor),
              ],
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                ...order.items.take(2).map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '${item.quantity}x',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.menuItemName ?? 'Menu',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            formatter.format(item.subtotal),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )),
                if (order.items.length > 2)
                  Text(
                    '+${order.items.length - 2} item lainnya',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (order.notes?.isNotEmpty == true)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sticky_note_2_outlined,
                            size: 14, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.notes!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Footer - total & actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    Text(
                      formatter.format(order.totalPrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Chat button
                OutlinedButton.icon(
                  onPressed: () => context.push(
                    RouteNames.sellerChat.replaceAll(':orderId', order.id),
                  ),
                  icon: const Icon(Icons.chat_outlined, size: 16),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Update status button
                if (_nextStatus(order.status) != null)
                  ElevatedButton(
                    onPressed: () => _updateStatus(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _nextStatusLabel(order.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _nextStatus(String current) {
    const flow = {
      'pending': 'processing',
      'processing': 'ready',
      'ready': 'completed',
    };
    return flow[current];
  }

  String _nextStatusLabel(String current) {
    const labels = {
      'pending': 'Terima',
      'processing': 'Siap',
      'ready': 'Selesai',
    };
    return labels[current] ?? '';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'processing':
        return AppColors.info;
      case 'ready':
        return AppColors.success;
      case 'completed':
        return AppColors.orderCompleted;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String status) {
    const labels = {
      'pending': 'Menunggu',
      'processing': 'Diproses',
      'ready': 'Siap Ambil',
      'completed': 'Selesai',
      'cancelled': 'Dibatalkan',
    };
    return labels[status] ?? status;
  }

  void _updateStatus(BuildContext context, WidgetRef ref) async {
    final next = _nextStatus(order.status);
    if (next == null) return;

    final ok = await ref
        .read(ordersNotifierProvider.notifier)
        .updateStatus(order.id, next);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(ok ? 'Status pesanan diperbarui' : 'Gagal memperbarui status'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ));
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
