import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../providers/seller_provider.dart';

class SellerMenuPage extends ConsumerStatefulWidget {
  const SellerMenuPage({super.key});

  @override
  ConsumerState<SellerMenuPage> createState() => _SellerMenuPageState();
}

class _SellerMenuPageState extends ConsumerState<SellerMenuPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _categories = ['Semua', 'Makanan', 'Minuman', 'Snack', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Menu'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabAlignment: TabAlignment.start,
          tabs: _categories.map((c) => Tab(text: c)).toList(),
        ),
      ),
      body: menuState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : menuState.error != null
              ? _buildError(menuState.error!)
              : TabBarView(
                  controller: _tabController,
                  children: _categories.map((cat) {
                    final items = cat == 'Semua'
                        ? menuState.items
                        : menuState.items
                            .where((i) => i.category == cat)
                            .toList();
                    return _buildItemList(items);
                  }).toList(),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMenuForm(context, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Menu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildItemList(List<MenuItemEntity> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu_outlined,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('Belum ada menu',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(menuNotifierProvider.notifier).loadMenu(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: items.length,
        itemBuilder: (_, i) => _MenuItemCard(
          item: items[i],
          onEdit: () => _showMenuForm(context, items[i]),
          onDelete: () => _confirmDelete(items[i]),
          onToggle: () => _toggleAvailability(items[i]),
        ),
      ),
    );
  }

  void _showMenuForm(BuildContext context, MenuItemEntity? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MenuFormSheet(existing: existing),
    );
  }

  void _confirmDelete(MenuItemEntity item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Menu', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Hapus "${item.name}" dari daftar menu?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref
                  .read(menuNotifierProvider.notifier)
                  .deleteItem(item.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Menu berhasil dihapus' : 'Gagal menghapus menu'),
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

  void _toggleAvailability(MenuItemEntity item) async {
    final err = await ref.read(menuNotifierProvider.notifier).updateItem(
          menuItemId: item.id,
          isAvailable: !item.isAvailable,
        );
    if (mounted) {
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.error),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!item.isAvailable ? 'Menu diaktifkan' : 'Menu dinonaktifkan'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
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
                  ref.read(menuNotifierProvider.notifier).loadMenu(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
}

class _MenuItemCard extends StatelessWidget {
  final MenuItemEntity item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _MenuItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Image area
            Container(
              width: 90,
              height: 90,
              color: AppColors.inputBackground,
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.fastfood_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    )
                  : const Icon(
                      Icons.fastfood_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
            ),
            const SizedBox(width: 12),
            // Info Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: item.isAvailable
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              decoration:
                                  item.isAvailable ? null : TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                        // Label Badge
                        if (item.label != null && item.label!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getLabelColor(item.label!).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.label!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: _getLabelColor(item.label!),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatter.format(item.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Stock & Time
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined, size: 10, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Stok: ${item.stock}',
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 10, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '${item.estimatedTime} mnt',
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Category & Availability Switch
                    Row(
                      children: [
                        Text(
                          item.category,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Transform.scale(
                          scale: 0.75,
                          child: Switch(
                            value: item.isAvailable,
                            onChanged: (_) => onToggle(),
                            activeThumbColor: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Edit'),
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
          ],
        ),
      ),
    );
  }

  Color _getLabelColor(String label) {
    switch (label.toLowerCase()) {
      case 'best seller':
        return Colors.amber[800]!;
      case 'promo':
        return Colors.red;
      case 'pedas':
        return Colors.orange[900]!;
      case 'baru':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }
}

// ── Menu Form Sheet ──

class _MenuFormSheet extends ConsumerStatefulWidget {
  final MenuItemEntity? existing;

  const _MenuFormSheet({this.existing});

  @override
  ConsumerState<_MenuFormSheet> createState() => _MenuFormSheetState();
}

class _MenuFormSheetState extends ConsumerState<_MenuFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _timeCtrl;
  late final TextEditingController _imageCtrl;

  String? _selectedCategory;
  String? _selectedLabel;
  bool _isAvailable = true;
  bool _isLoading = false;

  final _categories = ['Makanan', 'Minuman', 'Snack', 'Lainnya'];
  final _labels = ['None', 'Best Seller', 'Promo', 'Pedas', 'Baru'];

  final List<String> _foodPresetImages = [
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500', // Salad/Generic
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500', // Pizza
    'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=500', // Pancakes/Snack
    'https://images.unsplash.com/photo-1513530534585-c7b1394c6d51?w=500', // Coffee/Drink
    'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500', // Italian
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
    _priceCtrl = TextEditingController(
      text: widget.existing != null ? widget.existing!.price.toStringAsFixed(0) : '',
    );
    _stockCtrl = TextEditingController(
      text: widget.existing != null ? widget.existing!.stock.toString() : '50',
    );
    _timeCtrl = TextEditingController(
      text: widget.existing != null ? widget.existing!.estimatedTime.toString() : '10',
    );
    _imageCtrl = TextEditingController(text: widget.existing?.imageUrl ?? '');

    _selectedCategory = widget.existing?.category ?? 'Makanan';
    _selectedLabel = widget.existing?.label;
    _isAvailable = widget.existing?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _timeCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  void _pickDummyPreset() {
    final randImage = (_foodPresetImages..shuffle()).first;
    setState(() => _imageCtrl.text = randImage);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Foto menu berhasil diunggah (Simulasi)'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Price validations
    final priceStr = _priceCtrl.text.trim();
    final price = double.tryParse(priceStr) ?? -1;
    if (price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga tidak boleh kurang dari 0'), backgroundColor: AppColors.error),
      );
      return;
    }

    // Stock validations
    final stockStr = _stockCtrl.text.trim();
    final stock = int.tryParse(stockStr) ?? -1;
    if (stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok tidak boleh kurang dari 0'), backgroundColor: AppColors.error),
      );
      return;
    }

    // Time validations
    final timeStr = _timeCtrl.text.trim();
    final estimatedTime = int.tryParse(timeStr) ?? 10;

    setState(() => _isLoading = true);

    String? error;
    final cat = _selectedCategory ?? 'Makanan';
    final label = _selectedLabel == 'None' ? null : _selectedLabel;

    if (widget.existing == null) {
      error = await ref.read(menuNotifierProvider.notifier).addItem(
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            price: price,
            category: cat,
            stock: stock,
            estimatedTime: estimatedTime,
            label: label,
            isAvailable: _isAvailable,
          );
    } else {
      error = await ref.read(menuNotifierProvider.notifier).updateItem(
            menuItemId: widget.existing!.id,
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            price: price,
            category: cat,
            stock: stock,
            estimatedTime: estimatedTime,
            label: label,
            isAvailable: _isAvailable,
          );
    }

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.existing == null
            ? 'Menu berhasil ditambahkan'
            : 'Menu berhasil diperbarui'),
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
              // Bottomsheet Handle
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
                widget.existing == null ? 'Tambah Menu Baru' : 'Edit Menu',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Image Picker Simulation
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: _imageCtrl.text.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _imageCtrl.text,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.fastfood_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.fastfood_rounded,
                            color: AppColors.primary,
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gambar Menu',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickDummyPreset,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.inputBackground,
                                foregroundColor: AppColors.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.image_search_rounded, size: 16),
                              label: const Text(
                                'Pilih Gambar (Simulasi)',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Nama Menu *',
                hint: 'Contoh: Nasi Goreng Gila',
                controller: _nameCtrl,
                prefixIcon: Icons.fastfood_outlined,
                validator: (v) => Validators.required(v, 'Nama menu'),
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Deskripsi Menu',
                hint: 'Tuliskan deskripsi rasa, porsi, atau bahan...',
                controller: _descCtrl,
                prefixIcon: Icons.description_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Harga (Rp) *',
                      hint: '15000',
                      controller: _priceCtrl,
                      prefixIcon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.required(v, 'Harga'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Stok Menu *',
                      hint: '50',
                      controller: _stockCtrl,
                      prefixIcon: Icons.inventory_2_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.required(v, 'Stok'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Estimasi Masak (Menit) *',
                      hint: '10',
                      controller: _timeCtrl,
                      prefixIcon: Icons.timer_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.required(v, 'Estimasi pembuatan'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Label Select
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Label Menu',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLabel ?? 'None',
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: _labels.map((lbl) {
                            return DropdownMenuItem(
                              value: lbl,
                              child: Text(lbl, style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedLabel = val == 'None' ? null : val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Category Choice Chips
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kategori *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _categories.map((cat) {
                      final selected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.white : AppColors.textPrimary,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Availability Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tersedia untuk dipesan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Switch(
<<<<<<< HEAD
                    value: _available,
                    onChanged: (v) => setState(() => _available = v),
=======
                    value: _isAvailable,
                    onChanged: (v) => setState(() => _isAvailable = v),
>>>>>>> 07f3ccc2fca1921d59a87706cb38589600a34faf
                    activeThumbColor: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(
                          widget.existing == null ? Icons.add : Icons.save_outlined,
                          color: Colors.white,
                        ),
                  label: Text(
                    widget.existing == null ? 'Tambah Menu' : 'Simpan Perubahan',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
