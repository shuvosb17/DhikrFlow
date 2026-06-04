import 'package:flutter/material.dart';

/// Curated Material icons for dhikr categories.
///
/// Icons must come from this const list so release builds can tree-shake the
/// icon font. Do not construct [IconData] dynamically from stored code points.
class CategoryIcons {
  CategoryIcons._();

  static const IconData fallback = Icons.spa_outlined;

  /// Icons users can pick when creating or editing a category.
  static const List<IconData> choices = [
    Icons.spa_outlined,
    Icons.favorite_outline,
    Icons.star_outline,
    Icons.self_improvement_outlined,
    Icons.brightness_low_outlined,
    Icons.mosque_outlined,
    Icons.nights_stay_outlined,
    Icons.wb_sunny_outlined,
    Icons.water_drop_outlined,
    Icons.eco_outlined,
    Icons.menu_book_outlined,
    Icons.volunteer_activism_outlined,
    Icons.light_mode_outlined,
    Icons.bolt_outlined,
    Icons.diamond_outlined,
    Icons.shield_moon_outlined,
  ];

  /// Resolves a persisted code point to a const [IconData].
  static IconData fromCodePoint(int codePoint) {
    for (final icon in choices) {
      if (icon.codePoint == codePoint) return icon;
    }
    return fallback;
  }
}
