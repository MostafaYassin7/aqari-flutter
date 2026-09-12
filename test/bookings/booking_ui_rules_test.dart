import 'package:flutter_test/flutter_test.dart';
import 'package:aqar_app/features/bookings/presentation/booking_ui_rules.dart';
import 'package:aqar_app/features/home/presentation/providers/rentals_provider.dart';

void main() {
  final today = DateTime(2026, 9, 10);
  final dates = RentalDateRange(
    checkIn: DateTime(2026, 10, 10),
    checkOut: DateTime(2026, 10, 13),
  );
  String? validate({
    String guests = '',
    String notes = '',
    int? maximum,
    int minimum = 1,
    RentalDateRange? range,
    List<DateTime> blocked = const [],
  }) => bookingInputError(
    dates: range ?? dates,
    guests: guests,
    notes: notes,
    minNights: minimum,
    maxGuests: maximum,
    blockedDates: blocked,
    today: today,
  );
  test('guest count may be absent with or without a capacity', () {
    expect(validate(), isNull);
    expect(validate(maximum: 6), isNull);
    expect(validate(guests: '100'), isNull);
  });
  for (final value in ['0', '-1', '1.5', 'NaN', '7']) {
    test('rejects invalid guest count $value for capacity six', () {
      expect(validate(guests: value, maximum: 6), isNotNull);
    });
  }
  test('accepts capacity boundary and notes limit', () {
    expect(validate(guests: '6', maximum: 6, notes: 'a' * 500), isNull);
    expect(validate(notes: 'a' * 501), isNotNull);
  });
  test('requires future valid range meeting minimum', () {
    expect(validate(range: const RentalDateRange()), isNotNull);
    expect(validate(minimum: 4), isNotNull);
    expect(
      validate(
        range: RentalDateRange(
          checkIn: DateTime(2026, 9, 9),
          checkOut: DateTime(2026, 9, 12),
        ),
      ),
      isNotNull,
    );
  });
  test('blocks occupied dates excluding checkout night', () {
    for (final day in [10, 11]) {
      expect(validate(blocked: [DateTime(2026, 10, day)]), isNotNull);
    }
    expect(validate(blocked: [DateTime(2026, 10, 14)]), isNull);
  });
  test('night count uses calendar dates, disregarding hours', () {
    expect(
      RentalDateRange(
        checkIn: DateTime(2026, 10, 10, 23),
        checkOut: DateTime(2026, 10, 13, 1),
      ).nights,
      3,
    );
  });
}
