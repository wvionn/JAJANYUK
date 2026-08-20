import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import 'order_success_page.dart';
import '../providers/menu_provider.dart';
import '../providers/profile_providers.dart';
import 'chat_page.dart';
import '../../../../core/utils/currency_formatter.dart';

enum PaymentMethod { cod, transfer, qris }
enum DeliveryType { ambilSendiri, diAntar }

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _lobbyController = TextEditingController();
  PaymentMethod _selectedPayment = PaymentMethod.qris;
  DeliveryType _selectedDeliveryType = DeliveryType.ambilSendiri;
  
  final List<String> _gedungList = ['Gedung A', 'Gedung B', 'Lobi', 'Taman'];
  String _selectedGedung = 'Gedung A';
  String _selectedLantai = 'Lantai 1';

  @override
  void initState() {
    super.initState();
    _prefillAddress();
  }

  void _prefillAddress() {
    final address = ref.read(deliveryAddressProvider);
    if (address.isEmpty) return;

    final lantais = ['Lantai 1', 'Lantai 2', 'Lantai 3', 'Lantai 4', 'Lantai 5'];

    String? matchedBuilding;
    for (final b in _gedungList) {
      if (address.contains(b)) {
        matchedBuilding = b;
        break;
      }
    }

    String? matchedLantai;
    for (final l in lantais) {
      if (address.contains(l)) {
        matchedLantai = l;
        break;
      }
    }

    String? matchedLobby;
    final startBracket = address.indexOf('(');
    final endBracket = address.indexOf(')');
    if (startBracket != -1 && endBracket != -1 && endBracket > startBracket) {
      matchedLobby = address.substring(startBracket + 1, endBracket);
    } else {
      final parts = address.split(',');
      if (parts.length > 2) {
        matchedLobby = parts.sublist(2).join(',').trim();
      } else if (parts.length == 2 && matchedBuilding != null && matchedLantai == null) {
        matchedLobby = parts[1].trim();
      }
    }

    if (matchedBuilding != null) {
      _selectedGedung = matchedBuilding;
    }
    if (matchedLantai != null) {
      _selectedLantai = matchedLantai;
    }
    if (matchedLobby != null) {
      _lobbyController.text = matchedLobby;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _lobbyController.dispose();
    super.dispose();
  }

  String get _paymentMethodName {
    switch (_selectedPayment) {
      case PaymentMethod.cod: return 'Bayar di Tempat (COD)';
      case PaymentMethod.transfer: return 'Transfer Bank';
      case PaymentMethod.qris: return 'QRIS';
    }
  }

  IconData get _paymentMethodIcon {
    switch (_selectedPayment) {
      case PaymentMethod.cod: return Icons.money;
      case PaymentMethod.transfer: return Icons.account_balance;
      case PaymentMethod.qris: return Icons.qr_code;
    }
  }

  void _showPaymentSheet(BuildContext context, CartState cartState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Pilih Metode Pembayaran',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _paymentOption(sheetContext, PaymentMethod.qris, Icons.qr_code, 'QRIS', 'Scan QR code untuk bayar'),
            // _paymentOption(sheetContext, PaymentMethod.transfer, Icons.account_balance, 'Transfer Bank', 'BCA / BRI / Mandiri / BNI'),
            _paymentOption(sheetContext, PaymentMethod.cod, Icons.money, 'Bayar di Tempat', 'Bayar langsung ke penjual'),
          ],
        ),
      ),
    );
  }

  Widget _paymentOption(BuildContext sheetContext, PaymentMethod method, IconData icon, String title, String subtitle) {
    final isSelected = _selectedPayment == method;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPayment = method);
        Navigator.pop(sheetContext);
        if (method == PaymentMethod.qris) _showQrisDialog();
        if (method == PaymentMethod.transfer) _showTransferDialog();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF3FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F7FFF) : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF4F7FFF) : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF4F7FFF) : Colors.black)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF4F7FFF)),
          ],
        ),
      ),
    );
  }

  void _showQrisDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Scan QRIS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF4F7FFF), width: 3),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code, size: 120, color: Colors.black87),
                      SizedBox(height: 8),
                      Text('QRIS EsaEats', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Tunjukkan QR ini ke kasir atau scan dari HP kamu',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F7FFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tutup', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransferDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text('Info Transfer Bank', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              _bankRow('BCA', '1234567890'),
              _bankRow('BRI', '0987654321'),
              _bankRow('Mandiri', '1122334455'),
              const SizedBox(height: 8),
              const Text('a.n. EsaEats Kantin', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              const Text('Setelah transfer, tunjukkan bukti pembayaran ke penjual.',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F7FFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Mengerti', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bankRow(String bank, String number) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(bank, style: const TextStyle(color: Color(0xFF4F7FFF), fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Text(number, style: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 1)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartNotifierProvider);
    final vendorState = ref.watch(vendorNotifierProvider);
    final vendor = cartState.vendorId != null
        ? vendorState.vendors.where((v) => v.id == cartState.vendorId).firstOrNull
        : null;
    final serviceFee = 1000.0;
    final total = cartState.totalPrice + serviceFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Checkout', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (cartState.vendorId != null)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF4F7FFF)),
              tooltip: 'Chat Penjual',
              onPressed: () {
                final vendorName = vendor?.name ?? 'Penjual';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      vendorId: cartState.vendorId!,
                      vendorName: vendorName,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Opsi Pengambilan ──
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.delivery_dining, color: Color(0xFF4F7FFF), size: 20),
                      SizedBox(width: 8),
                      Text('Opsi Pengambilan Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _deliveryTypeOption(
                        DeliveryType.ambilSendiri,
                        Icons.storefront,
                        'Ambil Sendiri',
                        'Ambil langsung ke warung',
                      ),
                      const SizedBox(width: 12),
                      _deliveryTypeOption(
                        DeliveryType.diAntar,
                        Icons.local_shipping,
                        'Di Antar',
                        'Dikirim ke lokasi Anda',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Lokasi Pengantaran / Pengambilan Toko ──
            if (_selectedDeliveryType == DeliveryType.ambilSendiri) ...[
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.storefront, color: Color(0xFF4F7FFF), size: 20),
                        SizedBox(width: 8),
                        Text('Lokasi Pengambilan Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.place, color: Color(0xFF4F7FFF), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vendor?.name ?? 'Nama Toko',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  vendor?.location ?? 'Silakan kunjungi toko kantin penjual setelah pesanan berstatus Siap Diambil.',
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFF4F7FFF), size: 20),
                        SizedBox(width: 8),
                        Text('Lokasi Pengantaran Mahasiswa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('Pilih Gedung / Area', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _gedungList.map((g) {
                        final isGSelected = _selectedGedung == g;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedGedung = g),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isGSelected ? const Color(0xFFEEF3FF) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isGSelected ? const Color(0xFF4F7FFF) : Colors.grey[300]!,
                                width: isGSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              g,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isGSelected ? const Color(0xFF4F7FFF) : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_selectedGedung == 'Gedung A' || _selectedGedung == 'Gedung B') ...[
                      const SizedBox(height: 16),
                      const Text('Pilih Lantai', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLantai,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4F7FFF)),
                            items: ['Lantai 1', 'Lantai 2', 'Lantai 3', 'Lantai 4', 'Lantai 5'].map((String item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child: Text(item, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() => _selectedLantai = newValue);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text('Posisi Lobi / Detail Lokasi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _lobbyController,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Lobi Utama, depan resepsionis/lift...',
                        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4F7FFF), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Ringkasan Pesanan ──
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.receipt_long_outlined, color: Color(0xFF4F7FFF), size: 20),
                      SizedBox(width: 8),
                      Text('Ringkasan Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...cartState.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F5FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fastfood_outlined, color: Color(0xFF4F7FFF)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.menu.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('x${item.quantity}  •  ${item.menu.price.toRupiah()}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                         Text(item.subtotal.toRupiah(),
                             style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
                  const Divider(height: 20),
                  _priceRow('Subtotal', cartState.totalPrice),
                  const SizedBox(height: 6),
                  _priceRow('Biaya Layanan', serviceFee),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F7FFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Bayar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                         Text(total.toRupiah(),
                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Metode Pembayaran ──
            GestureDetector(
              onTap: () => _showPaymentSheet(context, cartState),
              child: _sectionCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_paymentMethodIcon, color: const Color(0xFF4F7FFF), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Metode Pembayaran', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(_paymentMethodName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Catatan ──
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sticky_note_2_outlined, color: Color(0xFF4F7FFF), size: 20),
                      SizedBox(width: 8),
                      Text('Catatan (opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Contoh: tanpa pedas, sajikan panas...',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4F7FFF)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, -5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text('Total: ${total.toRupiah()}',
                     style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4F7FFF))),
                Text(_paymentMethodName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: cartState.isLoading
                    ? null
                    : () async {
                        if (_selectedDeliveryType == DeliveryType.diAntar && _lobbyController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Silakan isi posisi lobi Anda terlebih dahulu'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final String deliveryDetails = _selectedDeliveryType == DeliveryType.ambilSendiri
                            ? '[Opsi: Ambil Sendiri]'
                            : (_selectedGedung == 'Gedung A' || _selectedGedung == 'Gedung B')
                                ? '[Opsi: Di Antar - Gedung: $_selectedGedung, Lantai: $_selectedLantai, Lobi: ${_lobbyController.text.trim()}]'
                                : '[Opsi: Di Antar - Area: $_selectedGedung, Detail: ${_lobbyController.text.trim()}]';
                        final String finalNote = _noteController.text.trim().isEmpty
                            ? deliveryDetails
                            : '$deliveryDetails\nCatatan: ${_noteController.text.trim()}';

                        final vendorId = cartState.vendorId;
                        final vendor = vendorId != null
                            ? ref.read(vendorNotifierProvider).vendors
                                .where((v) => v.id == vendorId)
                                .firstOrNull
                            : null;
                        final vendorName = vendor?.name;

                        await ref.read(cartNotifierProvider.notifier).checkout(
                          note: finalNote,
                        );
                        if (!context.mounted) return;
                        final error = ref.read(cartNotifierProvider).error;
                        if (error == null) {
                          ref.invalidate(orderHistoryProvider);
                          final lastOrder = ref.read(cartNotifierProvider).lastOrder;
                          final newOrderId = lastOrder?.id;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderSuccessPage(
                                orderId: newOrderId,
                                vendorId: vendorId,
                                vendorName: vendorName,
                              ),
                            ),
                            (route) => route.isFirst,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error), backgroundColor: Colors.red),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F7FFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: cartState.isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Konfirmasi Pesanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deliveryTypeOption(DeliveryType type, IconData icon, String title, String subtitle) {
    final isSelected = _selectedDeliveryType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDeliveryType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEEF3FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF4F7FFF) : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF4F7FFF) : Colors.grey, size: 24),
              const SizedBox(height: 6),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? const Color(0xFF4F7FFF) : Colors.black87)),
              const SizedBox(height: 2),
              Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: isSelected ? const Color(0xFF4F7FFF).withValues(alpha: 0.8) : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _priceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
         Text(amount.toRupiah()),
      ],
    );
  }
}
