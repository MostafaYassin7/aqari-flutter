import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/listing.dart';
import '../../../../shared/models/project.dart';
import '../../../home/data/listings_repository.dart';

// ── Active tab context (0=عقارات, 1=مشاريع, 2=إيجار يومي) ─────────────────────

class SearchTabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void select(int v) => state = v;
}

final searchTabProvider = NotifierProvider<SearchTabNotifier, int>(
  SearchTabNotifier.new,
);

/// Maps tab index to listing type for the API
String? listingTypeForTab(int tab) {
  switch (tab) {
    case 0:
      return 'sale';
    case 2:
      return 'rent_short';
    default:
      return null;
  }
}

// ── Search mode (0 = filter search, 1 = search by number) ────────────────────

class SearchModeNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void select(int v) => state = v;
}

final searchModeProvider = NotifierProvider<SearchModeNotifier, int>(
  SearchModeNotifier.new,
);

// ── Query text ────────────────────────────────────────────────────────────────

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

// ── City filter (English value) ───────────────────────────────────────────────

class SearchCityNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? v) => state = v;
}

final searchCityProvider = NotifierProvider<SearchCityNotifier, String?>(
  SearchCityNotifier.new,
);

// ── Property type filter (English value) ──────────────────────────────────────

class SearchPropertyTypeNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? v) => state = v;
}

final searchPropertyTypeProvider =
    NotifierProvider<SearchPropertyTypeNotifier, String?>(
      SearchPropertyTypeNotifier.new,
    );

// ── Price range ───────────────────────────────────────────────────────────────

class SearchPriceFromNotifier extends Notifier<double?> {
  @override
  double? build() => null;
  void set(double? v) => state = v;
}

final searchPriceFromProvider =
    NotifierProvider<SearchPriceFromNotifier, double?>(
      SearchPriceFromNotifier.new,
    );

class SearchPriceToNotifier extends Notifier<double?> {
  @override
  double? build() => null;
  void set(double? v) => state = v;
}

final searchPriceToProvider = NotifierProvider<SearchPriceToNotifier, double?>(
  SearchPriceToNotifier.new,
);

// ── Area range ────────────────────────────────────────────────────────────────

class SearchAreaFromNotifier extends Notifier<double?> {
  @override
  double? build() => null;
  void set(double? v) => state = v;
}

final searchAreaFromProvider =
    NotifierProvider<SearchAreaFromNotifier, double?>(
      SearchAreaFromNotifier.new,
    );

class SearchAreaToNotifier extends Notifier<double?> {
  @override
  double? build() => null;
  void set(double? v) => state = v;
}

final searchAreaToProvider = NotifierProvider<SearchAreaToNotifier, double?>(
  SearchAreaToNotifier.new,
);

// ── Bedrooms ──────────────────────────────────────────────────────────────────

class SearchBedroomsNotifier extends Notifier<int?> {
  @override
  int? build() => null;
  void select(int? v) => state = v;
}

final searchBedroomsProvider = NotifierProvider<SearchBedroomsNotifier, int?>(
  SearchBedroomsNotifier.new,
);

// ── Boolean filters ───────────────────────────────────────────────────────────

class SearchFurnishedNotifier extends Notifier<bool?> {
  @override
  bool? build() => null;
  void set(bool? v) => state = v;
}

final searchFurnishedProvider =
    NotifierProvider<SearchFurnishedNotifier, bool?>(
      SearchFurnishedNotifier.new,
    );

class SearchElevatorNotifier extends Notifier<bool?> {
  @override
  bool? build() => null;
  void set(bool? v) => state = v;
}

final searchElevatorProvider = NotifierProvider<SearchElevatorNotifier, bool?>(
  SearchElevatorNotifier.new,
);

// ── Project status filter (ready / off_plan) ──────────────────────────────────

class SearchProjectStatusNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? v) => state = v;
}

final searchProjectStatusProvider =
    NotifierProvider<SearchProjectStatusNotifier, String?>(
      SearchProjectStatusNotifier.new,
    );

// ── Async search results (listings) with pagination ───────────────────────────

class SearchResultsNotifier extends AsyncNotifier<List<Listing>> {
  final _repo = ListingsRepository();
  int _page = 1;
  bool hasMore = true;

