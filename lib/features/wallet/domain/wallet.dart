import 'package:flutter/material.dart';
// ── Transaction type ──────────────────────────────────────────────────────────

enum TransactionType {
  topUp,
  promotion,
  subscription,
  booking,
  refund,
  unknown,
}

extension TransactionTypeX on TransactionType {
  IconData get icon {
    switch (this) {
      case TransactionType.unknown:
        return Icons.receipt_long_outlined;
      case TransactionType.topUp:
        return Icons.add_card_rounded;
      case TransactionType.promotion:
        return Icons.rocket_launch_rounded;
      case TransactionType.subscription:
        return Icons.workspace_premium_rounded;
      case TransactionType.booking:
        return Icons.calendar_month_rounded;
      case TransactionType.refund:
        return Icons.undo_rounded;
    }
  }

  Color get color {
    switch (this) {
      case TransactionType.unknown:
        return const Color(0xFF717171);
      case TransactionType.topUp:
        return const Color(0xFF00A699);
      case TransactionType.promotion:
        return const Color(0xFFF5A623);
      case TransactionType.subscription:
        return const Color(0xFF9C27B0);
      case TransactionType.booking:
        return const Color(0xFF2196F3);
      case TransactionType.refund:
        return const Color(0xFF00A699);
    }
  }
}

// ── Filter ────────────────────────────────────────────────────────────────────

enum TransactionFilter { all, topUps, promotions, subscriptions, bookings }

extension TransactionFilterX on TransactionFilter {
  String get label {
    switch (this) {
      case TransactionFilter.all:
        return 'الكل';
      case TransactionFilter.topUps:
        return 'الشحن';
      case TransactionFilter.promotions:
        return 'التمييز';
      case TransactionFilter.subscriptions:
        return 'الاشتراكات';
      case TransactionFilter.bookings:
        return 'الحجوزات';
    }
  }

  /// Maps to the `referenceType` query param the API expects.
  String? get referenceType {
    switch (this) {
      case TransactionFilter.all:
        return null;
      case TransactionFilter.topUps:
        return 'top_up';
      case TransactionFilter.promotions:
        return 'promotion';
      case TransactionFilter.subscriptions:
        return 'subscription';
      case TransactionFilter.bookings:
        return 'booking';
    }
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class WalletTransaction {
  final String id;
  final String? rawDirection;
  final TransactionType type;
  final String description;
  final double amount; // positive = credit, negative = debit
  final DateTime dateTime;

  const WalletTransaction({
    this.rawDirection,
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.dateTime,
  });

  String get direction => rawDirection ?? (amount < 0 ? 'debit' : 'credit');
  bool get isCredit => direction == 'credit';
  bool get isDebit => direction == 'debit';
  double get signedAmount => isDebit ? -amount.abs() : amount.abs();

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    final rawType = (json['referenceType'] ?? json['type'] ?? '').toString();
    final type = _parseTransactionType(rawType);
    final rawAmount = double.tryParse(json['amount']?.toString() ?? '');
    final txType = (json['type'] ?? '').toString();
    if (rawAmount == null || !rawAmount.isFinite) {
      throw const FormatException('Invalid wallet amount');
    }
    final amount = rawAmount.abs();
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    if (createdAt == null) throw const FormatException('Invalid wallet date');

    return WalletTransaction(
      rawDirection: txType,
      id: (json['id'] ?? '').toString(),
      type: type,
      description: (json['description'] ?? _defaultDescription(type))
          .toString(),
      amount: amount,
      dateTime: createdAt,
    );
  }

  static TransactionType _parseTransactionType(String raw) {
    switch (raw) {
      case 'top_up':
        return TransactionType.topUp;
      case 'promotion':
        return TransactionType.promotion;
      case 'subscription':
        return TransactionType.subscription;
      case 'booking':
        return TransactionType.booking;
      case 'refund':
        return TransactionType.refund;
      default:
        return TransactionType.unknown;
    }
  }

  static String _defaultDescription(TransactionType type) {
    switch (type) {
      case TransactionType.unknown:
        return 'معاملة';
      case TransactionType.topUp:
        return 'شحن محفظة';
      case TransactionType.promotion:
        return 'تمييز إعلان';
      case TransactionType.subscription:
        return 'اشتراك';
      case TransactionType.booking:
        return 'حجز';
      case TransactionType.refund:
        return 'استرداد';
    }
  }
}

Map<String, dynamic> walletTransactionQuery({
  int page = 1,
  int limit = 20,
  String direction = 'all',
  TransactionFilter purpose = TransactionFilter.all,
}) => {
  'page': page,
  'limit': limit,
  if (direction == 'credit' || direction == 'debit') 'type': direction,
  if (purpose.referenceType != null) 'referenceType': purpose.referenceType,
};
