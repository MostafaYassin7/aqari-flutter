import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/preview/ui_preview.dart';
import '../../../../core/network/api_failure.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/wallet_repository.dart';
import '../../domain/wallet.dart';
export '../../domain/wallet.dart';

class WalletState {
  final double heldBalance, pendingEarnings;
  final double balance;
  final String currency;
  final String direction;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<WalletTransaction> transactions;
  final TransactionFilter filter;
  final int currentPage;
  final bool hasMore;

  const WalletState({
    this.heldBalance = 0,
    this.pendingEarnings = 0,
    required this.balance,
    this.currency = 'SAR',
    this.direction = 'all',
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    required this.transactions,
    required this.filter,
    this.currentPage = 1,
    this.hasMore = true,
  });

  WalletState copyWith({
    double? heldBalance,
    double? pendingEarnings,
    double? balance,
    String? currency,
    String? direction,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<WalletTransaction>? transactions,
    TransactionFilter? filter,
    int? currentPage,
    bool? hasMore,
  }) => WalletState(
    heldBalance: heldBalance ?? this.heldBalance,
    pendingEarnings: pendingEarnings ?? this.pendingEarnings,
    balance: balance ?? this.balance,
    currency: currency ?? this.currency,
    direction: direction ?? this.direction,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    error: error,
    transactions: transactions ?? this.transactions,
    filter: filter ?? this.filter,
    currentPage: currentPage ?? this.currentPage,
    hasMore: hasMore ?? this.hasMore,
  );
}

class WalletNotifier extends Notifier<WalletState> {
  int _generation = 0, _summaryGeneration = 0;
  @override
  WalletState build() {
    ref.watch(authProvider.select((s) => (s.user?.id, s.step)));
    ++_generation;
    ++_summaryGeneration;
    if (uiPreview) {
      return WalletState(
        balance: 2400,
        heldBalance: 900,
        pendingEarnings: 1800,
        transactions: sampleTransactions,
        filter: TransactionFilter.all,
        hasMore: false,
      );
    }
    Future.microtask(() {
      if (ref.mounted) refresh();
    });
    return const WalletState(
      balance: 0,
      transactions: [],
      filter: TransactionFilter.all,
      isLoading: true,
    );
  }

  Future<void> refresh() async {
    await Future.wait([fetchWallet(), fetchTransactions()]);
  }

  Future<void> fetchWallet() async {
    if (uiPreview) return;
    final generation = ++_summaryGeneration;
    try {
      final data = await ref.read(walletRepositoryProvider).summary();
      if (!ref.mounted || generation != _summaryGeneration) return;
      state = state.copyWith(
        balance: data.balance,
        heldBalance: data.held,
        pendingEarnings: data.pending,
        currency: data.currency,
        error: state.error,
      );
    } catch (e) {
      if (ref.mounted && generation == _summaryGeneration) {
        state = state.copyWith(error: ApiFailure.fromError(e).message);
      }
    }
  }

  Future<void> fetchTransactions({bool reset = true}) async {
    final generation = ++_generation;
    final page = reset ? 1 : state.currentPage;
    final purpose = state.filter;
    final direction = state.direction;
    if (uiPreview) {
      state = state.copyWith(
        transactions: sampleTransactions
            .where(
              (t) =>
                  (direction == 'all' || t.direction == direction) &&
                  (purpose == TransactionFilter.all ||
                      t.type.name ==
                          switch (purpose) {
                            TransactionFilter.topUps => 'topUp',
                            TransactionFilter.promotions => 'promotion',
                            TransactionFilter.subscriptions => 'subscription',
                            TransactionFilter.bookings => 'booking',
                            _ => '',
                          }),
            )
            .toList(),
        hasMore: false,
        isLoading: false,
        isLoadingMore: false,
      );
      return;
    }
    state = state.copyWith(
      isLoading: reset,
      isLoadingMore: !reset,
      transactions: reset ? [] : state.transactions,
      currentPage: page,
    );
    try {
      final result = await ref
          .read(walletRepositoryProvider)
          .transactions(page: page, purpose: purpose, direction: direction);
      if (!ref.mounted || generation != _generation) return;
      final unique = {
        for (final t in [
          ...(reset ? <WalletTransaction>[] : state.transactions),
          ...result.items,
        ])
          t.id: t,
      };
      state = state.copyWith(
        transactions: unique.values.toList(),
        currentPage: page + 1,
        hasMore: result.hasMore,
        isLoading: false,
        isLoadingMore: false,
        error: state.error,
      );
    } catch (e) {
      if (ref.mounted && generation == _generation) {
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: ApiFailure.fromError(e).message,
        );
      }
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    await fetchTransactions(reset: false);
  }

  void setFilter(TransactionFilter f) {
    if (f == state.filter) return;
    state = state.copyWith(filter: f);
    fetchTransactions();
  }

  void setDirection(String direction) {
    if (direction == state.direction) return;
    state = state.copyWith(direction: direction);
    fetchTransactions();
  }
}

final walletProvider = NotifierProvider<WalletNotifier, WalletState>(
  WalletNotifier.new,
);

List<WalletTransaction> get sampleTransactions => [
  WalletTransaction(
    id: 'preview-topup',
    type: TransactionType.topUp,
    description: 'شحن المحفظة',
    amount: 2000,
    dateTime: DateTime.now(),
  ),
  WalletTransaction(
    id: 'preview-booking',
    type: TransactionType.booking,
    description: 'حجز شاليه النخيل',
    amount: -900,
    dateTime: DateTime.now().subtract(const Duration(days: 1)),
  ),
  WalletTransaction(
    id: 'preview-earning',
    type: TransactionType.booking,
    description: 'إيراد حجز مكتمل',
    amount: 1300,
    dateTime: DateTime.now().subtract(const Duration(days: 4)),
  ),
  WalletTransaction(
    id: 'preview-promotion',
    type: TransactionType.promotion,
    description: 'تمييز إعلان',
    amount: -100,
    dateTime: DateTime.now().subtract(const Duration(days: 10)),
  ),
];
