import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/profile_providers.dart';

class AddressPage extends ConsumerStatefulWidget {
  const AddressPage({super.key});

  @override
  ConsumerState<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends ConsumerState<AddressPage> {
  String _selectedGedung = 'Gedung A';
  String _selectedLantai = 'Lantai 1';
  final TextEditingController _detailController = TextEditingController();

  final List<String> _gedungList = ['Gedung A', 'Gedung B', 'Lobi', 'Taman'];
  final List<String> _lantaiList = ['Lantai 1', 'Lantai 2', 'Lantai 3', 'Lantai 4', 'Lantai 5'];

  @override
  void initState() {
    super.initState();
    final currentAddress = ref.read(deliveryAddressProvider);
    _parseAddress(currentAddress);
  }

  void _parseAddress(String address) {
    for (final g in _gedungList) {
      if (address.contains(g)) {
        _selectedGedung = g;
        break;
      }
    }
    for (final l in _lantaiList) {
      if (address.contains(l)) {
        _selectedLantai = l;
        break;
      }
    }
    final startBracket = address.indexOf('(');
    final endBracket = address.indexOf(')');
    if (startBracket != -1 && endBracket != -1 && endBracket > startBracket) {
      _detailController.text = address.substring(startBracket + 1, endBracket);
    } else {
      final parts = address.split(',');
      if (parts.length > 2) {
        _detailController.text = parts.sublist(2).join(',').trim();
      }
    }
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showLantai = _selectedGedung == 'Gedung A' || _selectedGedung == 'Gedung B';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Lokasi Pengiriman', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Gedung / Area',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGedung,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: _gedungList.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item, style: const TextStyle(fontSize: 15)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedGedung = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
            if (showLantai) ...[
              const SizedBox(height: 20),
              const Text(
                'Pilih Lantai',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLantai,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: _lantaiList.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item, style: const TextStyle(fontSize: 15)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedLantai = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Detail Lokasi / Catatan (Opsional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _detailController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Dekat lift, Meja nomor 3, Depan Gazebo kiri',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                String formattedAddress = _selectedGedung;
                if (showLantai) {
                  formattedAddress += ', $_selectedLantai';
                }
                if (_detailController.text.trim().isNotEmpty) {
                  formattedAddress += ' (${_detailController.text.trim()})';
                }

                ref.read(deliveryAddressProvider.notifier).state = formattedAddress;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lokasi pengiriman berhasil disimpan'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Simpan Lokasi',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
