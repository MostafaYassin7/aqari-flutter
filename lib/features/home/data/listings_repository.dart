import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/listing.dart';
import '../../../shared/models/project.dart';
import '../../../shared/models/rental.dart';

class ListingsRepository {
  /// Extracts the item list from various response shapes:
  /// - Algolia: { hits: [...], nbHits: N }
  /// - Backend paginated: { data: [...], total: N } or { items: [...], total: N }
  /// - Direct list: [...]
  List<T> _parseItems<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    List<dynamic> items;

    if (raw is List) {
      items = raw;
    } else if (raw is Map) {
      final m = Map<String, dynamic>.from(raw as Map);
      final rawItems = m['hits'] ?? m['data'] ?? m['items'];
      items = (rawItems as List?) ?? [];
    } else {
      return [];
    }

    return items
        .whereType<Map>()
        .map((j) => fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<List<Listing>> getListings({
    int page = 1,
    int limit = 20,
    String? listingType,
    String? query,
    String? city,
    String? propertyType,
    double? priceFrom,
    double? priceTo,
    double? areaFrom,
    double? areaTo,
    int? bedrooms,
    bool? isFurnished,
    bool? hasElevator,
  }) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.search,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (listingType != null) 'listingType': listingType,
          if (query != null && query.isNotEmpty) 'query': query,
          if (city != null && city.isNotEmpty) 'city': city,
          if (propertyType != null && propertyType.isNotEmpty)
            'propertyType': propertyType,
          if (priceFrom != null) 'priceFrom': priceFrom,
          if (priceTo != null) 'priceTo': priceTo,
          if (areaFrom != null) 'areaFrom': areaFrom,
          if (areaTo != null) 'areaTo': areaTo,
          if (bedrooms != null) 'bedrooms': bedrooms,
          if (isFurnished != null) 'isFurnished': isFurnished,
          if (hasElevator != null) 'hasElevator': hasElevator,
        },
      );
      return _parseItems<Listing>(response.data, Listing.fromJson);
    } catch (_) {
      return [];
    }
  }

  Future<List<Project>> getProjects({
    int page = 1,
    int limit = 20,
    String? city,
    String? status,
  }) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.projects,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (city != null && city.isNotEmpty) 'city': city,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      return _parseItems<Project>(response.data, Project.fromJson);
    } catch (_) {
      return [];
    }
  }

  Future<void> toggleFavorite({
    required String targetId,
    String targetType = 'listing',
  }) async {
    await apiClient.post(
      ApiEndpoints.favorites,
      data: {'targetType': targetType, 'targetId': targetId},
    );
  }

  /// Fetch a single listing by ID.
  Future<Listing> getListingById(String id) async {
    final response = await apiClient.get('${ApiEndpoints.listings}/$id');
    final raw = response.data;
    if (raw is Map) {
      return Listing.fromJson(Map<String, dynamic>.from(raw));
    }
    throw Exception('Invalid listing response');
  }

  /// Fetch engagement status (isFavorited) for a listing.
  Future<bool> getEngagementStatus(String listingId) async {
    try {
      final response = await apiClient.get(
        '${ApiEndpoints.engagementStatus}/$listingId',
      );
      final raw = response.data;
      if (raw is Map) {
        return raw['isFavorited'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<List<Listing>> getFavorites({int page = 1, int limit = 20}) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.favorites,
        queryParameters: {'page': page, 'limit': limit},
      );
      // Response: { data: [ { favoriteId, favoritedAt, listing: {...} } ] }
      final raw = response.data;
      List<dynamic> items;
      if (raw is List) {
        items = raw;
      } else if (raw is Map) {
        final m = Map<String, dynamic>.from(raw);
        items = (m['data'] ?? m['items'] ?? []) as List;
      } else {
        return [];
      }
      return items
          .whereType<Map>()
          .map((j) {
            final map = Map<String, dynamic>.from(j);
            final listing = map['listing'];
            if (listing is Map) {
              return Listing.fromJson(Map<String, dynamic>.from(listing));
            }
            return null;
          })
          .whereType<Listing>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<DailyRental>> getDailyRentals({
    int page = 1,
    int limit = 20,
    String? query,
    String? city,
    String? propertyType,
  }) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.search,
        queryParameters: {
          'page': page,
          'limit': limit,
          'listingType': 'rent_short',
          if (query != null && query.isNotEmpty) 'query': query,
          if (city != null && city.isNotEmpty) 'city': city,
          if (propertyType != null && propertyType.isNotEmpty)
            'propertyType': propertyType,
        },
      );
      return _parseItems<DailyRental>(response.data, DailyRental.fromJson);
    } catch (_) {
      return [];
    }
  }
}
