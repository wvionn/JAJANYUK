import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'order_detail_page.dart';

class OrderSuccessPage extends StatelessWidget {
  final String? orderId;
  final String? vendorId;
  final String? vendorName;

  const OrderSuccessPage({
    super.key,
    this.orderId,
    this.vendorId,
    this.vendorName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Color(0xFFE8F0FE), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: Color(0xFF4F7FFF), size: 80),
            ),
            const SizedBox(height: 24),
            const Text('Pesanan Berhasil!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Pesananmu sedang diproses oleh warung', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            if (orderId != null) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailPage(
                        orderId: orderId!,
                        vendorName: vendorName ?? 'Warung',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.track_changes, color: Colors.white),
                label: const Text('Lacak Pesanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F7FFF),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF4F7FFF)),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kembali ke Home', style: TextStyle(color: Color(0xFF4F7FFF), fontWeight: FontWeight.bold)),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F7FFF),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kembali ke Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
            if (vendorId != null && vendorName != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        vendorId: vendorId!,
                        vendorName: vendorName!,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF4F7FFF)),
                label: const Text('Chat Penjual', style: TextStyle(color: Color(0xFF4F7FFF), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF4F7FFF)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}