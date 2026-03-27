import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/listing.dart';
import '../../data/listings_repository.dart';

// ── Category model ────────────────────────────────────────────────────────────

class HomeCategory {
  final String name;
  final IconData icon;

  const HomeCategory({required this.name, required this.icon});
}

const List<HomeCategory> homeCategories = [
  HomeCategory(name: 'الكل', icon: Icons.apps_rounded),
  HomeCategory(name: 'شقة', icon: Icons.apartment_rounded),
  HomeCategory(name: 'فيلا', icon: Icons.house_rounded),
  HomeCategory(name: 'أرض', icon: Icons.landscape_rounded),
  HomeCategory(name: 'تجاري', icon: Icons.business_center_rounded),
  HomeCategory(name: 'دوبلكس', icon: Icons.villa_rounded),
  HomeCategory(name: 'استراحة', icon: Icons.holiday_village_rounded),
  HomeCategory(name: 'عمارة', icon: Icons.domain_rounded),
];

// ── Listings async loader ─────────────────────────────────────────────────────

class ListingsNotifier extends AsyncNotifier<List<Listing>> {
  final _repo = ListingsRepository();

  @override
  Future<List<Listing>> build() {
    print('=== ListingsNotifier.build() called');
    return _repo.getListings();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getListings());
  }
}

final listingsNotifierProvider =
    AsyncNotifierProvider<ListingsNotifier, List<Listing>>(
        ListingsNotifier.new);

// ── Category selection ────────────────────────────────────────────────────────

class SelectedCategoryNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, int>(
        SelectedCategoryNotifier.new);

// ── Filtered listings (synchronous, derived from async state) ─────────────────

final listingsIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(listingsNotifierProvider).isLoading;
});

final filteredListingsProvider = Provider<List<Listing>>((ref) {
  final idx = ref.watch(selectedCategoryProvider);
  final listings = ref.watch(listingsNotifierProvider).when(
    data: (data) => data,
    loading: () => <Listing>[],
    error: (_, __) => <Listing>[],
  );
  if (idx == 0) return listings;
  final catName = homeCategories[idx].name;
  return listings.where((l) => l.category == catName).toList();
});

// ── Favorites ─────────────────────────────────────────────────────────────────

class FavoritedIdsNotifier extends Notifier<Set<String>> {
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

final favoritedIdsProvider =
    NotifierProvider<FavoritedIdsNotifier, Set<String>>(
        FavoritedIdsNotifier.new);

final favoritedListingsProvider = Provider<List<Listing>>((ref) {
  final ids = ref.watch(favoritedIdsProvider);
  final listings = ref.watch(listingsNotifierProvider).when(
    data: (data) => data,
    loading: () => <Listing>[],
    error: (_, __) => <Listing>[],
  );
  return listings.where((l) => ids.contains(l.id)).toList();
});
