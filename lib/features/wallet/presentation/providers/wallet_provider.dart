import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Transaction type ──────────────────────────────────────────────────────────

enum TransactionType { topUp, promotion, subscription, booking, refund }

extension TransactionTypeX on TransactionType {
  IconData get icon {
    switch (this) {
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
}

// ── Model ─────────────────────────────────────────────────────────────────────

class WalletTransaction {
  final String id;
  final TransactionType type;
  final String description;
  final double amount; // positive = credit, negative = debit
  final DateTime dateTime;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.dateTime,
  });

  bool get isCredit => amount > 0;
}

// ── Mock data ─────────────────────────────────────────────────────────────────

final _now = DateTime.now();

final _mockTransactions = <WalletTransaction>[
  WalletTransaction(
    id: 'tx1',
    type: TransactionType.topUp,
    description: 'شحن محفظة',
    amount: 500.0,
    dateTime: _now.subtract(const Duration(days: 2, hours: 3)),
  ),
  WalletTransaction(
    id: 'tx2',
    type: TransactionType.subscription,
    description: 'اشتراك شهري — باقة ذهبية',
    amount: -299.0,
    dateTime: _now.subtract(const Duration(days: 3, hours: 10)),
  ),
  WalletTransaction(
    id: 'tx3',
    type: TransactionType.promotion,
    description: 'تمييز إعلان — شقة فاخرة حي النرجس',
    amount: -120.0,
    dateTime: _now.subtract(const Duration(days: 5, hours: 6)),
  ),
  WalletTransaction(
    id: 'tx4',
    type: TransactionType.booking,
    description: 'إيراد حجز — شقة حي العليا (ليلتان)',
    amount: 850.0,
    dateTime: _now.subtract(const Duration(days: 8, hours: 14)),
  ),
  WalletTransaction(
    id: 'tx5',
    type: TransactionType.topUp,
    description: 'شحن محفظة',
    amount: 200.0,
    dateTime: _now.subtract(const Duration(days: 10, hours: 9)),
  ),
  WalletTransaction(
    id: 'tx6',
    type: TransactionType.promotion,
    description: 'رفع ترتيب إعلان — فيلا حي الياسمين',
    amount: -75.0,
    dateTime: _now.subtract(const Duration(days: 13, hours: 2)),
  ),
  WalletTransaction(
    id: 'tx7',
    type: TransactionType.refund,
    description: 'استرداد — إلغاء حجز استراحة النخيل',
    amount: 350.0,
    dateTime: _now.subtract(const Duration(days: 16, hours: 17)),
  ),
  WalletTransaction(
    id: 'tx8',
    type: TransactionType.booking,
    description: 'إيراد حجز — استراحة النخيل (3 ليالٍ)',
    amount: 1200.0,
    dateTime: _now.subtract(const Duration(days: 20, hours: 11)),
  ),
  WalletTransaction(
    id: 'tx9',
    type: TransactionType.subscription,
    description: 'اشتراك نصف سنوي — باقة بلاتينية',
    amount: -499.0,
    dateTime: _now.subtract(const Duration(days: 24, hours: 8)),
  ),
  WalletTransaction(
    id: 'tx10',
    type: TransactionType.promotion,
    description: 'إعلان مميز — أرض تجارية حي العليا',
    amount: -50.0,
    dateTime: _now.subtract(const Duration(days: 28, hours: 15)),
  ),
  WalletTransaction(
    id: 'tx11',
    type: TransactionType.topUp,
    description: 'شحن محفظة',
    amount: 1000.0,
    dateTime: _now.subtract(const Duration(days: 33, hours: 4)),
  ),
  WalletTransaction(
    id: 'tx12',
    type: TransactionType.booking,
    description: 'إيراد حجز — شقة مطلة على البحر (ليلة)',
    amount: 650.0,
    dateTime: _now.subtract(const Duration(days: 38, hours: 20)),
  ),
];

// ── State ─────────────────────────────────────────────────────────────────────

class WalletState {
  final double balance;
  final List<WalletTransaction> transactions;
  final TransactionFilter filter;

  const WalletState({
    required this.balance,
    required this.transactions,
    required this.filter,
  });

  List<WalletTransaction> get filtered {
    switch (filter) {
      case TransactionFilter.all:
        return transactions;
      case TransactionFilter.topUps:
        return transactions
            .where((t) => t.type == TransactionType.topUp)
            .toList();
      case TransactionFilter.promotions:
        return transactions
            .where((t) => t.type == TransactionType.promotion)
            .toList();
      case TransactionFilter.subscriptions:
        return transactions
            .where((t) => t.type == TransactionType.subscription)
            .toList();
      case TransactionFilter.bookings:
        return transactions
            .where((t) =>
                t.type == TransactionType.booking ||
                t.type == TransactionType.refund)
            .toList();
    }
  }

  WalletState copyWith({
    double? balance,
    List<WalletTransaction>? transactions,
    TransactionFilter? filter,
  }) =>
      WalletState(
        balance: balance ?? this.balance,
        transactions: transactions ?? this.transactions,
        filter: filter ?? this.filter,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class WalletNotifier extends Notifier<WalletState> {
  @override
  WalletState build() => WalletState(
        balance: 1250.0,
        transactions: _mockTransactions,
        filter: TransactionFilter.all,
      );

  void setFilter(TransactionFilter f) =>
      state = state.copyWith(filter: f);

  void topUp(double amount) {
    final tx = WalletTransaction(
      id: 'tx_new_${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.topUp,
      description: 'شحن محفظة',
      amount: amount,
      dateTime: DateTime.now(),
    );
    state = state.copyWith(
      balance: state.balance + amount,
      transactions: [tx, ...state.transactions],
    );
  }
}

final walletProvider =
    NotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);
