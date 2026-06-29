import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'order_history_page.dart';
import 'address_page.dart';
import 'settings_page.dart';
import 'help_page.dart';
import 'analytics_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final userName = user?.fullName ?? 'Pengguna';
    final userEmail = user?.email ?? 'Tidak ada email';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Header Info
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.person_outline,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Menu Items List
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.history,
                    title: 'Riwayat Pesanan',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.location_on,
                    title: 'Alamat Pengiriman',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddressPage()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.bar_chart,
                    title: 'Analisis Pembelian',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AnalyticsPage()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Pengaturan',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'Bantuan',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Log Out Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton(
                onPressed: () => _showLogoutDialog(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go(RouteNames.login);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
