import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/listing_category.dart';
import '../../../home/data/listings_repository.dart';

// ── My listing model ──────────────────────────────────────────────────────────

class MyListing {
  final String id;
  final String createdAt;
  final String title;
  final String status;
  final int viewCount;
  final int messageCount;
  final String adNumber;
  final ListingCategory? category;
  final String propertyType;
  final String listingType;
  final double totalPrice;
  final double pricePerMeter;
  final double area;
  final int bedrooms;
  final int bathrooms;
  final String city;
  final String district;
  final String address;
  final String? coverPhoto;

  const MyListing({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.status,
    required this.viewCount,
    required this.messageCount,
    required this.adNumber,
    this.category,
    required this.propertyType,
    required this.listingType,
    required this.totalPrice,
    required this.pricePerMeter,
    required this.area,
    required this.bedrooms,
    required this.bathrooms,
    required this.city,
    required this.district,
    required this.address,
    this.coverPhoto,
  });

  factory MyListing.fromJson(Map<String, dynamic> json) {
    return MyListing(
      id: json['id'] as String,
      createdAt: json['createdAt'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      viewCount: json['viewCount'] as int? ?? 0,
      messageCount: json['messageCount'] as int? ?? 0,
      adNumber: json['adNumber'] as String? ?? '',
      category: json['category'] is Map
          ? ListingCategory.fromJson(
              Map<String, dynamic>.from(json['category'] as Map),
            )
          : null,
      propertyType: json['propertyType'] as String? ?? '',
      listingType: json['listingType'] as String? ?? '',
      totalPrice: double.tryParse('${json['totalPrice']}') ?? 0,
      pricePerMeter: double.tryParse('${json['pricePerMeter']}') ?? 0,
      area: double.tryParse('${json['area']}') ?? 0,
      bedrooms: json['bedrooms'] as int? ?? 0,
      bathrooms: json['bathrooms'] as int? ?? 0,
      city: json['city'] as String? ?? '',
      district: json['district'] as String? ?? '',
      address: json['address'] as String? ?? '',
      coverPhoto: json['coverPhoto'] as String?,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'published':
        return 'منشور';
      case 'paused_temp':
        return 'موقوف مؤقتاً';
      case 'paused':
        return 'موقوف';
      case 'expired':
        return 'منتهي الصلاحية';
      case 'pending':
        return 'قيد المراجعة';
      default:
        return status;
    }
  }
}

// ── Status filter values ──────────────────────────────────────────────────────

const statusFilters = <String, String>{
  '': 'الكل',
  'published': 'منشور',
  'paused_temp': 'موقوف مؤقتاً',
  'paused': 'موقوف',
  'expired': 'منتهي',
  'pending': 'قيد المراجعة',
};

// ── Selected category provider ────────────────────────────────────────────────

class SelectedCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String?>(
      SelectedCategoryNotifier.new,
    );

// ── Selected status provider ──────────────────────────────────────────────────

class SelectedStatusNotifier extends Notifier<String> {
  @override
  String build() => '';
  void select(String v) => state = v;
}

final selectedStatusProvider = NotifierProvider<SelectedStatusNotifier, String>(
  SelectedStatusNotifier.new,
);

// ── Listing categories provider ───────────────────────────────────────────────

class ListingCategoriesNotifier extends AsyncNotifier<List<ListingCategory>> {
  final _repo = ListingsRepository();

  @override
  Future<List<ListingCategory>> build() async {
    return _repo.getListingCategories();
  }
}

final listingCategoriesProvider =
    AsyncNotifierProvider<ListingCategoriesNotifier, List<ListingCategory>>(
      ListingCategoriesNotifier.new,
    );

// ── My listings provider ──────────────────────────────────────────────────────

class MyListingsNotifier extends AsyncNotifier<List<MyListing>> {
  final _repo = ListingsRepository();
  int _page = 1;
  bool hasMore = true;

  @override
  Future<List<MyListing>> build() async {
    _page = 1;
    hasMore = true;
    final categoryId = ref.watch(selectedCategoryProvider);
    final status = ref.watch(selectedStatusProvider);

    return _repo.getMyListings(
      page: _page,
      limit: 20,
      categoryId: categoryId,
      status: status.isEmpty ? null : status,
    );
  }

  Future<void> loadMore() async {
    if (!hasMore) return;
    final current = state.value;
    if (current == null) return;
    _page++;
    final categoryId = ref.read(selectedCategoryProvider);
    final status = ref.read(selectedStatusProvider);

    final newItems = await _repo.getMyListings(
      page: _page,
      limit: 20,
      categoryId: categoryId,
      status: status.isEmpty ? null : status,
    );
    if (newItems.length < 20) hasMore = false;
    state = AsyncData([...current, ...newItems]);
  }
}

final myListingsProvider =
    AsyncNotifierProvider<MyListingsNotifier, List<MyListing>>(
      MyListingsNotifier.new,
    );
