import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/listing.dart';
import '../../../home/data/mock_listings.dart';

// ── Search mode (0 = Filter, 1 = Ad/Phone) ────────────────────────────────────

class SearchModeNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int idx) => state = idx;
}

final searchModeProvider =
    NotifierProvider<SearchModeNotifier, int>(SearchModeNotifier.new);

// ── Ad / Phone query ──────────────────────────────────────────────────────────

class AdQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String v) => state = v;
}

final adQueryProvider =
    NotifierProvider<AdQueryNotifier, String>(AdQueryNotifier.new);

// ── Filter fields ─────────────────────────────────────────────────────────────

class SearchCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? v) => state = v;
}

final searchCategoryProvider =
    NotifierProvider<SearchCategoryNotifier, String?>(
        SearchCategoryNotifier.new);

class SearchCityNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? v) => state = v;
}

final searchCityProvider =
    NotifierProvider<SearchCityNotifier, String?>(SearchCityNotifier.new);

class SearchDistrictNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? v) => state = v;
}

final searchDistrictProvider =
    NotifierProvider<SearchDistrictNotifier, String?>(
        SearchDistrictNotifier.new);

class MarketingOnlyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final marketingOnlyProvider =
    NotifierProvider<MarketingOnlyNotifier, bool>(MarketingOnlyNotifier.new);

// ── Filter sheet: price range ─────────────────────────────────────────────────

class PriceRangeState {
  final double min;
  final double max;

  const PriceRangeState({required this.min, required this.max});
}

class PriceRangeNotifier extends Notifier<PriceRangeState> {
  static const double kMin = 0;
  static const double kMax = 5000000;

  @override
  PriceRangeState build() => const PriceRangeState(min: kMin, max: kMax);

  void set(double min, double max) => state = PriceRangeState(min: min, max: max);

  void reset() => state = const PriceRangeState(min: kMin, max: kMax);
}

final priceRangeProvider =
    NotifierProvider<PriceRangeNotifier, PriceRangeState>(
        PriceRangeNotifier.new);

// ── Filter sheet: property types ──────────────────────────────────────────────

class SelectedPropertyTypesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String t) {
    if (state.contains(t)) {
      state = Set.from(state)..remove(t);
    } else {
      state = Set.from(state)..add(t);
    }
  }

  void clear() => state = const {};
}

final selectedPropertyTypesProvider =
    NotifierProvider<SelectedPropertyTypesNotifier, Set<String>>(
        SelectedPropertyTypesNotifier.new);

// ── Filter sheet: bedrooms (-1 = any) ────────────────────────────────────────

class BedroomsFilterNotifier extends Notifier<int> {
  @override
  int build() => -1;

  void select(int v) => state = v;

  void reset() => state = -1;
}

final bedroomsFilterProvider =
    NotifierProvider<BedroomsFilterNotifier, int>(BedroomsFilterNotifier.new);

// ── Filter sheet: amenities ───────────────────────────────────────────────────

class SelectedAmenitiesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String a) {
    if (state.contains(a)) {
      state = Set.from(state)..remove(a);
    } else {
      state = Set.from(state)..add(a);
    }
  }

  void clear() => state = const {};
}

final selectedAmenitiesProvider =
    NotifierProvider<SelectedAmenitiesNotifier, Set<String>>(
        SelectedAmenitiesNotifier.new);

// ── Derived results ───────────────────────────────────────────────────────────

final searchResultsProvider = Provider<List<Listing>>((ref) {
  final category = ref.watch(searchCategoryProvider);
  final city = ref.watch(searchCityProvider);
  final district = ref.watch(searchDistrictProvider);
  final priceRange = ref.watch(priceRangeProvider);
  final types = ref.watch(selectedPropertyTypesProvider);
  final bedrooms = ref.watch(bedroomsFilterProvider);

  return mockListings.where((l) {
    if (category != null && l.category != category) return false;
    if (city != null && l.city != city) return false;
    if (district != null && l.district != district) return false;
    if (l.price < priceRange.min || l.price > priceRange.max) return false;
    if (types.isNotEmpty && !types.contains(l.category)) return false;
    if (bedrooms >= 0 && l.bedrooms != bedrooms) return false;
    return true;
  }).toList();
});

// ── Static reference data ─────────────────────────────────────────────────────

const searchCities = [
  'الرياض',
  'جدة',
  'مكة المكرمة',
  'المدينة المنورة',
  'الدمام',
  'الخبر',
  'أبها',
  'الطائف',
  'تبوك',
  'نيوم',
  'الجبيل',
  'ينبع',
];

const searchPropertyTypes = [
  'شقة',
  'فيلا',
  'أرض',
  'تجاري',
  'دوبلكس',
  'استراحة',
  'عمارة',
];

const searchAmenities = [
  'مسبح',
  'مصعد',
  'موقف سيارة',
  'حديقة',
  'أمن 24 ساعة',
  'مطبخ راكب',
  'واي فاي',
  'صالة رياضية',
];

const _riyadhDistricts = [
  'حي العليا',
  'حي النزهة',
  'حي التلال',
  'حي الملقا',
  'حي الربيع',
  'حي الورود',
  'حي السليمانية',
];

const _jeddahDistricts = [
  'حي الشاطئ',
  'حي الروضة',
  'شمال جدة',
  'حي الزهراء',
  'حي الحمراء',
];

const _genericDistricts = [
  'حي المركز',
  'حي الشرق',
  'حي الغرب',
  'حي الشمال',
  'حي الجنوب',
];

List<String> getDistrictsForCity(String? city) {
  if (city == 'الرياض') return _riyadhDistricts;
  if (city == 'جدة') return _jeddahDistricts;
  if (city != null) return _genericDistricts;
  return [];
}
