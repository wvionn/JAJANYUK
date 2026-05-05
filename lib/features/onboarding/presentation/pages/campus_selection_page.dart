import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';

class CampusSelectionPage extends ConsumerStatefulWidget {
  const CampusSelectionPage({super.key});

  @override
  ConsumerState<CampusSelectionPage> createState() =>
      _CampusSelectionPageState();
}

class _CampusSelectionPageState extends ConsumerState<CampusSelectionPage> {
  String? _selectedCampus;

  final List<CampusData> _campuses = [
    CampusData(
      id: '1',
      name: 'Universitas Esa Unggul, Jakarta',
      imageUrl: 'assets/images/campus1.jpg',
    ),
    // Add more campuses as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F0FE), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Kampus',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tentukan lokasi kampus kamu untuk melanjutkan',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView.builder(
                    itemCount: _campuses.length,
                    itemBuilder: (context, index) {
                      final campus = _campuses[index];
                      return _buildCampusCard(campus);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Next',
                  onPressed: _selectedCampus != null
                      ? () {
                          // Save selected campus
                          context.go(RouteNames.login);
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCampusCard(CampusData campus) {
    final isSelected = _selectedCampus == campus.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCampus = campus.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                campus.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}

class CampusData {
  final String id;
  final String name;
  final String imageUrl;

  CampusData({required this.id, required this.name, required this.imageUrl});
}
