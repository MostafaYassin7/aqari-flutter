import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/rental.dart';
import '../../data/listings_repository.dart';

// ── Rental category model ─────────────────────────────────────────────────────

class RentalCategory {
  final String name;
  final IconData icon;
  const RentalCategory({required this.name, required this.icon});
}

const List<RentalCategory> rentalCategories = [
  RentalCategory(name: 'الكل', icon: Icons.apps_rounded),
  RentalCategory(name: 'شقة', icon: Icons.apartment_rounded),
  RentalCategory(name: 'شاليه', icon: Icons.beach_access_rounded),
  RentalCategory(name: 'استراحة', icon: Icons.holiday_village_rounded),
  RentalCategory(name: 'فيلا', icon: Icons.house_rounded),
];

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
  }) =>
      RentalDateRange(
        checkIn: clearCheckIn ? null : (checkIn ?? this.checkIn),
        checkOut: clearCheckOut ? null : (checkOut ?? this.checkOut),
      );
}

// ── Providers ─────────────────────────────────────────────────────────────────

class SelectedRentalCategoryNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void select(int index) => state = index;
}

final selectedRentalCategoryProvider =
    NotifierProvider<SelectedRentalCategoryNotifier, int>(
        SelectedRentalCategoryNotifier.new);

class RentalDateRangeNotifier extends Notifier<RentalDateRange> {
  @override
  RentalDateRange build() => const RentalDateRange();

  void setRange(DateTime checkIn, DateTime checkOut) =>
      state = RentalDateRange(checkIn: checkIn, checkOut: checkOut);

  void clear() => state = const RentalDateRange();
}

final rentalDateRangeProvider =
    NotifierProvider<RentalDateRangeNotifier, RentalDateRange>(
        RentalDateRangeNotifier.new);

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
        RentalGuestCountNotifier.new);

// ── Rentals async loader ──────────────────────────────────────────────────────

class RentalsNotifier extends AsyncNotifier<List<DailyRental>> {
  final _repo = ListingsRepository();

  @override
  Future<List<DailyRental>> build() => _repo.getDailyRentals();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getDailyRentals());
  }
}

final rentalsNotifierProvider =
    AsyncNotifierProvider<RentalsNotifier, List<DailyRental>>(
        RentalsNotifier.new);

// ── Filtered rentals (synchronous, derived from async state) ──────────────────

final filteredRentalsProvider = Provider<List<DailyRental>>((ref) {
  final idx = ref.watch(selectedRentalCategoryProvider);
  final rentals = ref.watch(rentalsNotifierProvider).when(
    data: (data) => data,
    loading: () => <DailyRental>[],
    error: (_, __) => <DailyRental>[],
  );
  if (idx == 0) return rentals;
  final catName = rentalCategories[idx].name;
  return rentals.where((r) => r.category == catName).toList();
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
        FavoritedRentalsNotifier.new);
