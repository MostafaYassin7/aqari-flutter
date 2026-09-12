import '../../../shared/models/listing.dart';
import 'stay_dates.dart';

enum BookingStatus { pending, confirmed, cancelled, completed, unknown }

class Booking {
  final String id, listingId, guestId, ownerId, rawStatus;
  final Listing? listing;
  final StayDate? checkInDate, checkOutDate;
  final int? nights, guestCount;
  final double totalPrice;
  final String? notes;
  final DateTime? createdAt, updatedAt;
  Booking.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      listingId = json['listingId'] as String,
      guestId = json['guestId'] as String,
      ownerId = json['ownerId'] as String,
      rawStatus = json['status'] as String? ?? 'unknown',
      listing = json['listing'] is Map
          ? Listing.fromJson(Map<String, dynamic>.from(json['listing']))
          : null,
      checkInDate = json['checkInDate'] == null
          ? null
          : StayDate.parse(json['checkInDate']),
      checkOutDate = json['checkOutDate'] == null
          ? null
          : StayDate.parse(json['checkOutDate']),
      nights = optionalPositiveInt(json['nights']),
      guestCount = optionalPositiveInt(json['guestCount']),
      totalPrice =
          optionalNumber(json['totalPrice']) ??
          (throw const FormatException('Invalid booking total')),
      notes = json['notes'] as String?,
      createdAt = DateTime.tryParse('${json['createdAt']}'),
      updatedAt = DateTime.tryParse('${json['updatedAt']}');
  Booking.withListing(Booking booking, Listing? fallback)
    : id = booking.id,
      listingId = booking.listingId,
      guestId = booking.guestId,
      ownerId = booking.ownerId,
      rawStatus = booking.rawStatus,
      listing = booking.listing ?? fallback,
      checkInDate = booking.checkInDate,
      checkOutDate = booking.checkOutDate,
      nights = booking.nights,
      guestCount = booking.guestCount,
      totalPrice = booking.totalPrice,
      notes = booking.notes,
      createdAt = booking.createdAt,
      updatedAt = booking.updatedAt;
  bool get canManagePending =>
      status == BookingStatus.pending &&
      (listing?.rules.isDailyRental ??
          (checkInDate != null && checkOutDate != null));
  BookingStatus get status => BookingStatus.values.firstWhere(
    (value) => value.name == rawStatus,
    orElse: () => BookingStatus.unknown,
  );
  String get statusLabel => switch (status) {
    BookingStatus.pending => 'بانتظار موافقة المضيف',
    BookingStatus.confirmed => 'مؤكد',
    BookingStatus.cancelled => 'ملغي',
    BookingStatus.completed => 'مكتمل',
    BookingStatus.unknown => rawStatus,
  };
}

class CalendarBlock {
  final StayDate date;
  final String? timeSlot;
  CalendarBlock.fromJson(Map<String, dynamic> json)
    : date = StayDate.parse(json['date']),
      timeSlot = json['timeSlot'] as String?;
}

class AvailabilityResult {
  final bool isAvailable;
  final List<StayDate> blockedDates;
  AvailabilityResult.fromJson(Map<String, dynamic> json)
    : isAvailable = json['isAvailable'] as bool,
      blockedDates = (json['blockedDates'] as List? ?? [])
          .map((d) => StayDate.parse(d as String))
          .toList();
}

class BookingPage {
  final List<Booking> data;
  final int total, pages;
  BookingPage.fromJson(Map<String, dynamic> json)
    : data = (json['data'] as List)
          .map((b) => Booking.fromJson(Map<String, dynamic>.from(b)))
          .toList(),
      total = (json['total'] as num).toInt(),
      pages = (json['pages'] as num).toInt();
}
