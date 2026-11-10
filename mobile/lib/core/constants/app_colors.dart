import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand colors (Drapeau Burundi)
  static const Color primary = Color(0xFF003F87); // Bleu
  static const Color success = Color(0xFF1EB53A); // Vert
  static const Color error = Color(0xFFCE1126); // Rouge
  static const Color white = Color(0xFFFFFFFF);

  // Extended palette
  static const Color primaryLight = Color(0xFF1A5FB4);
  static const Color primaryDark = Color(0xFF002D6E);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color warning = Color(0xFFF59E0B);
  static const Color shimmerBase = Color(0xFFE5E7EB);
  static const Color shimmerHighlight = Color(0xFFF3F4F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient burundiGradient = LinearGradient(
    colors: [primary, success],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
