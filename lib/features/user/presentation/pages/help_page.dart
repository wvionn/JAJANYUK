import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Bantuan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Pertanyaan Populer (FAQ)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                ExpansionTile(
                  title: Text('Bagaimana cara memesan makanan?'),
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: Text(
                        'Pilih warung makan favoritmu dari halaman Home, pilih menu makanan, masukkan jumlahnya, lalu klik tombol Keranjang. Setelah itu lakukan Checkout dan konfirmasi pesananmu.',
                        style: TextStyle(color: Colors.grey, height: 1.4),
                      ),
                    ),
                  ],
                ),
                Divider(height: 1),
                ExpansionTile(
                  title: Text('Apakah pembayaran bisa Cash on Delivery (COD)?'),
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: Text(
                        'Ya, semua pesanan di EsaEats saat ini dikirimkan menggunakan metode Cash on Delivery (COD) atau bayar di tempat.',
                        style: TextStyle(color: Colors.grey, height: 1.4),
                      ),
                    ),
                  ],
                ),
                Divider(height: 1),
                ExpansionTile(
                  title: Text('Bagaimana jika pesanan saya tidak sampai?'),
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: Text(
                        'Kamu dapat menghubungi nomor kontak warung bersangkutan yang tertera atau menghubungi tim support kami via WhatsApp yang ada di bawah halaman ini.',
                        style: TextStyle(color: Colors.grey, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Hubungi Kami',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone, color: Colors.green),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('WhatsApp Support', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('+62 812-3456-7890', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F0FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.email, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email Support', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('support@esaeats.com', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
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
  }
}
