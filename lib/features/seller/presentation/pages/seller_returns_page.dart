import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/order_entity.dart';
import '../providers/seller_provider.dart';

class SellerReturnsPage extends ConsumerStatefulWidget {
  const SellerReturnsPage({super.key});

  @override
  ConsumerState<SellerReturnsPage> createState() => _SellerReturnsPageState();
}

class _SellerReturnsPageState extends ConsumerState<SellerReturnsPage> {
  // Helper to parse notes
  static ({
    String? returnInfo,
    String? complaintInfo,
    String? responseInfo,
    String? attachmentUrl,
    String cleanNote
  }) _parseNoteTags(String? rawNote) {
    if (rawNote == null || rawNote.isEmpty) {
      return (returnInfo: null, complaintInfo: null, responseInfo: null, attachmentUrl: null, cleanNote: '');
    }

    String? returnInfo;
    String? complaintInfo;
    String? responseInfo;
    String? attachmentUrl;
    String note = rawNote;

    // Extract [ATTACHMENT: ...]
    if (note.contains('[ATTACHMENT:')) {
      final start = note.indexOf('[ATTACHMENT:');
      final end = note.indexOf(']', start);
      if (end != -1) {
        attachmentUrl = note.substring(start + 12, end).trim();
        note = note.replaceRange(start, end + 1, '').trim();
      }
    }

    // Extract [RESPONSE: ...]
    if (note.contains('[RESPONSE:')) {
      final start = note.indexOf('[RESPONSE:');
      final end = note.indexOf(']', start);
      if (end != -1) {
        responseInfo = note.substring(start + 10, end).trim();
        note = note.replaceRange(start, end + 1, '').trim();
      }
    }

    // Extract [RETURN: ...]
    if (note.contains('[RETURN:')) {
      final start = note.indexOf('[RETURN:');
      final end = note.indexOf(']', start);
      if (end != -1) {
        returnInfo = note.substring(start + 8, end).trim();
        note = note.replaceRange(start, end + 1, '').trim();
      }
    }

    // Extract [COMPLAINT: ...]
    if (note.contains('[COMPLAINT:')) {
      final start = note.indexOf('[COMPLAINT:');
      final end = note.indexOf(']', start);
      if (end != -1) {
        complaintInfo = note.substring(start + 11, end).trim();
        note = note.replaceRange(start, end + 1, '').trim();
      }
    }

    return (
      returnInfo: returnInfo,
      complaintInfo: complaintInfo,
      responseInfo: responseInfo,
      attachmentUrl: attachmentUrl,
      cleanNote: note.trim()
    );
  }

