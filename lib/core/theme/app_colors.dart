import 'package:flutter/material.dart';

/// Centralized color palette for the Dhikr Counter app.
///
/// The palette is inspired by calm, Islamic-leaning tones: deep teal/emerald
/// greens, warm sand neutrals and a muted gold accent. Colors are intentionally
/// soft to keep the experience distraction-free.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF1F6E5E); // deep emerald
  static const Color primaryLight = Color(0xFF2E9C84);
  static const Color primaryDark = Color(0xFF124A3F);
  static const Color accent = Color(0xFFC9A24B); // muted gold

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFF6F4EE); // warm sand
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEFEBE1);
  static const Color lightTextPrimary = Color(0xFF1B2420);
  static const Color lightTextSecondary = Color(0xFF6B7771);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF0E1614);
  static const Color darkSurface = Color(0xFF16201D);
  static const Color darkSurfaceAlt = Color(0xFF1E2C28);
  static const Color darkTextPrimary = Color(0xFFEDF2EF);
  static const Color darkTextSecondary = Color(0xFF9AA8A2);

  // Semantic
  static const Color success = Color(0xFF3FA796);
  static const Color warning = Color(0xFFE0A458);
  static const Color error = Color(0xFFD16161);

  /// A curated set of palette colors users can pick for their categories.
  static const List<Color> categoryPalette = [
    Color(0xFF1F6E5E),
    Color(0xFF2E9C84),
    Color(0xFFC9A24B),
    Color(0xFF4C7EA8),
    Color(0xFF8E6CB5),
    Color(0xFFC76B7A),
    Color(0xFFD98E4A),
    Color(0xFF5BA36F),
    Color(0xFF3C8DAD),
    Color(0xFF9C5A8F),
    Color(0xFF6E7B8B),
    Color(0xFFB05C3B),
  ];
}
