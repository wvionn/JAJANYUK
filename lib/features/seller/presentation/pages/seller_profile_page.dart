import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../admin/presentation/providers/admin_provider.dart';
import '../../domain/entities/vendor_entity.dart';
import '../providers/seller_provider.dart';

class SellerProfilePage extends ConsumerWidget {
  const SellerProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorAsync = ref.watch(vendorProfileProvider);
    final campusAsync = ref.watch(campusNotifierProvider);
    final menuState = ref.watch(menuNotifierProvider);
    final ordersState = ref.watch(ordersNotifierProvider);

    final vendor = vendorAsync.valueOrNull;
    final campuses = campusAsync.valueOrNull ?? [];
    
    // Find campus name
    String campusName = 'Kantin Kampus';
    if (vendor != null && campuses.isNotEmpty) {
      final match = campuses.where((c) => c.id == vendor.campusId).firstOrNull;
      if (match != null) {
        campusName = match.name;
      }
    }

    final activeMenusCount = menuState.items.where((i) => i.isAvailable).length;
    final completedOrdersCount = ordersState.countByStatus('completed');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Toko'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: vendorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Gagal memuat profil: $err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
        data: (vendor) {
          if (vendor == null) {
            return const Center(
              child: Text(
                'Data toko tidak ditemukan',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.read(vendorProfileProvider.notifier).loadVendorProfile(vendor.id);
              ref.read(menuNotifierProvider.notifier).loadMenu();
              ref.read(ordersNotifierProvider.notifier).loadOrders();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStoreCard(context, vendor, campusName, activeMenusCount, completedOrdersCount, ref),
                  const SizedBox(height: 16),
                  _buildDetailList(vendor),
                  const SizedBox(height: 24),
                  _buildActionButtons(context, vendor, ref),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoreCard(
    BuildContext context,
    VendorEntity vendor,
    String campusName,
    int activeMenu,
    int completedCount,
    WidgetRef ref,
  ) {
    final isOpen = vendor.isOpen;
    final isVerified = vendor.verificationStatus == 'Terverifikasi';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Photo, Name, and Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: vendor.logoUrl != null && vendor.logoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          vendor.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.storefront_rounded,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.storefront_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vendor.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.verified_rounded,
                              color: AppColors.info,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      campusName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isOpen ? AppColors.success : AppColors.textSecondary)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isOpen ? 'BUKA' : 'TUTUP',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOpen ? AppColors.success : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          // Store stats row (menus, orders, rating)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStoreStatItem('Menu Aktif', activeMenu.toString(), Icons.restaurant_menu),
              _buildStoreStatItem('Pesanan Selesai', completedCount.toString(), Icons.check_circle_outline),
              _buildStoreStatItem('Rating Toko', '⭐ 4.8', Icons.star_border_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoreStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDetailList(VendorEntity vendor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailItem('Deskripsi Kedai', vendor.description ?? 'Belum ada deskripsi', Icons.description_outlined),
          const Divider(height: 1, indent: 52),
          _buildDetailItem('Lokasi Canteen', vendor.location, Icons.location_on_outlined),
          const Divider(height: 1, indent: 52),
          _buildDetailItem('Kontak WhatsApp', vendor.phone, Icons.phone_android_rounded),
          const Divider(height: 1, indent: 52),
          _buildDetailItem('Jam Operasional', '${vendor.openTime} - ${vendor.closeTime}', Icons.access_time_rounded),
          const Divider(height: 1, indent: 52),
          _buildDetailItem('Estimasi Proses', vendor.estimatedProcessTime ?? '10-15 menit', Icons.hourglass_empty_rounded),
          const Divider(height: 1, indent: 52),
          _buildDetailItem('Status Verifikasi', vendor.verificationStatus, Icons.verified_user_outlined),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, VendorEntity vendor, WidgetRef ref) {
    final isOpen = vendor.isOpen;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _showEditBottomSheet(context, vendor),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.edit_note_rounded, size: 22),
            label: const Text(
              'Edit Profil Toko',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () async {
              final err = await ref
                  .read(vendorProfileProvider.notifier)
                  .toggleOpenStatus(!isOpen);
              if (context.mounted) {
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err), backgroundColor: AppColors.error),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(!isOpen ? 'Toko berhasil dibuka' : 'Toko berhasil ditutup'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isOpen ? AppColors.error : AppColors.success, width: 1.5),
              foregroundColor: isOpen ? AppColors.error : AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(isOpen ? Icons.close_rounded : Icons.check_rounded, size: 20),
            label: Text(
              isOpen ? 'Tutup Toko Sekarang' : 'Buka Toko Sekarang',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditBottomSheet(BuildContext context, VendorEntity vendor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProfileBottomSheet(vendor: vendor),
    );
  }
}

// ── Edit Profile Sheet Form ──

class _EditProfileBottomSheet extends ConsumerStatefulWidget {
  final VendorEntity vendor;

  const _EditProfileBottomSheet({required this.vendor});

  @override
  ConsumerState<_EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends ConsumerState<_EditProfileBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _openCtrl;
  late final TextEditingController _closeCtrl;
  late final TextEditingController _processCtrl;
  late final TextEditingController _logoCtrl;
  
  bool _isOpen = true;
  bool _isSaving = false;

  final List<String> _dummyLogoPresets = [
    'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=500', // Rice/Indo
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500', // Pizza/Snack
    'https://images.unsplash.com/photo-1544025162-d76694265947?w=500', // Grill/Meat
    'https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?w=500', // Drinks/Ice
    'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=500', // Coffee
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.vendor.name);
    _descCtrl = TextEditingController(text: widget.vendor.description ?? '');
    _locCtrl = TextEditingController(text: widget.vendor.location);
    _phoneCtrl = TextEditingController(text: widget.vendor.phone);
    _openCtrl = TextEditingController(text: widget.vendor.openTime);
    _closeCtrl = TextEditingController(text: widget.vendor.closeTime);
    _processCtrl = TextEditingController(text: widget.vendor.estimatedProcessTime ?? '10-15 menit');
    _logoCtrl = TextEditingController(text: widget.vendor.logoUrl ?? '');
    _isOpen = widget.vendor.isOpen;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    _phoneCtrl.dispose();
    _openCtrl.dispose();
    _closeCtrl.dispose();
    _processCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectTime(TextEditingController ctrl) async {
    final initialParts = ctrl.text.split(':');
    final initialHour = initialParts.isNotEmpty ? (int.tryParse(initialParts[0]) ?? 8) : 8;
    final initialMin = initialParts.length > 1 ? (int.tryParse(initialParts[1]) ?? 0) : 0;

    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMin),
    );
    if (selected != null) {
      final hourStr = selected.hour.toString().padLeft(2, '0');
      final minStr = selected.minute.toString().padLeft(2, '0');
      setState(() => ctrl.text = '$hourStr:$minStr');
    }
  }

  void _simulateLogoUpload() {
    // Pick a random Unsplash preset image to simulate picking a file
    final randomPreset = (_dummyLogoPresets..shuffle()).first;
    setState(() => _logoCtrl.text = randomPreset);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Foto toko berhasil diunggah (Simulasi)'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check phone validation: digits only
    final phoneText = _phoneCtrl.text.trim();
    if (!RegExp(r'^\d+$').hasMatch(phoneText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor WhatsApp harus berupa angka saja'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final updatedVendor = widget.vendor.copyWith(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      location: _locCtrl.text.trim(),
      phone: phoneText,
      openTime: _openCtrl.text.trim(),
      closeTime: _closeCtrl.text.trim(),
      estimatedProcessTime: _processCtrl.text.trim(),
      logoUrl: _logoCtrl.text.trim(),
      isOpen: _isOpen,
    );

    final err = await ref
        .read(vendorProfileProvider.notifier)
        .updateProfile(updatedVendor);

    setState(() => _isSaving = false);

    if (mounted) {
      if (err == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil toko berhasil diperbarui'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottomsheet handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[350],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Profil Toko',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Logo Upload Section
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: _logoCtrl.text.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _logoCtrl.text,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.store_rounded,
                                  color: AppColors.primary),
                            ),
                          )
                        : const Icon(Icons.store_rounded,
                            color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Foto / Logo Kedai',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _simulateLogoUpload,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.inputBackground,
                                foregroundColor: AppColors.primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.upload_rounded, size: 16),
                              label: const Text('Simulasi Upload',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                            if (_logoCtrl.text.isNotEmpty)
                              IconButton(
                                onPressed: () => setState(() => _logoCtrl.text = ''),
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.error, size: 18),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Fields
              CustomTextField(
                label: 'Nama Toko / Kantin *',
                hint: 'Masukkan nama toko',
                controller: _nameCtrl,
                prefixIcon: Icons.storefront_rounded,
                validator: (v) => Validators.required(v, 'Nama toko'),
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Deskripsi Toko',
                hint: 'Tuliskan deskripsi toko...',
                controller: _descCtrl,
                prefixIcon: Icons.description_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Lokasi Kantin *',
                hint: 'Contoh: Kantin Lantai 1 Gedung A',
                controller: _locCtrl,
                prefixIcon: Icons.location_on_outlined,
                validator: (v) => Validators.required(v, 'Lokasi kantin'),
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Nomor WhatsApp *',
                hint: 'Contoh: 08123456789 (Hanya angka)',
                controller: _phoneCtrl,
                prefixIcon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                validator: (v) => Validators.required(v, 'Nomor WhatsApp'),
              ),
              const SizedBox(height: 14),

              // Open & Close Hours row
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(_openCtrl),
                      child: AbsorbPointer(
                        child: CustomTextField(
                          label: 'Jam Buka *',
                          hint: '08:00',
                          controller: _openCtrl,
                          prefixIcon: Icons.access_time_rounded,
                          validator: (v) => Validators.required(v, 'Jam buka'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(_closeCtrl),
                      child: AbsorbPointer(
                        child: CustomTextField(
                          label: 'Jam Tutup *',
                          hint: '17:00',
                          controller: _closeCtrl,
                          prefixIcon: Icons.access_time_filled_rounded,
                          validator: (v) =>
                              Validators.required(v, 'Jam tutup'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Estimasi Waktu Proses *',
                hint: 'Contoh: 10-15 menit',
                controller: _processCtrl,
                prefixIcon: Icons.hourglass_bottom_rounded,
                validator: (v) => Validators.required(v, 'Estimasi waktu proses'),
              ),
              const SizedBox(height: 14),

              // Status Toko Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Status Toko (Buka/Tutup)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Switch(
                    value: _isOpen,
                    onChanged: (v) => setState(() => _isOpen = v),
                    activeThumbColor: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
