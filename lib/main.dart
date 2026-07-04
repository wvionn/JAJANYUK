import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Initialize locale data for Indonesian date formatting
    await initializeDateFormatting('id_ID', null);

    // Initialize Supabase
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );

    // Sync database: activate all campuses and distribute vendors
    try {
      final client = Supabase.instance.client;
      // 1. Activate all campuses
      await client
          .from('campuses')
          .update({'is_active': true})
          .neq('id', '00000000-0000-0000-0000-000000000000');

      // 2. Fetch campuses and vendors to distribute
      final campuses = await client.from('campuses').select().order('name');
      final vendors = await client.from('vendors').select().order('name');

      if (campuses.isNotEmpty && vendors.isNotEmpty) {
        for (int i = 0; i < vendors.length; i++) {
          final campus = campuses[i % campuses.length];
          await client
              .from('vendors')
              .update({'campus_id': campus['id']})
              .eq('id', vendors[i]['id']);
        }
      }
      debugPrint('DB SYNC SUCCESS: Campuses activated, vendors distributed.');
    } catch (e) {
      debugPrint('DB SYNC ERROR: $e');
    }

    runApp(
      const ProviderScope(
        child: EsaEatsApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint("CRITICAL INITIALIZATION ERROR: $e");
    debugPrint(stackTrace.toString());
    
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal Inisialisasi Aplikasi',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => main(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A80F0),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EsaEatsApp extends ConsumerWidget {
  const EsaEatsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Esa Eats',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
