import 'dart:async';
import 'package:dio/dio.dart';
import 'package:aqar_app/features/bookings/data/booking_repository.dart';
import 'package:aqar_app/features/bookings/domain/booking.dart';
import 'package:aqar_app/features/bookings/domain/stay_dates.dart';
import 'package:aqar_app/shared/models/listing.dart';

Map<String, dynamic> rentalJson({
  String propertyType = 'chalet',
  String listingType = 'rent_short',
}) => {
  'id': 'rental-live',
  'ownerId': 'host-live',
  'title': 'شاليه حي',
  'description': 'وصف من الخادم',
  'propertyType': propertyType,
  'listingType': listingType,
  'totalPrice': '125.50',
  'minNights': 2,
  'maxGuests': 4,
  'checkInTime': '15:00',
  'checkOutTime': '11:00',
  'hasKitchen': true,
  'city': 'Riyadh',
  'district': 'العليا',
  '__owner__': {'name': 'المضيف الحي'},
};
Listing rental({
  String propertyType = 'chalet',
  String listingType = 'rent_short',
}) => Listing.fromJson(
  rentalJson(propertyType: propertyType, listingType: listingType),
);
Map<String, dynamic> bookingJson({
  String status = 'pending',
  String id = 'booking-live',
}) => {
  'id': id,
  'listingId': 'rental-live',
  'guestId': 'guest-live',
  'ownerId': 'host-live',
  'checkInDate': '2026-09-12',
  'checkOutDate': '2026-09-14',
  'nights': 2,
  'guestCount': 3,
  'totalPrice': '260.75',
  'status': status,
  'notes': 'موعد الوصول',
  'createdAt': '2026-09-10T14:00:00Z',
  'updatedAt': '2026-09-10T14:00:00Z',
  'listing': rentalJson(),
};
StayRange stay() => StayRange(StayDate(2026, 9, 12), StayDate(2026, 9, 14));
CalendarBlock block(String date, [String? slot]) =>
    CalendarBlock.fromJson({'date': date, 'timeSlot': slot});

class FakeBookingRepository extends BookingRepository {
  FakeBookingRepository() : super(Dio());
  final months = <String>[];
  final checks = <StayRange>[];
  final creates = <Map<String, dynamic>>[];
  FutureOr<List<CalendarBlock>> Function(int, int) calendarLoader = (_, _) =>
      [];
  FutureOr<AvailabilityResult> Function() availability = () =>
      AvailabilityResult.fromJson({'isAvailable': true});
  FutureOr<Booking> Function() creator = () => Booking.fromJson(bookingJson());
  FutureOr<BookingPage> Function(int) guestLoader = (_) =>
      BookingPage.fromJson({'data': [], 'total': 0, 'pages': 0});
  @override
  Future<List<CalendarBlock>> calendar(String id, int year, int month) async {
    months.add('$year-$month');
    return calendarLoader(year, month);
  }

  @override
  Future<AvailabilityResult> checkAvailability(
    String id,
    StayRange range,
  ) async {
    checks.add(range);
    return availability();
  }

  @override
  Future<Booking> create(
    String id,
    StayRange range, {
    int? guestCount,
    String? notes,
  }) async {
    creates.add({
      'listingId': id,
      ...range.toJson(),
      'guestCount': guestCount,
      'notes': notes,
    });
    return creator();
  }

  @override
  Future<BookingPage> guestBookings({int page = 1, int limit = 20}) async =>
      guestLoader(page);
}
