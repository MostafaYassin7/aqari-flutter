import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqar_app/core/network/api_client.dart';
import 'package:aqar_app/core/network/api_failure.dart';
import 'package:aqar_app/features/bookings/data/booking_repository.dart';
import 'test_support.dart';

class Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  Object? body;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) await requestStream.drain<void>();
    return ResponseBody.fromString(
      jsonEncode({
        'success': status == 200,
        if (status == 200)
          'data': body
        else
          'message': 'التواريخ المطلوبة غير متاحة',
      }),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'exact calendar, availability, create, paginated list and action contracts',
    () async {
      final adapter = Adapter();
      final client = createApiClient()..httpClientAdapter = adapter;
      addTearDown(() => client.close(force: true));
      final repo = BookingRepository(client);
      adapter.body = {
        'blockedDates': [
          {'date': '2026-09-13', 'timeSlot': 'morning'},
        ],
      };
      final blocks = await repo.calendar('rental-live', 2026, 9);
      expect(blocks.single.timeSlot, 'morning');
      expect(adapter.requests.last.path, '/listings/rental-live/calendar');
      expect(adapter.requests.last.queryParameters, {'year': 2026, 'month': 9});
      adapter.body = {
        'isAvailable': false,
        'blockedDates': ['2026-09-13'],
      };
      expect(
        (await repo.checkAvailability(
          'rental-live',
          stay(),
        )).blockedDates.single.iso,
        '2026-09-13',
      );
      expect(adapter.requests.last.method, 'POST');
      expect(
        adapter.requests.last.path,
        '/bookings/check-availability/rental-live',
      );
      expect(adapter.requests.last.data, stay().toJson());
      adapter.body = {...bookingJson()}..remove('listing');
      expect(
        (await repo.create(
          'rental-live',
          stay(),
          guestCount: 3,
          notes: ' ملاحظة ',
        )).totalPrice,
        260.75,
      );
      expect(adapter.requests.last.path, '/bookings');
      expect(adapter.requests.last.data, {
        'listingId': 'rental-live',
        ...stay().toJson(),
        'guestCount': 3,
        'notes': 'ملاحظة',
      });
      await repo.create('rental-live', stay());
      expect(adapter.requests.last.data, {
        'listingId': 'rental-live',
        ...stay().toJson(),
      });
      adapter.body = {
        'data': [bookingJson()],
        'total': 21,
        'pages': 2,
      };
      final page = await repo.guestBookings(page: 2, limit: 20);
      expect(page.total, 21);
      expect(page.pages, 2);
      expect(page.data.single.id, 'booking-live');
      expect(adapter.requests.last.path, '/bookings/my/guest');
      expect(adapter.requests.last.queryParameters, {'page': 2, 'limit': 20});
      await repo.ownerBookings();
      expect(adapter.requests.last.path, '/bookings/my/owner');
      adapter.body = bookingJson(status: 'confirmed');
      expect((await repo.confirm('booking-live')).rawStatus, 'confirmed');
      expect(adapter.requests.last.path, '/bookings/booking-live/confirm');
      expect(adapter.requests.last.method, 'PATCH');
      await repo.decline('booking-live', reason: 'سبب');
      expect(adapter.requests.last.path, '/bookings/booking-live/decline');
      expect(adapter.requests.last.data, {'reason': 'سبب'});
      await repo.cancel('booking-live');
      expect(adapter.requests.last.path, '/bookings/booking-live/cancel');
      expect(adapter.requests.last.method, 'PATCH');
    },
  );
  test(
    'every failed endpoint propagates API message and HTTP status, never empty data',
    () async {
      final adapter = Adapter()..status = 400;
      final client = createApiClient()..httpClientAdapter = adapter;
      addTearDown(() => client.close(force: true));
      final repo = BookingRepository(client);
      for (final call in <Future<Object> Function()>[
        () => repo.calendar('r', 2026, 9),
        () => repo.checkAvailability('r', stay()),
        () => repo.create('r', stay()),
        () => repo.guestBookings(),
        () => repo.ownerBookings(),
        () => repo.confirm('b'),
        () => repo.decline('b'),
        () => repo.cancel('b'),
      ]) {
        await expectLater(
          call(),
          throwsA(
            isA<ApiFailure>()
                .having((e) => e.statusCode, 'status', 400)
                .having(
                  (e) => e.message,
                  'message',
                  'التواريخ المطلوبة غير متاحة',
                ),
          ),
        );
      }
    },
  );
}
