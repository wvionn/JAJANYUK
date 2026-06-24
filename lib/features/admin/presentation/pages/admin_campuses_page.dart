import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../domain/entities/campus_entity.dart';
import '../providers/admin_provider.dart';

class AdminCampusesPage extends ConsumerWidget {
  const AdminCampusesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campusAsync = ref.watch(campusNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Cabang Kampus'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: campusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildError(context, ref, err.toString()),
        data: (campuses) {
          if (campuses.isEmpty) {
            return _buildEmpty(context, ref);
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(campusNotifierProvider.notifier).loadCampuses(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: campuses.length,
              itemBuilder: (ctx, i) => _CampusCard(campus: campuses[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCampusDialog(context, ref, null),
        backgroundColor: AppColors.info,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Tambah Kampus', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  static void _showCampusDialog(
    BuildContext context,
    WidgetRef ref,
    CampusEntity? existing,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CampusFormSheet(existing: existing),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          TextButton(
            onPressed: () =>
                ref.read(campusNotifierProvider.notifier).loadCampuses(),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Belum ada kampus',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tambah cabang kampus baru',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showCampusDialog(context, ref, null),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Kampus'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.info),
          ),
        ],
      ),
    );
  }
}

class _CampusCard extends ConsumerWidget {
  final CampusEntity campus;

  const _CampusCard({required this.campus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (campus.isActive ? AppColors.info : AppColors.textHint)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.school_rounded,
            color: campus.isActive ? AppColors.info : AppColors.textHint,
            size: 24,
          ),
        ),
        title: Text(
          campus.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (campus.address != null)
              Text(
                campus.address!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            if (campus.city != null)
              Text(
                campus.city!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            const SizedBox(height: 4),
            _StatusBadge(isActive: campus.isActive),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (action) => _handleAction(context, ref, action),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(children: [
                Icon(Icons.edit_outlined, size: 18),
                SizedBox(width: 10),
                Text('Edit'),
              ]),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(children: [
                Icon(
                  campus.isActive
                      ? Icons.toggle_off_outlined
                      : Icons.toggle_on_outlined,
                  size: 18,
                  color:
                      campus.isActive ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(width: 10),
                Text(campus.isActive ? 'Nonaktifkan' : 'Aktifkan'),
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

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    if (action == 'edit') {
      _AdminCampusesPageState._showCampusDialog(context, ref, campus);
    } else if (action == 'toggle') {
      _confirmToggle(context, ref);
    } else if (action == 'delete') {
      _confirmDelete(context, ref);
    }
  }

  void _confirmToggle(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(campus.isActive ? 'Nonaktifkan Kampus' : 'Aktifkan Kampus'),
        content: Text(
          '${campus.isActive ? "Nonaktifkan" : "Aktifkan"} kampus ${campus.name}?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  campus.isActive ? AppColors.warning : AppColors.success,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final err =
                  await ref.read(campusNotifierProvider.notifier).updateCampus(
                        campusId: campus.id,
                        isActive: !campus.isActive,
                      );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(err ?? 'Status kampus diperbarui'),
                  backgroundColor:
                      err == null ? AppColors.success : AppColors.error,
                ));
              }
            },
            child: Text(
              campus.isActive ? 'Nonaktifkan' : 'Aktifkan',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kampus'),
        content: Text('Hapus kampus ${campus.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref
                  .read(campusNotifierProvider.notifier)
                  .deleteCampus(campus.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text(ok ? 'Kampus dihapus' : 'Gagal menghapus kampus'),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                ));
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// We need a way to access the static method; use a workaround via top-level
class _AdminCampusesPageState {
  static void _showCampusDialog(
    BuildContext context,
    WidgetRef ref,
    CampusEntity? existing,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CampusFormSheet(existing: existing),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.success : AppColors.textHint)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Nonaktif',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.success : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Campus Form Sheet ──

class _CampusFormSheet extends ConsumerStatefulWidget {
  final CampusEntity? existing;

  const _CampusFormSheet({this.existing});

  @override
  ConsumerState<_CampusFormSheet> createState() => _CampusFormSheetState();
}

class _CampusFormSheetState extends ConsumerState<_CampusFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _addressController =
        TextEditingController(text: widget.existing?.address ?? '');
    _cityController = TextEditingController(text: widget.existing?.city ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? error;

    if (widget.existing == null) {
      error = await ref.read(campusNotifierProvider.notifier).createCampus(
            name: _nameController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            city: _cityController.text.trim().isEmpty
                ? null
                : _cityController.text.trim(),
          );
    } else {
      error = await ref.read(campusNotifierProvider.notifier).updateCampus(
            campusId: widget.existing!.id,
            name: _nameController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            city: _cityController.text.trim().isEmpty
                ? null
                : _cityController.text.trim(),
          );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          widget.existing == null
              ? 'Kampus berhasil ditambahkan'
              : 'Kampus berhasil diperbarui',
        ),
        backgroundColor: AppColors.success,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              isEdit ? 'Edit Kampus' : 'Tambah Kampus Baru',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            CustomTextField(
              label: 'Nama Kampus',
              hint: 'Contoh: Universitas Esa Unggul',
              controller: _nameController,
              prefixIcon: Icons.school_outlined,
              validator: (v) => Validators.required(v, 'Nama kampus'),
            ),
            const SizedBox(height: 16),

            CustomTextField(
              label: 'Alamat (opsional)',
              hint: 'Jl. Arjuna Utara No.9',
              controller: _addressController,
              prefixIcon: Icons.location_on_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              label: 'Kota (opsional)',
              hint: 'Jakarta Barat',
              controller: _cityController,
              prefixIcon: Icons.location_city_outlined,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(isEdit ? Icons.save_outlined : Icons.add,
                        color: Colors.white),
                label: Text(
                  isEdit ? 'Simpan Perubahan' : 'Tambah Kampus',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
