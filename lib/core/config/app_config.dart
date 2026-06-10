import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration constants
class AppConfig {
  // Supabase Configuration from environment variables
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'YOUR_SUPABASE_URL';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'YOUR_SUPABASE_ANON_KEY';

  // App Constants
  static const String appName = 'Esa Eats';
  static const String appVersion = '1.0.0';

  // Campus Locations
  static const List<String> campusLocations = [
    'Universitas Esa Unggul, Jakarta',
    'Kampus Tangerang',
    'Kampus Bekasi',
  ];
}
