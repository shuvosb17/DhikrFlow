import 'package:intl/intl.dart';

/// Number and text formatting helpers.
class Formatters {
  Formatters._();

  static final NumberFormat _compact = NumberFormat.compact();
  static final NumberFormat _decimal = NumberFormat.decimalPattern();

  /// e.g. 1234 -> "1,234"
  static String number(num value) => _decimal.format(value);

  /// e.g. 12345 -> "12.3K"
  static String compact(num value) => _compact.format(value);

  /// Clamp a 0..1 fraction into a whole percentage string, e.g. "62%".
  static String percent(double fraction) {
    final clamped = fraction.clamp(0, 1);
    return '${(clamped * 100).round()}%';
  }

  static String pluralize(int count, String singular, [String? plural]) {
    if (count == 1) return '$count $singular';
    return '$count ${plural ?? '${singular}s'}';
  }
}
