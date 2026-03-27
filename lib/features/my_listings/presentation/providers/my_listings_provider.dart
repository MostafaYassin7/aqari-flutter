import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Listing status ────────────────────────────────────────────────────────────

enum ListingStatus { published, pausedTemp, paused, expired }

extension ListingStatusX on ListingStatus {
  String get label {
    switch (this) {
      case ListingStatus.published:
        return 'منشور';
      case ListingStatus.pausedTemp:
        return 'موقوف مؤقتاً';
      case ListingStatus.paused:
        return 'موقوف';
      case ListingStatus.expired:
        return 'منتهي الصلاحية';
    }
  }
}

// ── My listing model ──────────────────────────────────────────────────────────

class MyListing {
  final String id;
  final String title;
  final String address;
  final String category;
  final double price;
  final int area;
  final int bedrooms;
  final int bathrooms;
  final int livingRooms;
  final String imageUrl;
  final ListingStatus status;
  final int messageRequests;
  final int views;
  final String lastUpdated;

  const MyListing({
    required this.id,
    required this.title,
    required this.address,
    required this.category,
    required this.price,
    required this.area,
    required this.bedrooms,
    required this.bathrooms,
    required this.livingRooms,
    required this.imageUrl,
    required this.status,
    required this.messageRequests,
    required this.views,
    required this.lastUpdated,
  });
}

// ── Mock data ─────────────────────────────────────────────────────────────────

const _mockMyListings = <MyListing>[
  MyListing(
    id: 'ml_01',
    title: 'شقة فاخرة في حي العليا',
    address: 'الرياض  ·  حي العليا',
    category: 'شقة للبيع',
    price: 850000,
    area: 180,
    bedrooms: 3,
    bathrooms: 2,
    livingRooms: 1,
    imageUrl: 'https://picsum.photos/seed/ml01/300/300',
    status: ListingStatus.published,
    messageRequests: 7,
    views: 342,
    lastUpdated: 'منذ يومين',
  ),
  MyListing(
    id: 'ml_02',
    title: 'فيلا مع مسبح - حي الياسمين',
    address: 'الرياض  ·  حي الياسمين',
    category: 'فيلا للبيع',
    price: 3200000,
    area: 520,
    bedrooms: 6,
    bathrooms: 5,
    livingRooms: 3,
    imageUrl: 'https://picsum.photos/seed/ml02/300/300',
    status: ListingStatus.published,
    messageRequests: 12,
    views: 891,
    lastUpdated: 'منذ 5 أيام',
  ),
  MyListing(
    id: 'ml_03',
    title: 'أرض سكنية في حي الملقا',
    address: 'الرياض  ·  حي الملقا',
    category: 'أرض',
    price: 1450000,
    area: 600,
    bedrooms: 0,
    bathrooms: 0,
    livingRooms: 0,
    imageUrl: 'https://picsum.photos/seed/ml03/300/300',
    status: ListingStatus.pausedTemp,
    messageRequests: 0,
    views: 156,
    lastUpdated: 'منذ أسبوع',
  ),
  MyListing(
    id: 'ml_04',
    title: 'شقة للإيجار - النزهة',
    address: 'الرياض  ·  حي النزهة',
    category: 'شقة للإيجار',
    price: 45000,
    area: 120,
    bedrooms: 2,
    bathrooms: 1,
    livingRooms: 1,
    imageUrl: 'https://picsum.photos/seed/ml04/300/300',
    status: ListingStatus.paused,
    messageRequests: 3,
    views: 210,
    lastUpdated: 'منذ أسبوعين',
  ),
  MyListing(
    id: 'ml_05',
    title: 'محل تجاري - طريق الملك فهد',
    address: 'الرياض  ·  طريق الملك فهد',
    category: 'تجاري',
    price: 620000,
    area: 95,
    bedrooms: 0,
    bathrooms: 1,
    livingRooms: 0,
    imageUrl: 'https://picsum.photos/seed/ml05/300/300',
    status: ListingStatus.expired,
    messageRequests: 0,
    views: 78,
    lastUpdated: 'منذ شهر',
  ),
  MyListing(
    id: 'ml_06',
    title: 'دوبلكس حديث - حي الربيع',
    address: 'الرياض  ·  حي الربيع',
    category: 'دوبلكس',
    price: 1100000,
    area: 280,
    bedrooms: 4,
    bathrooms: 3,
    livingRooms: 2,
    imageUrl: 'https://picsum.photos/seed/ml06/300/300',
    status: ListingStatus.published,
    messageRequests: 5,
    views: 430,
    lastUpdated: 'منذ 3 أيام',
  ),
];

// ── Filter tab ────────────────────────────────────────────────────────────────

enum ListingFilter { all, published, pausedTemp, paused, expired }

extension ListingFilterX on ListingFilter {
  String get label {
    switch (this) {
      case ListingFilter.all:
        return 'الكل';
      case ListingFilter.published:
        return 'منشور';
      case ListingFilter.pausedTemp:
        return 'موقوف مؤقتاً';
      case ListingFilter.paused:
        return 'موقوف';
      case ListingFilter.expired:
        return 'منتهي الصلاحية';
    }
  }
}

// ── State ─────────────────────────────────────────────────────────────────────

class MyListingsState {
  final List<MyListing> listings;
  final ListingFilter filter;

  const MyListingsState({
    this.listings = _mockMyListings,
    this.filter = ListingFilter.all,
  });

  List<MyListing> get filtered {
    if (filter == ListingFilter.all) return listings;
    final targetStatus = _filterToStatus(filter);
    return listings.where((l) => l.status == targetStatus).toList();
  }

  ListingStatus _filterToStatus(ListingFilter f) {
    switch (f) {
      case ListingFilter.published:
        return ListingStatus.published;
      case ListingFilter.pausedTemp:
        return ListingStatus.pausedTemp;
      case ListingFilter.paused:
        return ListingStatus.paused;
      case ListingFilter.expired:
        return ListingStatus.expired;
      case ListingFilter.all:
        return ListingStatus.published;
    }
  }

  MyListingsState copyWith({List<MyListing>? listings, ListingFilter? filter}) {
    return MyListingsState(
      listings: listings ?? this.listings,
      filter: filter ?? this.filter,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class MyListingsNotifier extends Notifier<MyListingsState> {
  @override
  MyListingsState build() => const MyListingsState();

  void setFilter(ListingFilter f) =>
      state = state.copyWith(filter: f);

  void deleteListing(String id) {
    final updated =
        state.listings.where((l) => l.id != id).toList();
    state = state.copyWith(listings: updated);
  }

  void togglePause(String id) {
    final updated = state.listings.map((l) {
      if (l.id != id) return l;
      final newStatus = l.status == ListingStatus.published
          ? ListingStatus.pausedTemp
          : ListingStatus.published;
      return MyListing(
        id: l.id,
        title: l.title,
        address: l.address,
        category: l.category,
        price: l.price,
        area: l.area,
        bedrooms: l.bedrooms,
        bathrooms: l.bathrooms,
        livingRooms: l.livingRooms,
        imageUrl: l.imageUrl,
        status: newStatus,
        messageRequests: l.messageRequests,
        views: l.views,
        lastUpdated: l.lastUpdated,
      );
    }).toList();
    state = state.copyWith(listings: updated);
  }
}

final myListingsProvider =
    NotifierProvider<MyListingsNotifier, MyListingsState>(
        MyListingsNotifier.new);
