import 'package:flutter/material.dart';

import '../../core/constants/category_icons.dart';

/// A dhikr category (e.g. SubhanAllah). Pure domain entity, framework-light.
@immutable
class DhikrCategory {
  const DhikrCategory({
    required this.id,
    required this.name,
    this.arabic,
    this.description,
    this.transliteration,
    required this.colorValue,
    required this.iconCodePoint,
    this.dailyTarget,
    required this.lifetimeCount,
    required this.sortOrder,
    this.isArchived = false,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? arabic;
  final String? transliteration;
  final String? description;

  /// Stored as an ARGB int.
  final int colorValue;

  /// Material icon code point.
  final int iconCodePoint;

  /// Optional daily goal. Null means "no target".
  final int? dailyTarget;

  /// Cumulative count for all time (denormalized for fast home rendering).
  final int lifetimeCount;

  final int sortOrder;
  final bool isArchived;
  final DateTime createdAt;

  Color get color => Color(colorValue);

  IconData get icon => CategoryIcons.fromCodePoint(iconCodePoint);

  bool get hasTarget => dailyTarget != null && dailyTarget! > 0;

  DhikrCategory copyWith({
    String? name,
    String? arabic,
    String? transliteration,
    String? description,
    int? colorValue,
    int? iconCodePoint,
    int? dailyTarget,
    bool clearTarget = false,
    int? lifetimeCount,
    int? sortOrder,
    bool? isArchived,
  }) {
    return DhikrCategory(
      id: id,
      name: name ?? this.name,
      arabic: arabic ?? this.arabic,
      transliteration: transliteration ?? this.transliteration,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      dailyTarget: clearTarget ? null : (dailyTarget ?? this.dailyTarget),
      lifetimeCount: lifetimeCount ?? this.lifetimeCount,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DhikrCategory &&
      other.id == id &&
      other.name == name &&
      other.lifetimeCount == lifetimeCount &&
      other.dailyTarget == dailyTarget &&
      other.colorValue == colorValue &&
      other.iconCodePoint == iconCodePoint &&
      other.sortOrder == sortOrder &&
      other.isArchived == isArchived;

  @override
  int get hashCode => Object.hash(id, name, lifetimeCount, dailyTarget,
      colorValue, iconCodePoint, sortOrder, isArchived);
}
