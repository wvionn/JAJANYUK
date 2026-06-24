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
                            .where((i) => (i.category ?? 'Lainnya') == cat)
                            .toList();
                    return _buildItemList(items);
                  }).toList(),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMenuForm(context, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Menu', style: TextStyle(color: Colors.white)),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _MenuFormSheet(existing: existing),
    );
  }

  void _confirmDelete(MenuItemEntity item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Menu'),
        content: Text('Hapus "${item.name}" dari daftar menu?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref
                  .read(menuNotifierProvider.notifier)
                  .deleteItem(item.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Menu dihapus' : 'Gagal menghapus menu'),
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
          available: !item.available,
        );
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
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
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.fastfood_rounded, color: AppColors.primary),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: item.available
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  decoration:
                      item.available ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
            if (item.category != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.category!,
                  style: const TextStyle(fontSize: 10, color: AppColors.info),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description != null)
              Text(
                item.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  formatter.format(item.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (item.available
                              ? AppColors.success
                              : AppColors.textSecondary)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.available
                              ? Icons.check_circle_outline
                              : Icons.remove_circle_outline,
                          size: 12,
                          color: item.available
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.available ? 'Tersedia' : 'Habis',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: item.available
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      ),
    );
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
  String? _selectedCategory;
  bool _available = true;
  bool _isLoading = false;

  final _categories = ['Makanan', 'Minuman', 'Snack', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
    _priceCtrl = TextEditingController(
      text: widget.existing?.price.toStringAsFixed(0) ?? '',
    );
    _selectedCategory = widget.existing?.category;
    _available = widget.existing?.available ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String? error;
    final price = double.tryParse(_priceCtrl.text.replaceAll('.', '')) ?? 0;

    if (widget.existing == null) {
      error = await ref.read(menuNotifierProvider.notifier).addItem(
            name: _nameCtrl.text.trim(),
            description:
                _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            price: price,
            category: _selectedCategory,
            available: _available,
          );
    } else {
      error = await ref.read(menuNotifierProvider.notifier).updateItem(
            menuItemId: widget.existing!.id,
            name: _nameCtrl.text.trim(),
            description:
                _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            price: price,
            category: _selectedCategory,
            available: _available,
          );
    }

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.existing == null
            ? 'Menu berhasil ditambahkan'
            : 'Menu diperbarui'),
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
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              CustomTextField(
                label: 'Nama Menu',
                hint: 'Contoh: Nasi Goreng Spesial',
                controller: _nameCtrl,
                prefixIcon: Icons.fastfood_outlined,
                validator: (v) => Validators.required(v, 'Nama menu'),
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Deskripsi (opsional)',
                hint: 'Deskripsikan menu ini...',
                controller: _descCtrl,
                prefixIcon: Icons.description_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Harga (Rp)',
                hint: '15000',
                controller: _priceCtrl,
                prefixIcon: Icons.attach_money_outlined,
                keyboardType: TextInputType.number,
                validator: Validators.price,
              ),
              const SizedBox(height: 14),

              // Kategori
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kategori',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _categories.map((cat) {
                      final selected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (_) => setState(
                            () => _selectedCategory = selected ? null : cat),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color:
                              selected ? Colors.white : AppColors.textPrimary,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Ketersediaan
              Row(
                children: [
                  const Text(
                    'Tersedia untuk dipesan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Switch(
                    value: _available,
                    onChanged: (v) => setState(() => _available = v),
                    activeColor: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
                      : Icon(
                          widget.existing == null
                              ? Icons.add
                              : Icons.save_outlined,
                          color: Colors.white,
                        ),
                  label: Text(
                    widget.existing == null
                        ? 'Tambah Menu'
                        : 'Simpan Perubahan',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
