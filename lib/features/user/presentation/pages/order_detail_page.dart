import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/order_item_entity.dart';
import '../providers/cart_provider.dart';
import '../../domain/entities/order_entity.dart';
import 'chat_page.dart';
import '../../../../core/utils/currency_formatter.dart';

// Provider untuk mengambil data items pesanan beserta nama menunya dari repository
final orderItemsProvider = FutureProvider.family<List<OrderItemEntity>, String>((ref, orderId) async {
  return ref.watch(orderRepositoryProvider).getOrderItems(orderId);
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
        const SnackBar(
            content: Text('Silakan pilih rating bintang terlebih dahulu')),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF4F7FFF)),
              SizedBox(width: 10),
              Text('Terima Kasih!',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
              'Ulasan bintang $_selectedRating dan ulasan Anda telah berhasil disimpan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup',
                  style: TextStyle(
                      color: Color(0xFF4F7FFF), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  void _showReturnDialog(
      BuildContext context, OrderEntity order, String rawNote) {
    String selectedReason = 'Makanan basi/rusak';
    final TextEditingController detailsController = TextEditingController();
    final List<String> reasons = [
      'Makanan basi/rusak',
      'Makanan salah/tertukar',
      'Porsi tidak sesuai',
      'Lainnya'
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.assignment_return, color: Colors.orange),
            SizedBox(width: 8),
            Text('Return Pesanan',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih alasan pengembalian:',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedReason,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: reasons
                    .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      selectedReason = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Detail masalah:',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: detailsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Jelaskan detail masalah (min. 5 karakter)...',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final details = detailsController.text.trim();
              if (details.length < 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Silakan tulis detail masalah minimal 5 karakter.')),
                );
                return;
              }

              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Mengirim pengajuan pengembalian...'),
                    duration: Duration(seconds: 1)),
              );

              try {
                final newNote = rawNote.isEmpty
                    ? '[RETURN: $selectedReason - $details]'
                    : '$rawNote\n[RETURN: $selectedReason - $details]';

                await ref
                    .read(orderRepositoryProvider)
                    .updateOrderNote(orderId: order.id, newNote: newNote);

                ref.invalidate(orderHistoryProvider);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pengembalian pesanan berhasil diajukan!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Gagal mengajukan pengembalian: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[800],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Kirim',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showComplaintDialog(
      BuildContext context, OrderEntity order, String rawNote) {
    String selectedType = 'Kurang item/pesanan tidak lengkap';
    final TextEditingController detailsController = TextEditingController();
    final List<String> types = [
      'Kurang item/pesanan tidak lengkap',
      'Pelayanan warung buruk',
      'Pengiriman/pengambilan terlambat',
      'Lainnya'
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.report_problem, color: Colors.red),
            SizedBox(width: 8),
            Text('Komplain Pembeli',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih jenis komplain:',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: types
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      selectedType = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Detail komplain:',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: detailsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Jelaskan detail komplain Anda (min. 5 karakter)...',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final details = detailsController.text.trim();
              if (details.length < 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Silakan tulis detail komplain minimal 5 karakter.')),
                );
                return;
              }

              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Mengirim komplain...'),
                    duration: Duration(seconds: 1)),
              );

              try {
                final newNote = rawNote.isEmpty
                    ? '[COMPLAINT: $selectedType - $details]'
                    : '$rawNote\n[COMPLAINT: $selectedType - $details]';

                await ref
                    .read(orderRepositoryProvider)
                    .updateOrderNote(orderId: order.id, newNote: newNote);

                ref.invalidate(orderHistoryProvider);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Komplain berhasil dikirim! Tim kami akan meninjau laporan Anda.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Gagal mengirim komplain: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[800],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Kirim',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getStatusTitle(String status, {bool isDelivery = false}) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'processing':
        return 'Sedang Dibuat';
      case 'ready':
        return isDelivery ? 'Sedang Diantar' : 'Siap Diambil';
      case 'completed':
        return 'Pesanan Selesai';
      case 'cancelled':
        return 'Pesanan Dibatalkan';
      default:
        return status;
    }
  }

  String _getStatusDescription(String status, {bool isDelivery = false}) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Warung sedang meninjau pesanan Anda.';
      case 'processing':
        return 'Pesanan Anda sedang dimasak dengan penuh cinta.';
      case 'ready':
        return isDelivery
            ? 'Pesanan Anda sudah siap dan sedang dalam perjalanan ke lokasi Anda.'
            : 'Silakan datangi warung untuk mengambil pesanan Anda.';
      case 'completed':
        return 'Pesanan telah diterima dan selesai. Terima kasih!';
      case 'cancelled':
        return 'Pesanan dibatalkan oleh pihak pembeli atau penjual.';
      default:
        return '';
    }
  }

  int _getStatusStepIndex(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'processing':
        return 1;
      case 'ready':
        return 2;
      case 'completed':
        return 3;
      default:
        return -1;
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
        title: const Text('Detail & Lacak Pesanan',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            Center(child: Text('Gagal memuat detail pesanan: $err')),
        data: (orders) {
          final order = orders.where((o) => o.id == widget.orderId).firstOrNull;
          if (order == null) {
            return const Center(
                child: Text('Pesanan tidak ditemukan atau telah dihapus.'));
          }

          final currentStep = _getStatusStepIndex(order.orderStatus);
          final isCancelled = order.orderStatus.toLowerCase() == 'cancelled';

          // Parse Return, Complaint & Delivery Info from order note
          String cleanNote = order.note ?? '';
          String? returnInfo;
          String? complaintInfo;
          String? deliveryOption;

          if (cleanNote.contains('[RETURN:')) {
            final startIndex = cleanNote.indexOf('[RETURN:');
            final endIndex = cleanNote.indexOf(']', startIndex);
            if (endIndex != -1) {
              returnInfo = cleanNote.substring(startIndex + 8, endIndex);
              cleanNote = cleanNote.replaceRange(startIndex, endIndex + 1, '').trim();
            }
          }

          if (cleanNote.contains('[COMPLAINT:')) {
            final startIndex = cleanNote.indexOf('[COMPLAINT:');
            final endIndex = cleanNote.indexOf(']', startIndex);
            if (endIndex != -1) {
              complaintInfo = cleanNote.substring(startIndex + 11, endIndex);
              cleanNote = cleanNote.replaceRange(startIndex, endIndex + 1, '').trim();
            }
          }

          if (cleanNote.contains('[Opsi:')) {
            final startIndex = cleanNote.indexOf('[Opsi:');
            final endIndex = cleanNote.indexOf(']', startIndex);
            if (endIndex != -1) {
              deliveryOption = cleanNote.substring(startIndex + 6, endIndex);
              cleanNote = cleanNote.replaceRange(startIndex, endIndex + 1, '').trim();
            }
          }

          final isDelivery = deliveryOption?.contains('Di Antar') ?? false;
          final String finalCleanNote = cleanNote;

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
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2)),
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
                              Text(widget.vendorName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                              const SizedBox(height: 4),
                              Text(
                                  'ID Pesanan: #${widget.orderId.substring(0, 8).toUpperCase()}',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 13)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (isCancelled
                                      ? Colors.red
                                      : const Color(0xFF4F7FFF))
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getStatusTitle(order.orderStatus, isDelivery: isDelivery),
                              style: TextStyle(
                                color: isCancelled
                                    ? Colors.red
                                    : const Color(0xFF4F7FFF),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getStatusDescription(order.orderStatus, isDelivery: isDelivery),
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 14),
                      ),
                      const Divider(height: 32),

                      // Timeline Stepper (Only show if not cancelled)
                      if (!isCancelled) ...[
                        AnimatedStepRow(
                          index: 0,
                          label: 'Pesanan Dibuat',
                          description: 'Warung sedang meninjau pesanan Anda.',
                          currentStep: currentStep,
                          isLast: false,
                        ),
                        AnimatedStepRow(
                          index: 1,
                          label: 'Sedang Dibuat oleh Warung',
                          description:
                              'Pesanan Anda sedang dimasak dengan penuh cinta.',
                          currentStep: currentStep,
                          isLast: false,
                        ),
                        AnimatedStepRow(
                          index: 2,
                          label: isDelivery ? 'Sedang Diantar' : 'Siap Diambil',
                          description: isDelivery
                              ? 'Pesanan sedang dalam perjalanan ke lokasi Anda.'
                              : 'Silakan datangi warung untuk mengambil pesanan Anda.',
                          currentStep: currentStep,
                          isLast: false,
                        ),
                        AnimatedStepRow(
                          index: 3,
                          label: 'Selesai',
                          description:
                              'Pesanan telah diterima dan selesai. Terima kasih!',
                          currentStep: currentStep,
                          isLast: true,
                        ),
                      ] else ...[
                        const Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.red, size: 24),
                            SizedBox(width: 10),
                            Text('Pesanan ini telah dibatalkan',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold)),
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
                    icon: const Icon(Icons.chat_bubble_outline,
                        color: Colors.white),
                    label: const Text('Hubungi Penjual',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F7FFF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Beri Rating & Nilai Menu',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text(
                            'Bagaimana kualitas makanan dan pelayanan warung ini?',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                                  color: isSelected
                                      ? Colors.amber
                                      : Colors.grey[400],
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
                              hintStyle: const TextStyle(
                                  fontSize: 13, color: Colors.grey),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _isSubmittingRating ? null : _submitRating,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F7FFF),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: _isSubmittingRating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Text('Kirim Ulasan',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
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
                                const Icon(Icons.check_circle,
                                    color: Colors.green),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Anda memberikan ulasan bintang $_selectedRating. Terima kasih atas feedback Anda!',
                                    style: TextStyle(
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13),
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

                  // ── Return & Komplain Section ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.support_agent,
                                color: Color(0xFF4F7FFF), size: 20),
                            SizedBox(width: 8),
                            Text('Layanan & Komplain',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Cards showing submitted status
                        if (returnInfo != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.assignment_return,
                                    color: Colors.orange[800], size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pengembalian Diajukan',
                                        style: TextStyle(
                                            color: Colors.orange[800],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        returnInfo,
                                        style: TextStyle(
                                            color: Colors.orange[900],
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        if (complaintInfo != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.report_problem,
                                    color: Colors.red[800], size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Komplain Diajukan',
                                        style: TextStyle(
                                            color: Colors.red[800],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        complaintInfo,
                                        style: TextStyle(
                                            color: Colors.red[900],
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Action buttons if not yet completed/submitted
                        if (returnInfo == null || complaintInfo == null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (returnInfo == null)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showReturnDialog(
                                        context, order, order.note ?? ''),
                                    icon: const Icon(Icons.assignment_return,
                                        size: 16),
                                    label: const Text('Return Pesanan',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange[800],
                                      side: BorderSide(
                                          color: Colors.orange[300]!),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              if (returnInfo == null && complaintInfo == null)
                                const SizedBox(width: 10),
                              if (complaintInfo == null)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showComplaintDialog(
                                        context, order, order.note ?? ''),
                                    icon: const Icon(Icons.report_problem,
                                        size: 16),
                                    label: const Text('Komplain',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red[800],
                                      side: BorderSide(color: Colors.red[300]!),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Opsi Pengambilan & Lokasi ──
                if (deliveryOption != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.delivery_dining,
                                color: Color(0xFF4F7FFF), size: 20),
                            SizedBox(width: 8),
                            Text('Metode Pengambilan',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F5FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.place, color: Color(0xFF4F7FFF)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  deliveryOption,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1967D2),
                                      fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.receipt_long,
                              color: Color(0xFF4F7FFF), size: 20),
                          SizedBox(width: 8),
                          Text('Rincian Pesanan',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      itemsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Text('Gagal memuat item menu: $err',
                            style: const TextStyle(color: Colors.red)),
                        data: (items) {
                          return Column(
                            children: items
                                .map((item) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0F5FF),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${item.quantity}x',
                                              style: const TextStyle(
                                                  color: Color(0xFF4F7FFF),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(item.name,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                Text(item.price.toRupiah(),
                                                    style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                          Text(item.subtotal.toRupiah(),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ))
                                .toList(),
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
                            const Text('Total Pembayaran',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            Text(order.totalPrice.toRupiah(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Catatan Pesanan ──
                if (finalCleanNote.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notes,
                                color: Color(0xFF4F7FFF), size: 20),
                            SizedBox(width: 8),
                            Text('Catatan Pesanan',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(finalCleanNote,
                            style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                fontStyle: FontStyle.italic)),
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

class AnimatedStepRow extends StatelessWidget {
  final int index;
  final String label;
  final String description;
  final int currentStep;
  final bool isLast;

  const AnimatedStepRow({
    super.key,
    required this.index,
    required this.label,
    required this.description,
    required this.currentStep,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = index == currentStep;
    final bool isCompleted = index < currentStep;
    final bool isReached = index <= currentStep;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedStepIcon(
              index: index,
              isActive: isActive,
              isCompleted: isCompleted,
            ),
            if (!isLast)
              FlowingLine(
                isActive: isCompleted || (isActive && currentStep < 3),
                isFlowing: isActive,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isReached ? FontWeight.bold : FontWeight.w600,
                    color: isReached ? Colors.black87 : Colors.grey[400],
                    fontSize: isActive ? 16 : 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFF4F7FFF).withValues(alpha: 0.9)
                        : (isCompleted ? Colors.grey[600] : Colors.grey[400]),
                    fontSize: isActive ? 13 : 12,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AnimatedStepIcon extends StatefulWidget {
  final int index;
  final bool isActive;
  final bool isCompleted;

  const AnimatedStepIcon({
    super.key,
    required this.index,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  State<AnimatedStepIcon> createState() => _AnimatedStepIconState();
}

class _AnimatedStepIconState extends State<AnimatedStepIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedStepIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompleted) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF4F7FFF),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F7FFF).withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 20,
        ),
      );
    }

    if (!widget.isActive) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: Icon(
          _getStaticIcon(widget.index),
          color: Colors.grey[400],
          size: 18,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 40 + (12 * _controller.value),
              height: 40 + (12 * _controller.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4F7FFF)
                    .withValues(alpha: 0.25 * (1.0 - _controller.value)),
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4F7FFF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F7FFF).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _buildAnimatedIcon(widget.index, _controller.value),
            ),
          ],
        );
      },
    );
  }

  IconData _getStaticIcon(int index) {
    switch (index) {
      case 0:
        return Icons.receipt_long;
      case 1:
        return Icons.soup_kitchen;
      case 2:
        return Icons.local_shipping;
      case 3:
        return Icons.stars;
      default:
        return Icons.circle;
    }
  }

  Widget _buildAnimatedIcon(int index, double animValue) {
    switch (index) {
      case 0:
        final double scale = 1.0 +
            (0.12 * (animValue <= 0.5 ? animValue * 2 : (1.0 - animValue) * 2));
        return Transform.scale(
          scale: scale,
          child: const Icon(
            Icons.receipt_long,
            color: Colors.white,
            size: 20,
          ),
        );
      case 1:
        final double angle =
            0.12 * (animValue <= 0.5 ? animValue * 2 : (1.0 - animValue) * 2);
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 8 - (5 * animValue),
              left: 13 + (2 * animValue),
              child: Opacity(
                opacity: 1.0 - animValue,
                child: Container(
                  width: 2.5,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6 - (5 * ((animValue + 0.5) % 1.0)),
              right: 13 - (2 * ((animValue + 0.5) % 1.0)),
              child: Opacity(
                opacity: 1.0 - ((animValue + 0.5) % 1.0),
                child: Container(
                  width: 2.5,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
            Transform.rotate(
              angle: angle - 0.06,
              child: const Icon(
                Icons.soup_kitchen,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        );
      case 2:
        final double dx =
            1.5 * (animValue <= 0.5 ? animValue * 2 : (1.0 - animValue) * 2);
        final double dy = 0.5 *
            (animValue <= 0.25 || (animValue >= 0.5 && animValue <= 0.75)
                ? 1.0
                : -1.0);
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 4 - (4 * animValue),
              top: 14,
              child: Opacity(
                opacity: 1.0 - animValue,
                child: Container(
                  width: 5,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 6 - (3 * animValue),
              bottom: 12,
              child: Opacity(
                opacity: 1.0 - animValue,
                child: Container(
                  width: 4,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(dx - 1.0, dy),
              child: const Icon(
                Icons.local_shipping,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        );
      case 3:
        final double scale = 1.0 +
            (0.08 * (animValue <= 0.5 ? animValue * 2 : (1.0 - animValue) * 2));
        final double angle = animValue * 2.0 * 3.14159265;
        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: angle * 0.15,
            child: const Icon(
              Icons.stars,
              color: Colors.white,
              size: 22,
            ),
          ),
        );
      default:
        return const Icon(
          Icons.circle,
          color: Colors.white,
          size: 10,
        );
    }
  }
}

class FlowingLine extends StatefulWidget {
  final bool isActive;
  final bool isFlowing;

  const FlowingLine({
    super.key,
    required this.isActive,
    required this.isFlowing,
  });

  @override
  State<FlowingLine> createState() => _FlowingLineState();
}

class _FlowingLineState extends State<FlowingLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isFlowing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(FlowingLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlowing && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isFlowing && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Container(
        margin: const EdgeInsets.only(left: 18.5, top: 4, bottom: 4),
        width: 3,
        height: 36,
        color: Colors.grey[300],
      );
    }

    if (!widget.isFlowing) {
      return Container(
        margin: const EdgeInsets.only(left: 18.5, top: 4, bottom: 4),
        width: 3,
        height: 36,
        color: const Color(0xFF4F7FFF),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(left: 18.5, top: 4, bottom: 4),
          width: 3,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1.5),
            gradient: LinearGradient(
              begin: Alignment(0.0, -2.0 + (_controller.value * 4)),
              end: Alignment(0.0, 0.0 + (_controller.value * 4)),
              tileMode: TileMode.repeated,
              colors: const [
                Color(0xFF4F7FFF),
                Color(0x224F7FFF),
                Color(0xFF4F7FFF),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
