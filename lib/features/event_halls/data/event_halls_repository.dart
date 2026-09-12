import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../../../shared/models/listing.dart';
import '../presentation/providers/hall_filters.dart';

final eventHallsRepositoryProvider = Provider(
  (ref) => EventHallsRepository(apiClient),
);

class EventHallPage {
  final List<Listing> items;
  final bool hasMore;
  const EventHallPage(this.items, {required this.hasMore});
}

class EventHallsRepository {
  final Dio dio;
  EventHallsRepository(this.dio);
  Future<EventHallPage> getPage({
    int page = 1,
    int limit = 20,
    HallFilters filters = const HallFilters(),
  }) async {
    final response = await dio.get(
      '/search',
      queryParameters: {
        'propertyType': 'event_hall',
        'page': page,
        'limit': limit,
        if (filters.city.isNotEmpty) 'city': filters.city,
        if (filters.min != null) 'priceFrom': filters.min,
        if (filters.max != null) 'priceTo': filters.max,
        if (filters.areaFrom != null) 'areaFrom': filters.areaFrom,
        if (filters.areaTo != null) 'areaTo': filters.areaTo,
      },
    );
    final body = response.data;
    final raw = body is List
        ? body
        : body is Map
        ? body['hits'] ?? body['data'] ?? body['items']
        : null;
    if (raw is! List) {
      throw const ApiFailure('تعذر قراءة قائمة القاعات. حاول مجدداً.');
    }
    final pages = body is Map
        ? optionalNumber(body['pages'] ?? body['totalPages'] ?? body['nbPages'])
        : null;
    final total = body is Map
        ? optionalNumber(body['total'] ?? body['nbHits'])
        : null;
    return EventHallPage(
      raw
          .whereType<Map>()
          .map((v) => Listing.fromJson(Map<String, dynamic>.from(v)))
          .where((v) => v.rules.isEventHall && v.id.isNotEmpty)
          .toList(),
      hasMore: pages != null
          ? page < pages
          : total != null
          ? page * limit < total
          : raw.length >= limit,
    );
  }
}