  @override
  Future<List<Listing>> build() async {
    _page = 1;
    hasMore = true;
    final tab = ref.watch(searchTabProvider);
    // Tab 1 = projects (different provider), skip listings fetch
    if (tab == 1) return [];

    final query = ref.watch(searchQueryProvider);
    final city = ref.watch(searchCityProvider);
    final propertyType = ref.watch(searchPropertyTypeProvider);
    final priceFrom = ref.watch(searchPriceFromProvider);
    final priceTo = ref.watch(searchPriceToProvider);
    final areaFrom = ref.watch(searchAreaFromProvider);
    final areaTo = ref.watch(searchAreaToProvider);
    final bedrooms = ref.watch(searchBedroomsProvider);
    final isFurnished = ref.watch(searchFurnishedProvider);
    final hasElevator = ref.watch(searchElevatorProvider);

    return _repo.getListings(
      page: _page,
      limit: 20,
      listingType: listingTypeForTab(tab),
      query: query.isEmpty ? null : query,
      city: city,
      propertyType: propertyType,
      priceFrom: priceFrom,
      priceTo: priceTo,
      areaFrom: areaFrom,
      areaTo: areaTo,
      bedrooms: bedrooms,
      isFurnished: isFurnished,
      hasElevator: hasElevator,
    );
  }

  Future<void> loadMore() async {
    if (!hasMore) return;
    final tab = ref.read(searchTabProvider);
    if (tab == 1) return;
    final current = state.value;
    if (current == null) return;
    _page++;
    final query = ref.read(searchQueryProvider);
    final city = ref.read(searchCityProvider);
    final propertyType = ref.read(searchPropertyTypeProvider);
    final priceFrom = ref.read(searchPriceFromProvider);
    final priceTo = ref.read(searchPriceToProvider);
    final areaFrom = ref.read(searchAreaFromProvider);
    final areaTo = ref.read(searchAreaToProvider);
    final bedrooms = ref.read(searchBedroomsProvider);
    final isFurnished = ref.read(searchFurnishedProvider);
    final hasElevator = ref.read(searchElevatorProvider);

    final newItems = await _repo.getListings(
      page: _page,
      limit: 20,
      listingType: listingTypeForTab(tab),
      query: query.isEmpty ? null : query,
      city: city,
      propertyType: propertyType,
      priceFrom: priceFrom,
      priceTo: priceTo,
      areaFrom: areaFrom,
      areaTo: areaTo,
      bedrooms: bedrooms,
      isFurnished: isFurnished,
      hasElevator: hasElevator,
    );
    if (newItems.length < 20) hasMore = false;
    state = AsyncData([...current, ...newItems]);
  }
}

final searchResultsProvider =
    AsyncNotifierProvider<SearchResultsNotifier, List<Listing>>(
      SearchResultsNotifier.new,
    );

// ── Async project search results with pagination ──────────────────────────────

class ProjectSearchResultsNotifier extends AsyncNotifier<List<Project>> {
  final _repo = ListingsRepository();
  int _page = 1;
  bool hasMore = true;

  @override
  Future<List<Project>> build() async {
    _page = 1;
    hasMore = true;
    final tab = ref.watch(searchTabProvider);
    if (tab != 1) return [];

    final city = ref.watch(searchCityProvider);
    final status = ref.watch(searchProjectStatusProvider);

    return _repo.getProjects(
      page: _page,
      limit: 20,
      city: city,
      status: status,
    );
  }

  Future<void> loadMore() async {
    if (!hasMore) return;
    final tab = ref.read(searchTabProvider);
    if (tab != 1) return;
    final current = state.value;
    if (current == null) return;
    _page++;
    final city = ref.read(searchCityProvider);
    final status = ref.read(searchProjectStatusProvider);

    final newItems = await _repo.getProjects(
      page: _page,
      limit: 20,
      city: city,
      status: status,
    );
    if (newItems.length < 20) hasMore = false;
    state = AsyncData([...current, ...newItems]);
  }
}

final projectSearchResultsProvider =
    AsyncNotifierProvider<ProjectSearchResultsNotifier, List<Project>>(
      ProjectSearchResultsNotifier.new,
    );

// ── Reference query text (ad number / phone) ─────────────────────────────────

class ReferenceQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

final referenceQueryProvider = NotifierProvider<ReferenceQueryNotifier, String>(
  ReferenceQueryNotifier.new,
);

// ── Async search by reference results ─────────────────────────────────────────

class ReferenceSearchNotifier extends AsyncNotifier<List<Listing>> {
  final _repo = ListingsRepository();

  @override
  Future<List<Listing>> build() async {
    final q = ref.watch(referenceQueryProvider);
    if (q.trim().isEmpty) return [];
    return _repo.searchByReference(q.trim());
  }
}

final referenceSearchProvider =
    AsyncNotifierProvider<ReferenceSearchNotifier, List<Listing>>(
      ReferenceSearchNotifier.new,
    );

// ── Helper: whether any advanced filter is active ─────────────────────────────

final hasActiveFiltersProvider = Provider<bool>((ref) {
  return ref.watch(searchPriceFromProvider) != null ||
      ref.watch(searchPriceToProvider) != null ||
      ref.watch(searchAreaFromProvider) != null ||
      ref.watch(searchAreaToProvider) != null ||
      ref.watch(searchBedroomsProvider) != null ||
      ref.watch(searchFurnishedProvider) != null ||
      ref.watch(searchElevatorProvider) != null;
});
