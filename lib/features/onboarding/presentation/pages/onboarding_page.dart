import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Selamat Datang di Kantin Online Kampus',
      description:
          'Pesan makanan favorit kamu dengan mudah dan cepat langsung dari kampus',
      image: 'assets/onboarding/logo.png',
    ),
    OnboardingData(
      title: 'Pengantaran cepat di lingkungan kampus',
      description: 'Dapatkan pesanan kamu dengan cepat tanpa harus antri',
      image: 'assets/onboarding/pesan-antar.png',
    ),
    OnboardingData(
      title: 'Dari mahasiswa, untuk mahasiswa',
      description:
          'Platform yang dibuat khusus untuk memudahkan mahasiswa memesan makanan',
      image: 'assets/onboarding/mhs.png',
    ),
    OnboardingData(
      title: 'Makan sesuai caramu',
      description: 'Pilih menu favorit, bayar dengan mudah, dan nikmati!',
      image: 'assets/onboarding/delivery.png',
    ),
    OnboardingData(
      title: 'Makan di kampus jadi lebih mudah',
      description: 'Hemat waktu dan tenaga dengan pesan online',
      image: 'assets/onboarding/pamflet.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, Color(0xFF7BA5F4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),
              _buildIndicator(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CustomButton(
                  text: _currentPage == _pages.length - 1 ? 'Mulai' : 'Next',
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      context.go(RouteNames.campusSelection);
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  backgroundColor: Colors.white,
                  textColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    final isPngIcon = data.image.endsWith('.png') && !data.image.contains('Gemini');

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: EdgeInsets.all(isPngIcon ? 24 : 0),
                child: Image.asset(
                  data.image,
                  fit: isPngIcon ? BoxFit.contain : BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String image;

  OnboardingData({
    required this.title,
    required this.description,
    required this.image,
  });
}