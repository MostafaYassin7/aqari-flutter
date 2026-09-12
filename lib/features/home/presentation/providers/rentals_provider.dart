import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/rental.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/listings_repository.dart';

// ── Date range ────────────────────────────────────────────────────────────────

class RentalDateRange {
  final DateTime? checkIn;
  final DateTime? checkOut;

  const RentalDateRange({this.checkIn, this.checkOut});

  bool get hasRange => checkIn != null && checkOut != null;

  int get nights {
    if (!hasRange) return 0;
    return DateTime.utc(checkOut!.year, checkOut!.month, checkOut!.day)
        .difference(DateTime.utc(checkIn!.year, checkIn!.month, checkIn!.day))
        .inDays;
  }

  RentalDateRange copyWith({
    DateTime? checkIn,
    DateTime? checkOut,
    bool clearCheckIn = false,
    bool clearCheckOut = false,
  }) => RentalDateRange(
    checkIn: clearCheckIn ? null : (checkIn ?? this.checkIn),
    checkOut: clearCheckOut ? null : (checkOut ?? this.checkOut),
  );
}

// ── Filter state providers ────────────────────────────────────────────────────

class SelectedRentalCityNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? city) => state = city;
}

final selectedRentalCityProvider =
    NotifierProvider<SelectedRentalCityNotifier, String?>(
      SelectedRentalCityNotifier.new,
    );

class SelectedRentalPropertyTypeNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? type) => state = type;
}

final selectedRentalPropertyTypeProvider =
    NotifierProvider<SelectedRentalPropertyTypeNotifier, String?>(
      SelectedRentalPropertyTypeNotifier.new,
    );

class RentalDateRangeNotifier extends Notifier<RentalDateRange> {
  @override
  RentalDateRange build() {
    ref.listen(authProvider.select((s) => s.user?.id), (previous, next) {
      if (previous != null && previous != next) clear();
    });
    return const RentalDateRange();
  }

  void setRange(DateTime checkIn, DateTime checkOut) =>
      state = RentalDateRange(checkIn: checkIn, checkOut: checkOut);

  void clear() => state = const RentalDateRange();
}

final rentalDateRangeProvider =
    NotifierProvider<RentalDateRangeNotifier, RentalDateRange>(
      RentalDateRangeNotifier.new,
    );

class RentalGuestCountNotifier extends Notifier<int> {
  @override
  int build() => 1;
  void increment() => state = state + 1;
  void decrement() {
    if (state > 1) state = state - 1;
  }
}

final rentalGuestCountProvider =
    NotifierProvider<RentalGuestCountNotifier, int>(
      RentalGuestCountNotifier.new,
    );

// ── Rentals async loader with server-side filters ─────────────────────────────

final rentalListingsRepositoryProvider = Provider(
  (ref) => ListingsRepository(),
);

class RentalsNotifier extends AsyncNotifier<List<DailyRental>> {
  int _page = 1, _generation = 0;
  bool _loadingMore = false;
  bool hasMore = true;

  @override
  Future<List<DailyRental>> build() async {
    final generation = ++_generation;
    _page = 1;
    _loadingMore = false;
    hasMore = true;
    final repo = ref.watch(rentalListingsRepositoryProvider);
    final city = ref.watch(selectedRentalCityProvider);
    final propertyType = ref.watch(selectedRentalPropertyTypeProvider);
    final result = await repo.getDailyRentalPage(
      city: city,
      propertyType: propertyType,
    );
    if (ref.mounted && generation == _generation) hasMore = result.hasMore;
    return result.items;
  }

  Future<void> loadMore() async {
    if (!hasMore || _loadingMore || state.isLoading) return;
    final current = state.value;
    if (current == null) return;
    final generation = _generation;
    _loadingMore = true;
    try {
      final result = await ref
          .read(rentalListingsRepositoryProvider)
          .getDailyRentalPage(
            page: _page + 1,
            city: ref.read(selectedRentalCityProvider),
            propertyType: ref.read(selectedRentalPropertyTypeProvider),
          );
      if (!ref.mounted || generation != _generation) return;
      _page++;
      hasMore = result.hasMore;
      state = AsyncData(
        {
          for (final item in [...current, ...result.items]) item.id: item,
        }.values.toList(),
      );
    } finally {
      if (ref.mounted && generation == _generation) _loadingMore = false;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final rentalsNotifierProvider =
    AsyncNotifierProvider<RentalsNotifier, List<DailyRental>>(
      RentalsNotifier.new,
    );

// ── Filtered rentals (pass-through, filtering is server-side) ─────────────────

final filteredRentalsProvider = Provider<List<DailyRental>>((ref) {
  return ref
      .watch(rentalsNotifierProvider)
      .when(
        data: (data) => data,
        loading: () => <DailyRental>[],
        error: (_, __) => <DailyRental>[],
      );
});

// ── Favorited rentals ─────────────────────────────────────────────────────────

class FavoritedRentalsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};
  void toggle(String id) {
    if (state.contains(id)) {
      state = Set.from(state)..remove(id);
    } else {
      state = Set.from(state)..add(id);
    }
    // Fire-and-forget API call
    ListingsRepository().toggleFavorite(targetId: id);
  }
}

final favoritedRentalsProvider =
    NotifierProvider<FavoritedRentalsNotifier, Set<String>>(
      FavoritedRentalsNotifier.new,
    );
