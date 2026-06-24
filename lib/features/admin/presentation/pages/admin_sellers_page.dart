import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../providers/admin_provider.dart';

class AdminSellersPage extends ConsumerStatefulWidget {
  const AdminSellersPage({super.key});

  @override
  ConsumerState<AdminSellersPage> createState() => _AdminSellersPageState();
}

class _AdminSellersPageState extends ConsumerState<AdminSellersPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final sellersAsync = ref.watch(sellersNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Data Kantin'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push(RouteNames.sellerRegistration),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Tambah Seller',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Cari nama atau email seller...',
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: sellersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _buildError(err.toString()),
              data: (sellers) {
                final filtered = _searchQuery.isEmpty
                    ? sellers
                    : sellers
                        .where((s) =>
                            (s.fullName ?? '')
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                            s.email
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()))
                        .toList();

                if (filtered.isEmpty) {
                  return _buildEmpty();
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(sellersNotifierProvider.notifier).loadSellers(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _buildSellerCard(filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.sellerRegistration),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Tambah Seller', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSellerCard(UserEntity seller) {
    final initial = (seller.fullName?.isNotEmpty == true
            ? seller.fullName![0]
            : seller.email[0])
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          seller.fullName ?? 'Tanpa Nama',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              seller.email,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            if (seller.phoneNumber != null)
              Text(
                seller.phoneNumber!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            const SizedBox(height: 4),
            Text(
              'Bergabung: ${seller.createdAt.day}/${seller.createdAt.month}/${seller.createdAt.year}',
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (action) => _handleAction(action, seller),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'deactivate',
              child: Row(children: [
                Icon(Icons.block_outlined, size: 18, color: AppColors.warning),
                SizedBox(width: 10),
                Text('Nonaktifkan'),
              ]),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                SizedBox(width: 10),
                Text('Hapus', style: TextStyle(color: AppColors.error)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(String action, UserEntity seller) {
    if (action == 'deactivate') {
      _confirmDeactivate(seller);
    } else if (action == 'delete') {
      _confirmDelete(seller);
    }
  }

  void _confirmDeactivate(UserEntity seller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nonaktifkan Seller'),
        content: Text('Nonaktifkan akun ${seller.fullName ?? seller.email}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref
                  .read(sellersNotifierProvider.notifier)
                  .toggleSellerStatus(seller.id, false);
              _showSnack(ok, 'Seller dinonaktifkan', 'Gagal menonaktifkan');
            },
            child: const Text('Nonaktifkan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(UserEntity seller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Seller'),
        content: Text(
          'Hapus akun ${seller.fullName ?? seller.email}?\n\nSemua data kantin akan ikut terhapus.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref
                  .read(sellersNotifierProvider.notifier)
                  .deleteSeller(seller.id);
              _showSnack(
                  ok, 'Seller berhasil dihapus', 'Gagal menghapus seller');
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnack(bool ok, String successMsg, String failMsg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? successMsg : failMsg),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ));
  }

  Widget _buildError(String message) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(message, textAlign: TextAlign.center),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(sellersNotifierProvider.notifier).loadSellers(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_mall_directory_outlined,
                size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Belum ada seller',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambah seller baru dengan menekan tombol di bawah',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
}
