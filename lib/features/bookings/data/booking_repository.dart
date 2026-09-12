import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../domain/booking.dart';
import '../domain/stay_dates.dart';

final bookingRepositoryProvider = Provider((ref) => BookingRepository());

class BookingRepository {
  final Dio _client;
  BookingRepository([Dio? client]) : _client = client ?? apiClient;
  Future<T> _request<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (error) {
      throw ApiFailure.fromError(error);
    }
  }

  Future<List<CalendarBlock>> calendar(String listingId, int year, int month) =>
      _request(() async {
        final response = await _client.get(
          '/listings/${Uri.encodeComponent(listingId)}/calendar',
          queryParameters: {'year': year, 'month': month},
        );
        return (response.data['blockedDates'] as List)
            .map((b) => CalendarBlock.fromJson(Map<String, dynamic>.from(b)))
            .toList();
      });
  Future<AvailabilityResult> checkAvailability(
    String listingId,
    StayRange range,
  ) => _request(() async {
    final response = await _client.post(
      '/bookings/check-availability/${Uri.encodeComponent(listingId)}',
      data: range.toJson(),
    );
    return AvailabilityResult.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  });
  Future<Booking> create(
    String listingId,
    StayRange range, {
    int? guestCount,
    String? notes,
  }) => _request(() async {
    final response = await _client.post(
      '/bookings',
      data: {
        'listingId': listingId,
        ...range.toJson(),
        if (guestCount != null) 'guestCount': guestCount,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    try {
      return Booking.fromJson(Map<String, dynamic>.from(response.data));
    } catch (error) {
      final failure = ApiFailure.fromError(error);
      throw ApiFailure(failure.message, {}, null, true);
    }
  });
  Future<BookingPage> guestBookings({int page = 1, int limit = 20}) =>
      _list('guest', page, limit);
  Future<BookingPage> ownerBookings({int page = 1, int limit = 20}) =>
      _list('owner', page, limit);
  Future<BookingPage> _list(String role, int page, int limit) =>
      _request(() async {
        final response = await _client.get(
          '/bookings/my/$role',
          queryParameters: {'page': page, 'limit': limit},
        );
        return BookingPage.fromJson(Map<String, dynamic>.from(response.data));
      });
  Future<Booking> confirm(String id) => _action(id, 'confirm');
  Future<Booking> decline(String id, {String? reason}) =>
      _action(id, 'decline', {if (reason != null) 'reason': reason});
  Future<Booking> cancel(String id) => _action(id, 'cancel');
  Future<Booking> _action(
    String id,
    String action, [
    Map<String, dynamic>? body,
  ]) => _request(() async {
    final response = await _client.patch(
      '/bookings/${Uri.encodeComponent(id)}/$action',
      data: body,
    );
    return Booking.fromJson(Map<String, dynamic>.from(response.data));
  });
}
