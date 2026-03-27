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
      dynamic raw, T Function(Map<String, dynamic>) fromJson) {
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
  }) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.search,
        queryParameters: {
          'page': page,
          'hitsPerPage': limit,
          if (listingType != null) 'listingType': listingType,
        },
      );
      return _parseItems<Listing>(response.data, Listing.fromJson);
    } catch (_) {
      return [];
    }
  }

  Future<List<Project>> getProjects({int page = 1, int limit = 20}) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.projects,
        queryParameters: {'page': page, 'limit': limit},
      );
      return _parseItems<Project>(response.data, Project.fromJson);
    } catch (_) {
      return [];
    }
  }

  Future<List<DailyRental>> getDailyRentals({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.search,
        queryParameters: {
          'page': page,
          'hitsPerPage': limit,
          'listingType': 'rent_short',
        },
      );
      return _parseItems<DailyRental>(response.data, DailyRental.fromJson);
    } catch (_) {
      return [];
    }
  }
}
