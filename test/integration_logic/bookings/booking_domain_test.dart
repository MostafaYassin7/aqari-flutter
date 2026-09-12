import 'package:flutter_test/flutter_test.dart';
import 'package:aqar_app/features/bookings/domain/booking.dart';
import 'package:aqar_app/features/bookings/domain/stay_dates.dart';
import 'test_support.dart';

void main() {
  test('date-only round trip does not normalize through timezone offsets', () {
    for (final iso in [
      '2026-03-08',
      '2026-11-01',
      '2028-02-29',
      '2026-12-31',
    ]) {
      expect(StayDate.parse(iso).iso, iso);
      final parts = iso.split('-').map(int.parse).toList();
      expect(
        StayDate.local(DateTime(parts[0], parts[1], parts[2], 23, 59)).iso,
        iso,
      );
    }
    for (final invalid in [
      '2026-02-29',
      '2026-13-01',
      '2026-9-01',
      '2026-09-10T00:00:00+14:00',
    ]) {
      expect(() => StayDate.parse(invalid), throwsFormatException);
    }
  });
  test(
    'night arithmetic spans DST, leap days, months and years with checkout excluded',
    () {
      for (final start in [
        '2026-03-07',
        '2026-10-31',
        '2028-02-28',
        '2026-12-31',
      ]) {
        final date = StayDate.parse(start);
        final range = StayRange(date, date.addDays(3));
        expect(range.nights, 3);
        expect(range.bookedNights, [date, date.addDays(1), date.addDays(2)]);
        expect(range.bookedNights, isNot(contains(range.checkOut)));
      }
    },
  );
  test('minimum nights and blocked range boundaries', () {
    final range = stay();
    expect(range.validate(minNights: 3), contains('3'));
    expect(range.validate(minNights: 2), isNull);
    for (final d in range.bookedNights) {
      expect(range.validate(blocked: {d}), contains('غير متاحة'));
    }
    expect(
      range.validate(blocked: {range.checkIn.addDays(-1), range.checkOut}),
      isNull,
    );
    expect(StayRange(range.checkIn, range.checkIn).validate(), isNotNull);
  });
  test('optional guest bounds and fractional nightly preview', () {
    for (final input in ['', '1', '4']) {
      expect(validateGuestCount(input, 4), isNull);
    }
    for (final input in ['0', '-1', '1.5', 'abc', '5']) {
      expect(validateGuestCount(input, 4), isNotNull);
    }
    expect(validateGuestCount('100', null), isNull);
    expect(stay().previewTotal(125.50), 251);
  });
  test('booking relations, decimal strings, status and timestamps', () {
    final booking = Booking.fromJson(bookingJson());
    expect(booking.totalPrice, 260.75);
    expect(booking.listing!.title, 'شاليه حي');
    expect(booking.checkInDate, StayDate(2026, 9, 12));
    expect(booking.guestCount, 3);
    expect(booking.nights, 2);
    expect(booking.createdAt!.isUtc, isTrue);
    expect(booking.notes, 'موعد الوصول');
    for (final status in ['pending', 'confirmed', 'cancelled', 'completed']) {
      expect(Booking.fromJson(bookingJson(status: status)).status.name, status);
    }
    final unknown = Booking.fromJson(bookingJson(status: 'future_status'));
    expect(unknown.status, BookingStatus.unknown);
    expect(unknown.statusLabel, 'future_status');
    expect(
      () => Booking.fromJson({...bookingJson(), 'totalPrice': 'broken'}),
      throwsFormatException,
    );
  });
}
