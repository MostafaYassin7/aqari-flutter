import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

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

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    final rawType = (json['referenceType'] ?? json['type'] ?? '').toString();
    final type = _parseTransactionType(rawType);
    final rawAmount = double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0;
    // Negative for debits (promotion, subscription, booking), positive for credits
    final txType = (json['type'] ?? '').toString();
    final amount = txType == 'debit' ? -rawAmount.abs() : rawAmount.abs();

    return WalletTransaction(
      id: (json['id'] ?? '').toString(),
      type: type,
      description: (json['description'] ?? _defaultDescription(type))
          .toString(),
      amount: amount,
      dateTime:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
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
        return TransactionType.topUp;
    }
  }

  static String _defaultDescription(TransactionType type) {
    switch (type) {
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

// ── State ─────────────────────────────────────────────────────────────────────

class WalletState {
  final double balance;
  final String currency;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<WalletTransaction> transactions;
  final TransactionFilter filter;
  final int currentPage;
  final bool hasMore;

  const WalletState({
    required this.balance,
    this.currency = 'SAR',
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    required this.transactions,
    required this.filter,
    this.currentPage = 1,
    this.hasMore = true,
  });

  WalletState copyWith({
    double? balance,
    String? currency,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<WalletTransaction>? transactions,
    TransactionFilter? filter,
    int? currentPage,
    bool? hasMore,
  }) => WalletState(
    balance: balance ?? this.balance,
    currency: currency ?? this.currency,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    error: error,
    transactions: transactions ?? this.transactions,
    filter: filter ?? this.filter,
    currentPage: currentPage ?? this.currentPage,
    hasMore: hasMore ?? this.hasMore,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class WalletNotifier extends Notifier<WalletState> {
  static const _limit = 20;

  @override
  WalletState build() {
    Future.microtask(() async {
      await fetchWallet();
      await fetchTransactions();
    });
    return const WalletState(
      balance: 0,
      transactions: [],
      filter: TransactionFilter.all,
      isLoading: true,
    );
  }

  Future<void> fetchWallet() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.get(ApiEndpoints.wallet);
      final raw = response.data;
      if (raw is Map) {
        final data = Map<String, dynamic>.from(raw);
        final balance =
            double.tryParse(data['balance']?.toString() ?? '0') ?? 0.0;
        final currency = (data['currency'] ?? 'SAR').toString();
        state = state.copyWith(
          balance: balance,
          currency: currency,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchTransactions({bool reset = true}) async {
    if (reset) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 1,
        hasMore: true,
        transactions: [],
      );
    }

    try {
      final refType = state.filter.referenceType;
      final response = await apiClient.get(
        ApiEndpoints.walletTransactions,
        queryParameters: {
          'page': reset ? 1 : state.currentPage,
          'limit': _limit,
          if (refType != null) 'referenceType': refType,
        },
      );

      final raw = response.data;
      List<dynamic> items = [];
      if (raw is List) {
        items = raw;
      } else if (raw is Map) {
        final m = Map<String, dynamic>.from(raw);
        items = (m['data'] ?? m['items'] ?? m['hits'] ?? []) as List;
      }

      final newTx = items
          .whereType<Map>()
          .map((j) => WalletTransaction.fromJson(Map<String, dynamic>.from(j)))
          .toList();

      state = state.copyWith(
        transactions: reset ? newTx : [...state.transactions, ...newTx],
        currentPage: (reset ? 1 : state.currentPage) + 1,
        hasMore: newTx.length >= _limit,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    await fetchTransactions(reset: false);
  }

  void setFilter(TransactionFilter f) {
    if (f == state.filter) return;
    state = state.copyWith(filter: f);
    fetchTransactions();
  }

  Future<bool> topUp(double amount) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await apiClient.post(
        ApiEndpoints.walletTopUp,
        data: {'amount': amount, 'paymentMethod': 'card'},
      );
      await fetchWallet();
      await fetchTransactions();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final walletProvider = NotifierProvider<WalletNotifier, WalletState>(
  WalletNotifier.new,
);
