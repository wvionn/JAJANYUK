import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../providers/admin_provider.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final roles = ['all', 'buyer', 'seller'];
      final role = roles[_tabController.index];
      if (role == 'all') {
        ref.read(usersNotifierProvider.notifier).loadAllUsers();
      } else {
        ref.read(usersNotifierProvider.notifier).loadByRole(role);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Data User'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Pembeli'),
            Tab(text: 'Seller'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(roleFilter: null),
                _buildUserList(roleFilter: 'buyer'),
                _buildUserList(roleFilter: 'seller'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Cari nama atau email...',
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
    );
  }

  Widget _buildUserList({String? roleFilter}) {
    final usersAsync = ref.watch(usersNotifierProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _buildError(err.toString()),
      data: (users) {
        List<UserEntity> filtered = users;

        if (roleFilter != null) {
          filtered = users.where((u) => u.role.value == roleFilter).toList();
        }

        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          filtered = filtered
              .where((u) =>
                  (u.fullName ?? '').toLowerCase().contains(q) ||
                  u.email.toLowerCase().contains(q))
              .toList();
        }

        if (filtered.isEmpty) {
          return _buildEmpty('Tidak ada user ditemukan');
        }

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(usersNotifierProvider.notifier).loadAllUsers(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _buildUserCard(filtered[index]),
          ),
        );
      },
    );
  }

  Widget _buildUserCard(UserEntity user) {
    final roleColor = _getRoleColor(user.role.value);

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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.15),
          child: Text(
            (user.fullName?.isNotEmpty == true
                    ? user.fullName![0]
                    : user.email[0])
                .toUpperCase(),
            style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user.fullName ?? 'Tanpa Nama',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildRoleBadge(user.role.value, roleColor),
                if (user.phoneNumber != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    user.phoneNumber!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) => _handleUserAction(value, user),
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: 'view',
                child: _PopupItem(
                    icon: Icons.visibility_outlined, label: 'Detail')),
            const PopupMenuItem(
                value: 'toggle',
                child: _PopupItem(
                    icon: Icons.block_outlined, label: 'Nonaktifkan')),
            const PopupMenuItem(
              value: 'delete',
              child: _PopupItem(
                  icon: Icons.delete_outline,
                  label: 'Hapus',
                  isDestructive: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role, Color color) {
    final labels = {'admin': 'Admin', 'seller': 'Seller', 'buyer': 'Pembeli'};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        labels[role] ?? role,
        style:
            TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.info;
      case 'seller':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  void _handleUserAction(String action, UserEntity user) async {
    if (action == 'view') {
      _showUserDetail(user);
    } else if (action == 'toggle') {
      _showToggleConfirmation(user);
    } else if (action == 'delete') {
      _showDeleteConfirmation(user);
    }
  }

  void _showUserDetail(UserEntity user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _UserDetailSheet(user: user),
    );
  }

  void _showToggleConfirmation(UserEntity user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi'),
        content: Text('Nonaktifkan akun ${user.fullName ?? user.email}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref
                  .read(usersNotifierProvider.notifier)
                  .toggleUserStatus(user.id, false);
              _showFeedback(
                  ok, 'Berhasil dinonaktifkan', 'Gagal menonaktifkan user');
            },
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(UserEntity user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus User'),
        content: Text(
          'Hapus akun ${user.fullName ?? user.email}? Aksi ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref
                  .read(usersNotifierProvider.notifier)
                  .deleteUser(user.id);
              _showFeedback(
                  ok, 'User berhasil dihapus', 'Gagal menghapus user');
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFeedback(bool success, String successMsg, String failMsg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? successMsg : failMsg),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Widget _buildError(String message) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            TextButton(
              onPressed: () =>
                  ref.read(usersNotifierProvider.notifier).loadAllUsers(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );

  Widget _buildEmpty(String message) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
}

class _PopupItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;

  const _PopupItem({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontSize: 14)),
      ],
    );
  }
}

class _UserDetailSheet extends StatelessWidget {
  final UserEntity user;

  const _UserDetailSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              (user.fullName?.isNotEmpty == true
                      ? user.fullName![0]
                      : user.email[0])
                  .toUpperCase(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.fullName ?? 'Tanpa Nama',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(user.email,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          _infoRow(Icons.badge_outlined, 'Role', user.role.value),
          if (user.phoneNumber != null)
            _infoRow(Icons.phone_outlined, 'Telepon', user.phoneNumber!),
          if (user.campusId != null)
            _infoRow(Icons.school_outlined, 'Campus ID', user.campusId!),
          _infoRow(
            Icons.calendar_today_outlined,
            'Bergabung',
            '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
