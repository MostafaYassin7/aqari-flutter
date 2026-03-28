import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/rental.dart';
import '../../data/listings_repository.dart';

// ── Date range ────────────────────────────────────────────────────────────────

class RentalDateRange {
  final DateTime? checkIn;
  final DateTime? checkOut;

  const RentalDateRange({this.checkIn, this.checkOut});

  bool get hasRange => checkIn != null && checkOut != null;

  int get nights {
    if (!hasRange) return 0;
    return checkOut!.difference(checkIn!).inDays;
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
  RentalDateRange build() => const RentalDateRange();

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

class RentalsNotifier extends AsyncNotifier<List<DailyRental>> {
  final _repo = ListingsRepository();
  int _page = 1;
  bool hasMore = true;

  @override
  Future<List<DailyRental>> build() {
    _page = 1;
    hasMore = true;
    final city = ref.watch(selectedRentalCityProvider);
    final propertyType = ref.watch(selectedRentalPropertyTypeProvider);
    return _repo.getDailyRentals(
      page: _page,
      limit: 20,
      city: city,
      propertyType: propertyType,
    );
  }

  Future<void> loadMore() async {
    if (!hasMore) return;
    final current = state.value;
    if (current == null) return;
    _page++;
    final city = ref.read(selectedRentalCityProvider);
    final propertyType = ref.read(selectedRentalPropertyTypeProvider);
    final newItems = await _repo.getDailyRentals(
      page: _page,
      limit: 20,
      city: city,
      propertyType: propertyType,
    );
    if (newItems.length < 20) hasMore = false;
    state = AsyncData([...current, ...newItems]);
  }

  Future<void> refresh() async {
    _page = 1;
    hasMore = true;
    final city = ref.read(selectedRentalCityProvider);
    final propertyType = ref.read(selectedRentalPropertyTypeProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.getDailyRentals(
        page: _page,
        limit: 20,
        city: city,
        propertyType: propertyType,
      ),
    );
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
  }
}

final favoritedRentalsProvider =
    NotifierProvider<FavoritedRentalsNotifier, Set<String>>(
      FavoritedRentalsNotifier.new,
    );
