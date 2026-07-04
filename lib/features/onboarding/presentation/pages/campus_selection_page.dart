import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../admin/domain/entities/campus_entity.dart';
import '../../../admin/data/models/campus_model.dart';

final onboardingCampusesProvider = FutureProvider<List<CampusEntity>>((ref) async {
  final client = Supabase.instance.client;
  final response = await client
      .from('campuses')
      .select()
      .order('name');
  
  return (response as List)
      .map((json) => CampusModel.fromJson(json))
      .where((campus) => campus.isActive)
      .toList();
});

final selectedCampusIdProvider = StateProvider<String?>((ref) => null);

class CampusSelectionPage extends ConsumerStatefulWidget {
  const CampusSelectionPage({super.key});

  @override
  ConsumerState<CampusSelectionPage> createState() =>
      _CampusSelectionPageState();
}

class _CampusSelectionPageState extends ConsumerState<CampusSelectionPage> {
  String? _selectedCampus;

  @override
  Widget build(BuildContext context) {
    final campusesAsync = ref.watch(onboardingCampusesProvider);

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
                  child: campusesAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (err, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text(
                            'Gagal memuat daftar kampus: $err',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => ref.refresh(onboardingCampusesProvider),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                    data: (campuses) {
                      if (campuses.isEmpty) {
                        return const Center(
                          child: Text(
                            'Tidak ada kampus aktif ditemukan',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: campuses.length,
                        itemBuilder: (context, index) {
                          final campus = campuses[index];
                          return _buildCampusCard(campus);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Next',
                  onPressed: _selectedCampus != null
                      ? () {
                          // Simpan kampus yang dipilih ke state provider
                          ref.read(selectedCampusIdProvider.notifier).state =
                              _selectedCampus;
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

  Widget _buildCampusImage(CampusEntity campus) {
    final nameLower = campus.name.toLowerCase();
    final cityLower = campus.city?.toLowerCase() ?? '';

    if (nameLower.contains('bekasi') || cityLower.contains('bekasi')) {
      return Image.asset(
        'assets/onboarding/esgul-bekasi.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(
            Icons.school,
            size: 40,
            color: AppColors.primary,
          ),
        ),
      );
    } else if (nameLower.contains('jakarta') || cityLower.contains('jakarta')) {
      return Image.asset(
        'assets/onboarding/esgul-jakarta.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(
            Icons.school,
            size: 40,
            color: AppColors.primary,
          ),
        ),
      );
    } else if (nameLower.contains('tangerang') || cityLower.contains('tangerang')) {
      return Image.asset(
        'assets/onboarding/esgul-tangerang.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(
            Icons.school,
            size: 40,
            color: AppColors.primary,
          ),
        ),
      );
    }else {
      return const Center(
        child: Icon(
          Icons.school,
          size: 40,
          color: AppColors.primary,
        ),
      );
    }
  }

  Widget _buildCampusCard(CampusEntity campus) {
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
              color: Colors.black.withValues(alpha: 0.05),
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
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildCampusImage(campus),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campus.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (campus.city != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      campus.city!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
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
