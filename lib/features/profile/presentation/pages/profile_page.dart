import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child:
                        Icon(Icons.person, size: 50, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Khairunnisa dewi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'khairunnisa@example.com',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Menu Items
            _buildMenuItem(
              icon: Icons.location_on,
              title: 'Alamat Pengiriman',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.history,
              title: 'Riwayat Pesanan',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.payment,
              title: 'Metode Pembayaran',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.settings,
              title: 'Pengaturan',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.help,
              title: 'Bantuan',
              onTap: () {},
            ),
            const SizedBox(height: 24),
            // Logout Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement logout
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Keluar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
