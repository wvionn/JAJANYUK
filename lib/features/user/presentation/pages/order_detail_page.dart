import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';
import 'chat_page.dart';
import '../../../../core/utils/currency_formatter.dart';

// Model lokal untuk item pesanan detail
class OrderDetailItem {
  final String name;
  final int quantity;
  final double price;
  final double subtotal;

  const OrderDetailItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });
}

// Provider untuk mengambil data items pesanan beserta nama menunya dari Supabase
final orderItemsProvider = FutureProvider.family<List<OrderDetailItem>, String>((ref, orderId) async {
  final client = Supabase.instance.client;
  final response = await client
      .from('order_items')
      .select('*, menus(name)')
      .eq('order_id', orderId);

  return (response as List).map((e) {
    final menu = e['menus'] as Map<String, dynamic>?;
    return OrderDetailItem(
      name: menu?['name'] as String? ?? 'Menu Makanan',
      quantity: e['quantity'] as int? ?? 1,
      price: (e['price'] as num?)?.toDouble() ?? 0.0,
      subtotal: (e['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }).toList();
});

class OrderDetailPage extends ConsumerStatefulWidget {
  final String orderId;
  final String vendorName;

  const OrderDetailPage({
    super.key,
    required this.orderId,
    required this.vendorName,
  });

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  int _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _hasSubmittedRating = false;
  bool _isSubmittingRating = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      ref.invalidate(orderHistoryProvider);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _reviewController.dispose();
    super.dispose();
  }

  void _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih rating bintang terlebih dahulu')),
      );
      return;
    }

    setState(() {
      _isSubmittingRating = true;
    });

    // Simulasi pengiriman ulasan (dalam skenario produksi, data ini disimpan ke tabel database ulasan)
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isSubmittingRating = false;
        _hasSubmittedRating = true;
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF4F7FFF)),
              SizedBox(width: 10),
              Text('Terima Kasih!', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text('Ulasan bintang $_selectedRating dan ulasan Anda telah berhasil disimpan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup', style: TextStyle(color: Color(0xFF4F7FFF), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  String _getStatusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'Menunggu Konfirmasi';
      case 'processing': return 'Sedang Dibuat';
      case 'ready': return 'Siap Diambil';
      case 'completed': return 'Pesanan Selesai';
      case 'cancelled': return 'Pesanan Dibatalkan';
      default: return status;
    }
  }

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'Warung sedang meninjau pesanan Anda.';
      case 'processing': return 'Pesanan Anda sedang dimasak dengan penuh cinta.';
      case 'ready': return 'Silakan datangi warung untuk mengambil pesanan Anda.';
      case 'completed': return 'Pesanan telah diterima dan selesai. Terima kasih!';
      case 'cancelled': return 'Pesanan dibatalkan oleh pihak pembeli atau penjual.';
      default: return '';
    }
  }

  int _getStatusStepIndex(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 0;
      case 'processing': return 1;
      case 'ready': return 2;
      case 'completed': return 3;
      default: return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderHistoryProvider);
    final itemsAsync = ref.watch(orderItemsProvider(widget.orderId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Detail & Lacak Pesanan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat detail pesanan: $err')),
        data: (orders) {
          final order = orders.where((o) => o.id == widget.orderId).firstOrNull;
          if (order == null) {
            return const Center(child: Text('Pesanan tidak ditemukan atau telah dihapus.'));
          }

          final currentStep = _getStatusStepIndex(order.orderStatus);
          final isCancelled = order.orderStatus.toLowerCase() == 'cancelled';

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status Banner & Timeline ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.vendorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 4),
                              Text('ID Pesanan: #${widget.orderId.substring(0, 8).toUpperCase()}', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (isCancelled ? Colors.red : const Color(0xFF4F7FFF)).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getStatusTitle(order.orderStatus),
                              style: TextStyle(
                                color: isCancelled ? Colors.red : const Color(0xFF4F7FFF),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getStatusDescription(order.orderStatus),
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                      ),
                      const Divider(height: 32),
                      
                      // Timeline Stepper (Only show if not cancelled)
                      if (!isCancelled) ...[
                        _buildTimelineStep(0, 'Pesanan Dibuat', currentStep >= 0),
                        _buildTimelineDivider(currentStep > 0),
                        _buildTimelineStep(1, 'Sedang Dibuat oleh Warung', currentStep >= 1),
                        _buildTimelineDivider(currentStep > 1),
                        _buildTimelineStep(2, 'Siap Diambil / Diantar', currentStep >= 2),
                        _buildTimelineDivider(currentStep > 2),
                        _buildTimelineStep(3, 'Selesai', currentStep >= 3),
                      ] else ...[
                        const Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.red, size: 24),
                            SizedBox(width: 10),
                            Text('Pesanan ini telah dibatalkan', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Tombol Hubungi Penjual (Chat) ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            vendorId: order.vendorId,
                            vendorName: widget.vendorName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                    label: const Text('Hubungi Penjual', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F7FFF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Ulasan & Rating (Jika Status Selesai / Completed) ──
                if (order.orderStatus.toLowerCase() == 'completed') ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Beri Rating & Nilai Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text('Bagaimana kualitas makanan dan pelayanan warung ini?', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 16),
                        
                        if (!_hasSubmittedRating) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final starVal = index + 1;
                              final isSelected = starVal <= _selectedRating;
                              return IconButton(
                                icon: Icon(
                                  isSelected ? Icons.star : Icons.star_border,
                                  color: isSelected ? Colors.amber : Colors.grey[400],
                                  size: 36,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedRating = starVal;
                                  });
                                },
                              );
                            }),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _reviewController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Tulis ulasan Anda (opsional)...',
                              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmittingRating ? null : _submitRating,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F7FFF),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: _isSubmittingRating
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Kirim Ulasan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Anda memberikan ulasan bintang $_selectedRating. Terima kasih atas feedback Anda!',
                                    style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w500, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Rincian Menu Pesanan ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.receipt_long, color: Color(0xFF4F7FFF), size: 20),
                          SizedBox(width: 8),
                          Text('Rincian Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      itemsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Text('Gagal memuat item menu: $err', style: const TextStyle(color: Colors.red)),
                        data: (items) {
                          return Column(
                            children: items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F5FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${item.quantity}x',
                                      style: const TextStyle(color: Color(0xFF4F7FFF), fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text(item.price.toRupiah(), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Text(item.subtotal.toRupiah(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )).toList(),
                          );
                        },
                      ),
                      
                      const Divider(height: 24),
                      _priceRow('Subtotal', order.totalPrice - 1000.0),
                      const SizedBox(height: 6),
                      _priceRow('Biaya Layanan', 1000.0),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F7FFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Pembayaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(order.totalPrice.toRupiah(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Catatan Pesanan ──
                if (order.note != null && order.note!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notes, color: Color(0xFF4F7FFF), size: 20),
                            SizedBox(width: 8),
                            Text('Catatan Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(order.note!, style: const TextStyle(color: Colors.black87, fontSize: 14, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineStep(int index, String label, bool isActive) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF4F7FFF) : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isActive ? Icons.check : Icons.circle,
            color: Colors.white,
            size: isActive ? 14 : 8,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.black87 : Colors.grey[500],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDivider(bool isActive) {
    return Container(
      margin: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
      width: 2,
      height: 24,
      color: isActive ? const Color(0xFF4F7FFF) : Colors.grey[300],
    );
  }

  Widget _priceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(amount.toRupiah(), style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
