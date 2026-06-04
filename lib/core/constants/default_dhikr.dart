import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A seed definition for the default dhikr categories created on first launch.
class DefaultDhikr {
  const DefaultDhikr({
    required this.name,
    required this.arabic,
    required this.transliteration,
    required this.description,
    required this.color,
    required this.iconCodePoint,
    required this.target,
  });

  final String name;
  final String arabic;
  final String transliteration;
  final String description;
  final Color color;
  final int iconCodePoint;
  final int target;

  static final List<DefaultDhikr> all = [
    DefaultDhikr(
      name: 'SubhanAllah',
      arabic: 'سُبْحَانَ ٱللَّٰه',
      transliteration: 'Subhan Allah',
      description: 'Glory be to Allah',
      color: AppColors.categoryPalette[0],
      iconCodePoint: Icons.spa_outlined.codePoint,
      target: 33,
    ),
    DefaultDhikr(
      name: 'Alhamdulillah',
      arabic: 'ٱلْحَمْدُ لِلَّٰه',
      transliteration: 'Alhamdulillah',
      description: 'All praise is due to Allah',
      color: AppColors.categoryPalette[1],
      iconCodePoint: Icons.favorite_outline.codePoint,
      target: 33,
    ),
    DefaultDhikr(
      name: 'Allahu Akbar',
      arabic: 'ٱللَّٰهُ أَكْبَر',
      transliteration: 'Allahu Akbar',
      description: 'Allah is the Greatest',
      color: AppColors.categoryPalette[2],
      iconCodePoint: Icons.star_outline.codePoint,
      target: 34,
    ),
    DefaultDhikr(
      name: 'Astaghfirullah',
      arabic: 'أَسْتَغْفِرُ ٱللَّٰه',
      transliteration: 'Astaghfirullah',
      description: 'I seek forgiveness from Allah',
      color: AppColors.categoryPalette[3],
      iconCodePoint: Icons.self_improvement_outlined.codePoint,
      target: 100,
    ),
    DefaultDhikr(
      name: 'La ilaha illallah',
      arabic: 'لَا إِلَٰهَ إِلَّا ٱللَّٰه',
      transliteration: 'La ilaha illallah',
      description: 'There is no deity but Allah',
      color: AppColors.categoryPalette[4],
      iconCodePoint: Icons.brightness_low_outlined.codePoint,
      target: 100,
    ),
    DefaultDhikr(
      name: 'Durood Sharif',
      arabic: 'ٱللَّٰهُمَّ صَلِّ عَلَىٰ مُحَمَّد',
      transliteration: 'Allahumma salli ala Muhammad',
      description: 'Blessings upon the Prophet ﷺ',
      color: AppColors.categoryPalette[5],
      iconCodePoint: Icons.mosque_outlined.codePoint,
      target: 100,
    ),
  ];
}