  // Dialog to submit response
  void _showResponseDialog(BuildContext context, OrderEntity order, String? existingResponse) {
    final parsed = _parseNoteTags(order.note);
    final hasReturn = parsed.returnInfo != null;
    
    // Parse existing status and notes if any
    String status = hasReturn ? 'Setujui' : 'Selesai';
    String notesText = '';
    
    if (existingResponse != null && existingResponse.contains(' - ')) {
      final parts = existingResponse.split(' - ');
      status = parts[0];
      notesText = parts.sublist(1).join(' - ');
    } else if (existingResponse != null) {
      status = existingResponse;
    }

    final List<String> statuses = hasReturn 
        ? ['Setujui', 'Tolak'] 
        : ['Selesai', 'Tanggapi'];

    final TextEditingController responseController = TextEditingController(text: notesText);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(
              (hasReturn && parsed.complaintInfo != null)
                  ? 'Tanggapi Return & Komplain'
                  : hasReturn
                      ? 'Tanggapi Pengembalian'
                      : 'Tanggapi Komplain',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Keputusan/Status:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: status,
                    items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          status = val;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Catatan/Alasan:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: responseController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tulis tanggapan untuk pembeli...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(12),
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
                  final text = responseController.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Catatan tanggapan tidak boleh kosong.')),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  
                  // Construct new note by preserving other tags
                  String rawNote = order.note ?? '';
                  
                  // Strip existing [RESPONSE: ...] if present
                  if (rawNote.contains('[RESPONSE:')) {
                    final start = rawNote.indexOf('[RESPONSE:');
                    final end = rawNote.indexOf(']', start);
                    if (end != -1) {
                      rawNote = rawNote.replaceRange(start, end + 1, '').trim();
                    }
                  }

                  final responseTag = '[RESPONSE: $status - $text]';
                  final newNote = rawNote.isEmpty ? responseTag : '$rawNote\n$responseTag';

                  final success = await ref
                      .read(ordersNotifierProvider.notifier)
                      .updateOrderNote(order.id, newNote);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Tanggapan berhasil dikirim!' : 'Gagal mengirim tanggapan.'),
                        backgroundColor: success ? AppColors.success : AppColors.error,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Kirim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersNotifierProvider);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

    // Filter orders containing RETURN or COMPLAINT tags
    final alertOrders = ordersState.orders.where((o) {
      final note = o.note ?? '';
      return note.contains('[RETURN:') || note.contains('[COMPLAINT:');
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Return & Komplain'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: ordersState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : alertOrders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => ref.read(ordersNotifierProvider.notifier).loadOrders(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: alertOrders.length,
                    itemBuilder: (ctx, i) {
                      final order = alertOrders[i];
                      final parsed = _parseNoteTags(order.note);
                      
                      final hasReturn = parsed.returnInfo != null;
                      final hasComplaint = parsed.complaintInfo != null;
                      
                      // Decide banner properties
                      Color bannerBgColor = Colors.red[50]!;
                      Color bannerTxtColor = Colors.red[900]!;
                      IconData bannerIcon = Icons.report_problem_rounded;
                      String bannerTitle = 'KOMPLAIN PESANAN';

                      if (hasReturn && hasComplaint) {
                        bannerBgColor = const Color(0xFFFFF1F1);
                        bannerTxtColor = const Color(0xFFD32F2F);
                        bannerIcon = Icons.warning_amber_rounded;
                        bannerTitle = 'RETURN & KOMPLAIN PESANAN';
                      } else if (hasReturn) {
                        bannerBgColor = Colors.orange[50]!;
                        bannerTxtColor = Colors.orange[900]!;
                        bannerIcon = Icons.assignment_return_rounded;
                        bannerTitle = 'PENGEMBALIAN BARANG/DANA';
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        shadowColor: Colors.black12,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Banner type
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              color: bannerBgColor,
                              child: Row(
                                children: [
                                  Icon(
                                    bannerIcon,
                                    color: bannerTxtColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    bannerTitle,
                                    style: TextStyle(
                                      color: bannerTxtColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '#${order.id.substring(0, 8).toUpperCase()}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Main content
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Buyer details & Date
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        order.buyerName ?? 'Pembeli',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Text(
                                        dateFormatter.format(order.createdAt),
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Request box
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (hasReturn) ...[
                                          Row(
                                            children: [
                                              Icon(Icons.assignment_return_rounded, color: Colors.orange[800], size: 14),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Pengajuan Pengembalian (Return):',
                                                style: TextStyle(fontSize: 11, color: Colors.orange[900], fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            parsed.returnInfo!,
                                            style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary),
                                          ),
                                          if (hasComplaint) const SizedBox(height: 12),
                                        ],
                                        if (hasComplaint) ...[
                                          Row(
                                            children: [
                                              Icon(Icons.report_problem_rounded, color: Colors.red[800], size: 14),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Pengajuan Komplain:',
                                                style: TextStyle(fontSize: 11, color: Colors.red[900], fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            parsed.complaintInfo!,
                                            style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary),
                                          ),
                                        ],
                                        if (parsed.attachmentUrl != null) ...[
                                          const SizedBox(height: 12),
                                          const Divider(),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Foto Bukti Bukti dari Pembeli:',
                                            style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 6),
                                          GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (ctx) => Dialog(
                                                  child: Image.network(parsed.attachmentUrl!),
                                                ),
                                              );
                                            },
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                parsed.attachmentUrl!,
                                                height: 100,
                                                width: 150,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  
                                  // Response box if exists
                                  if (parsed.responseInfo != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.green[200]!),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.green[700], size: 14),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Tanggapan Anda:',
                                                style: TextStyle(fontSize: 11, color: Colors.green[800], fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            parsed.responseInfo!,
                                            style: TextStyle(fontSize: 13, height: 1.4, color: Colors.green[900]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  
                                  const Divider(height: 24),
                                  
                                  // Items list & action button
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total Transaksi:',
                                              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                            ),
                                            Text(
                                              formatter.format(order.totalPrice),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.secondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      ElevatedButton.icon(
                                        onPressed: () => _showResponseDialog(context, order, parsed.responseInfo),
                                        icon: Icon(parsed.responseInfo == null ? Icons.edit_note : Icons.replay, size: 18, color: Colors.white),
                                        label: Text(parsed.responseInfo == null ? 'Beri Tanggapan' : 'Ubah Tanggapan'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: parsed.responseInfo == null ? Colors.redAccent : Colors.grey[700],
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 72,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Semua Lancar!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tidak ada pengajuan return barang maupun komplain aktif dari pembeli saat ini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
