import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/listing.dart';
import '../../data/listings_repository.dart';

// ── Arabic display maps ───────────────────────────────────────────────────────

const Map<String, String> countryArabicNames = {
  'Egypt': 'مصر',
  'Saudi Arabia': 'السعودية',
  'United Arab Emirates': 'الإمارات',
  'Qatar': 'قطر',
  'Kuwait': 'الكويت',
  'Bahrain': 'البحرين',
  'Oman': 'عُمان',
  'Yemen': 'اليمن',
};

const Map<String, String> propertyTypeArabicNames = {
  'apartment': 'شقة',
  'villa': 'فيلا',
  'floor': 'دور',
  'land': 'أرض',
  'building': 'عمارة',
  'shop': 'محل',
  'house': 'منزل',
  'rest_house': 'استراحة',
  'farm': 'مزرعة',
  'commercial_office': 'مكتب تجاري',
  'chalet': 'شاليه',
  'warehouse': 'مستودع',
  'camp': 'مخيم',
  'other': 'أخرى',
};

const Map<String, IconData> propertyTypeIcons = {
  'apartment': Icons.apartment_rounded,
  'villa': Icons.house_rounded,
  'floor': Icons.layers_rounded,
  'land': Icons.landscape_rounded,
  'building': Icons.domain_rounded,
  'shop': Icons.storefront_rounded,
  'house': Icons.home_rounded,
  'rest_house': Icons.holiday_village_rounded,
  'farm': Icons.park_rounded,
  'commercial_office': Icons.business_center_rounded,
  'chalet': Icons.beach_access_rounded,
  'warehouse': Icons.warehouse_rounded,
  'camp': Icons.outdoor_grill_rounded,
  'other': Icons.more_horiz_rounded,
};

// ── Filter state providers ────────────────────────────────────────────────────

class SelectedCityNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? city) => state = city;
}

final selectedCityProvider = NotifierProvider<SelectedCityNotifier, String?>(
  SelectedCityNotifier.new,
);

class SelectedPropertyTypeNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? type) => state = type;
}

final selectedPropertyTypeProvider =
    NotifierProvider<SelectedPropertyTypeNotifier, String?>(
      SelectedPropertyTypeNotifier.new,
    );

// ── Listings async loader with server-side filters ────────────────────────────

class ListingsNotifier extends AsyncNotifier<List<Listing>> {
  final _repo = ListingsRepository();
  int _page = 1;
  bool hasMore = true;

  @override
  Future<List<Listing>> build() {
    _page = 1;
    hasMore = true;
    final city = ref.watch(selectedCityProvider);
    final propertyType = ref.watch(selectedPropertyTypeProvider);
    return _repo.getListings(
      listingType: 'sale',
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
    final city = ref.read(selectedCityProvider);
    final propertyType = ref.read(selectedPropertyTypeProvider);
    final newItems = await _repo.getListings(
      listingType: 'sale',
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
    final city = ref.read(selectedCityProvider);
    final propertyType = ref.read(selectedPropertyTypeProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.getListings(
        listingType: 'sale',
        page: _page,
        limit: 20,
        city: city,
        propertyType: propertyType,
      ),
    );
  }
}

final listingsNotifierProvider =
    AsyncNotifierProvider<ListingsNotifier, List<Listing>>(
      ListingsNotifier.new,
    );

// ── Convenience providers ─────────────────────────────────────────────────────

final listingsIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(listingsNotifierProvider).isLoading;
});

final filteredListingsProvider = Provider<List<Listing>>((ref) {
  return ref
      .watch(listingsNotifierProvider)
      .when(
        data: (data) => data,
        loading: () => <Listing>[],
        error: (_, __) => <Listing>[],
      );
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
      FavoritedIdsNotifier.new,
    );

final favoritedListingsProvider = Provider<List<Listing>>((ref) {
  final ids = ref.watch(favoritedIdsProvider);
  final listings = ref
      .watch(listingsNotifierProvider)
      .when(
        data: (data) => data,
        loading: () => <Listing>[],
        error: (_, __) => <Listing>[],
      );
  return listings.where((l) => ids.contains(l.id)).toList();
});
