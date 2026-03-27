class ParseHelpers {
  // Safely parse to double — handles String or num from PostgreSQL/Algolia
  static double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static double? toDoubleNullable(dynamic value) {
    if (value == null) return null;
    return toDouble(value);
  }

  static int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? toIntNullable(dynamic value) {
    if (value == null) return null;
    return toInt(value);
  }

  // Handles both ISO string (PostgreSQL) and Unix seconds int (Algolia)
  static DateTime toDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    return DateTime.now();
  }

  static DateTime? toDateTimeNullable(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    return null;
  }

  // Strip null values before sending to backend
  static Map<String, dynamic> buildBody(Map<String, dynamic> data) {
    return Map.fromEntries(
      data.entries.where((e) => e.value != null),
    );
  }

  // Format price for display: 750000 → "750K SAR"
  static String formatPrice(double price) {
    if (price >= 1000000) {
      final m = price / 1000000;
      return '${m == m.truncateToDouble() ? m.toInt() : m.toStringAsFixed(1)}M SAR';
    }
    if (price >= 1000) {
      final k = price / 1000;
      return '${k == k.truncateToDouble() ? k.toInt() : k.toStringAsFixed(0)}K SAR';
    }
    return '${price.toStringAsFixed(0)} SAR';
  }

  static String formatArea(double area) => '${area.toStringAsFixed(0)} m²';

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }
}
