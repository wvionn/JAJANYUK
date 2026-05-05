import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF5B8DEE); // Blue
  static const Color secondary = Color(0xFFFA842B); // Orange

  // Background Colors
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color inputBackground = Color(0xFFE8F0FE);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Order Status Colors
  static const Color orderPending = Color(0xFFFFA726);
  static const Color orderProcessing = Color(0xFF29B6F6);
  static const Color orderReady = Color(0xFF66BB6A);
  static const Color orderCompleted = Color(0xFF4CAF50);
  static const Color orderCancelled = Color(0xFFE53935);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF5B8DEE), Color(0xFF7BA5F4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFFA842B), Color(0xFFFF9F4D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
