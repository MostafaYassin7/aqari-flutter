/// A civil date, represented at UTC midnight solely for calendar arithmetic.
/// Never converts an API date or local date through a timezone.
class StayDate implements Comparable<StayDate> {
  final DateTime _value;
  StayDate(int year, int month, int day)
    : _value = DateTime.utc(year, month, day);
  factory StayDate.local(DateTime value) =>
      StayDate(value.year, value.month, value.day);
  factory StayDate.parse(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw FormatException('Expected YYYY-MM-DD', value);
    }
    final parts = value.split('-').map(int.parse).toList();
    final date = StayDate(parts[0], parts[1], parts[2]);
    if (date.iso != value) throw FormatException('Invalid date', value);
    return date;
  }
  int get year => _value.year;
  int get month => _value.month;
  int get day => _value.day;
  int get weekday => _value.weekday;
  String get iso =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  String get monthKey => iso.substring(0, 7);
  StayDate addDays(int days) =>
      StayDate.local(_value.add(Duration(days: days)));
  int difference(StayDate other) => _value.difference(other._value).inDays;
  @override
  int compareTo(StayDate other) => _value.compareTo(other._value);
  @override
  bool operator ==(Object other) => other is StayDate && _value == other._value;
  @override
  int get hashCode => _value.hashCode;
  @override
  String toString() => iso;
}

class StayRange {
  final StayDate checkIn, checkOut;
  const StayRange(this.checkIn, this.checkOut);
  int get nights => checkOut.difference(checkIn);
  Iterable<StayDate> get bookedNights sync* {
    for (var d = checkIn; d.compareTo(checkOut) < 0; d = d.addDays(1)) {
      yield d;
    }
  }

  double previewTotal(double nightlyPrice) => nights * nightlyPrice;
  String? validate({int minNights = 1, Set<StayDate> blocked = const {}}) {
    if (nights < minNights) return 'الحد الأدنى للإقامة $minNights ليلة';
    if (bookedNights.any(blocked.contains)) {
      return 'تتضمن الفترة تواريخ غير متاحة';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'checkInDate': checkIn.iso,
    'checkOutDate': checkOut.iso,
  };
}

String? validateGuestCount(String input, int? maxGuests) {
  if (input.trim().isEmpty) return null;
  final count = int.tryParse(input.trim());
  if (count == null || count < 1) {
    return 'عدد الضيوف يجب أن يكون عدداً صحيحاً لا يقل عن 1';
  }
  if (maxGuests != null && count > maxGuests) {
    return 'الحد الأقصى $maxGuests ضيف';
  }
  return null;
}
