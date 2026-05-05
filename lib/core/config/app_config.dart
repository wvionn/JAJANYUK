/// Application configuration constants
class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // App Constants
  static const String appName = 'Esa Eats';
  static const String appVersion = '1.0.0';

  // API Endpoints (if needed)
  static const Duration apiTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';
  static const String campusIdKey = 'campus_id';
}
