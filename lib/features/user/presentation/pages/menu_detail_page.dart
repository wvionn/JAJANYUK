import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/menu_entity.dart';
import '../providers/cart_provider.dart';
import 'chat_page.dart';
import '../../../../core/utils/currency_formatter.dart';

class MenuDetailPage extends ConsumerStatefulWidget {
  final MenuEntity menu;
  final String vendorName;
  final String vendorId;

  const MenuDetailPage({
    super.key,
    required this.menu,
    required this.vendorName,
    required this.vendorId,
  });

  @override
  ConsumerState<MenuDetailPage> createState() => _MenuDetailPageState();
}

class _MenuDetailPageState extends ConsumerState<MenuDetailPage>
    with SingleTickerProviderStateMixin {
  int _quantity = 1;
  final TextEditingController _notesController = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  String get _categoryIcon {
    switch (widget.menu.category) {
      case 'Mie Goreng': return '🍜';
      case 'Kopi': return '☕';
      case 'Nasi Goreng': return '🍚';
      case 'Dimsum': return '🥟';
      default: return '🍽️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _quantity * widget.menu.price;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // App Bar with hero image area
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: const Color(0xFF4F7FFF),
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                  tooltip: 'Chat dengan penjual',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        vendorId: widget.vendorId,
                        vendorName: widget.vendorName,
                      ),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: widget.menu.imageUrl != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(widget.menu.imageUrl!, fit: BoxFit.cover),
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black38],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4F7FFF), Color(0xFF8BA7FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _categoryIcon,
                            style: const TextStyle(fontSize: 100),
                          ),
                        ),
                      ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    if (widget.menu.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.menu.category!,
                          style: const TextStyle(
                            color: Color(0xFF4F7FFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Name & Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.menu.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.menu.price.toRupiah(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE67E22),
                              ),
                            ),
                            const Text('/ porsi', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Vendor info
                    Row(
                      children: [
                        const Icon(Icons.storefront_outlined, size: 16, color: Color(0xFF4F7FFF)),
                        const SizedBox(width: 6),
                        Text(
                          widget.vendorName,
                          style: const TextStyle(
                            color: Color(0xFF4F7FFF),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        // Rating placeholder
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        const Text('4.8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const Text(' (120)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Divider(),
                    const SizedBox(height: 16),

                    // Description
                    const Text(
                      'Tentang Menu Ini',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.menu.description ?? 'Menu lezat pilihan stan ini. Dibuat dengan bahan-bahan segar setiap harinya.',
                      style: const TextStyle(color: Colors.grey, height: 1.6, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // Info chips
                    Row(
                      children: [
                        _infoChip(Icons.access_time, '5-10 menit'),
                        const SizedBox(width: 12),
                        _infoChip(Icons.local_fire_department, 'Populer'),
                        const SizedBox(width: 12),
                        _infoChip(Icons.eco_outlined, 'Segar'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Notes
                    const Text(
                      'Catatan untuk Penjual',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText: 'Cth: tanpa bawang, tingkat kepedasan, dll...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF4F7FFF), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        prefixIcon: const Icon(Icons.sticky_note_2_outlined, color: Colors.grey),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom action bar
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Qty selector
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _qtyButton(Icons.remove, () {
                    if (_quantity > 1) setState(() => _quantity--);
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _qtyButton(Icons.add, () => setState(() => _quantity++)),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Add to cart button
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  for (int i = 0; i < _quantity; i++) {
                    ref.read(cartNotifierProvider.notifier).addToCart(widget.menu);
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('${_quantity}x ${widget.menu.name} ditambahkan'),
                        ],
                      ),
                      backgroundColor: const Color(0xFF2ECC71),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F7FFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tambah ke Keranjang',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      totalPrice.toRupiah(),
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
