import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqar_app/core/network/api_failure.dart';
import 'package:aqar_app/features/bookings/data/booking_repository.dart';
import 'package:aqar_app/features/bookings/domain/booking.dart';
import 'package:aqar_app/features/bookings/presentation/booking_providers.dart';
import 'test_support.dart';

void main() {
  test(
    'failed refresh retries page one while failed pagination retries next page',
    () async {
      final calls = <int>[];
      var fail = false;
      final repo = FakeBookingRepository()
        ..guestLoader = (page) {
          calls.add(page);
          if (fail) throw const ApiFailure('تعذر جلب الحجوزات');
          return BookingPage.fromJson({
            'data': [bookingJson(id: 'booking-$page')],
            'total': 30,
            'pages': 2,
          });
        };
      final c = ProviderContainer(
        overrides: [bookingRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      final notifier = c.read(guestBookingsProvider.notifier);
      await notifier.load();
      fail = true;
      await notifier.load(more: true);
      expect(c.read(guestBookingsProvider).retryMore, isTrue);
      expect(c.read(guestBookingsProvider).items.length, 1);
      fail = false;
      await notifier.load(more: c.read(guestBookingsProvider).retryMore);
      expect(c.read(guestBookingsProvider).items.length, 2);
      fail = true;
      await notifier.load();
      expect(c.read(guestBookingsProvider).retryMore, isFalse);
      fail = false;
      await notifier.load(more: c.read(guestBookingsProvider).retryMore);
      expect(calls, [1, 2, 2, 1, 1]);
    },
  );
  test(
    'a request created during a list load remains visible after stale response',
    () async {
      final pending = Completer<BookingPage>();
      final repo = FakeBookingRepository()..guestLoader = (_) => pending.future;
      final c = ProviderContainer(
        overrides: [bookingRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      final notifier = c.read(guestBookingsProvider.notifier);
      final loading = notifier.load();
      notifier.add(Booking.fromJson(bookingJson()));
      expect(c.read(guestBookingsProvider).items.single.rawStatus, 'pending');
      pending.complete(
        BookingPage.fromJson({'data': [], 'total': 0, 'pages': 0}),
      );
      await loading;
      expect(c.read(guestBookingsProvider).items.single.id, 'booking-live');
    },
  );
}
