import '../../home/presentation/providers/rentals_provider.dart';

/// Local form checks for the UI preview. Availability is fixture data only.
String? bookingInputError({
  required RentalDateRange dates,
  required String guests,
  required String notes,
  required int minNights,
  int? maxGuests,
  List<DateTime> blockedDates = const [],
  DateTime? today,
}) {
  final now = today ?? DateTime.now();
  final start = dates.checkIn;
  final end = dates.checkOut;
  if (start == null ||
      end == null ||
      start.isBefore(DateTime(now.year, now.month, now.day)) ||
      dates.nights < minNights) {
    return 'اختر تواريخ صالحة بحد أدنى $minNights ليالٍ';
  }
  if (blockedDates.any((d) {
    final day = DateTime(d.year, d.month, d.day);
    return !day.isBefore(start) && day.isBefore(end);
  })) {
    return 'يوجد تواريخ محجوزة في هذا النطاق';
  }
  if (guests.trim().isNotEmpty) {
    final count = int.tryParse(guests.trim());
    if (count == null ||
        count < 1 ||
        (maxGuests != null && count > maxGuests)) {
      return maxGuests == null
          ? 'أدخل عدد ضيوف صحيحاً لا يقل عن 1'
          : 'أدخل عدد ضيوف من 1 إلى $maxGuests';
    }
  }
  if (notes.length > 500) return 'الملاحظات لا تتجاوز 500 حرف';
  return null;
}
