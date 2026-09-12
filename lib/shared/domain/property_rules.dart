import '../../core/constants/app_enums.dart';

enum PropertyGroup { residential, commercial, land, eventHall, other }

class PropertyRules {
  final String? propertyType;
  final String? listingType;
  const PropertyRules(this.propertyType, this.listingType);
  static const residential = {
    'apartment',
    'villa',
    'house',
    'floor',
    'chalet',
    'rest_house',
    'farm',
  };
  static const commercial = {
    'shop',
    'commercial_office',
    'warehouse',
    'building',
  };
  PropertyGroup get group {
    if (isEventHall) return PropertyGroup.eventHall;
    if (propertyType == PropertyType.land) return PropertyGroup.land;
    if (residential.contains(propertyType)) return PropertyGroup.residential;
    if (commercial.contains(propertyType)) return PropertyGroup.commercial;
    return PropertyGroup.other;
  }

  bool get isEventHall => propertyType == PropertyType.eventHall;
  bool get isDailyRental =>
      listingType == ListingType.rentShort && !isEventHall;
  bool get isBookable => isDailyRental;
  static const utilities = {'hasWater', 'hasElectricity', 'hasSewage'};
  static const residentialFeatures = {
    ...utilities,
    'hasPrivateRoof',
    'isInVilla',
    'hasTwoEntrances',
    'hasSpecialEntrance',
  };
  static const checklist = {
    'isFurnished',
    'hasKitchen',
    'hasExtraUnit',
    'hasCarEntrance',
    'hasElevator',
  };
  Set<String> get featureFields => switch (group) {
    PropertyGroup.residential => residentialFeatures,
    PropertyGroup.land => utilities,
    _ => {},
  };
  Set<String> get detailFields => switch (group) {
    PropertyGroup.residential => {
      'bedrooms',
      'livingRooms',
      'bathrooms',
      'floor',
      'propertyAge',
      'streetWidth',
      'facade',
      ...checklist,
    },
    PropertyGroup.commercial => {
      'bathrooms',
      'floor',
      'propertyAge',
      'streetWidth',
      'facade',
    },
    PropertyGroup.land => {'streetWidth', 'facade'},
    PropertyGroup.eventHall => {
      'maxGuests',
      'pricePerHalfDay',
      'includedServices',
    },
    _ => {},
  };
  Set<String> get bookingFields => isDailyRental
      ? {'maxGuests', 'minNights', 'checkInTime', 'checkOutTime'}
      : {};
  Set<String> get allowedFields => {
    ...featureFields,
    ...detailFields,
    ...bookingFields,
  };

  /// Also used by detail/review rendering: unknown or hidden fields never leak.
  Map<String, dynamic> sanitizeDetails(Map<String, dynamic> values) => {
    for (final key in allowedFields)
      if (values[key] != null &&
          values[key] != '' &&
          !(values[key] is Iterable && (values[key] as Iterable).isEmpty))
        key: values[key],
  };
}

const includedServiceLabels = <String, String>{
  'catering': 'ضيافة',
  'sound_system': 'نظام صوت',
  'projector': 'جهاز عرض',
  'decoration': 'ديكور',
  'security': 'أمن',
  'parking': 'مواقف سيارات',
};
String includedServiceLabel(String value) =>
    includedServiceLabels[value] ?? value;
const facadeLabels = <String, String>{
  'north': 'شمال',
  'south': 'جنوب',
  'east': 'شرق',
  'west': 'غرب',
  'northeast': 'شمال شرقي',
  'northwest': 'شمال غربي',
  'southeast': 'جنوب شرقي',
  'southwest': 'جنوب غربي',
};
const listingFieldLabels = <String, String>{
  'title': 'عنوان الإعلان',
  'totalPrice': 'السعر (ريال)',
  'area': 'المساحة (م²)',
  'description': 'الوصف',
  'city': 'المدينة',
  'district': 'الحي',
  'address': 'العنوان',
  'latitude': 'خط العرض',
  'longitude': 'خط الطول',
  'coordinates': 'الموقع',
  'bedrooms': 'غرف النوم',
  'livingRooms': 'غرف المعيشة',
  'bathrooms': 'دورات المياه',
  'floor': 'الدور',
  'propertyAge': 'عمر العقار',
  'streetWidth': 'عرض الشارع',
  'facade': 'الواجهة',
  'hasWater': 'ماء',
  'hasElectricity': 'كهرباء',
  'hasSewage': 'صرف صحي',
  'hasPrivateRoof': 'سطح خاص',
  'isInVilla': 'داخل فيلا',
  'hasTwoEntrances': 'مدخلان',
  'hasSpecialEntrance': 'مدخل خاص',
  'isFurnished': 'مفروش',
  'hasKitchen': 'مطبخ',
  'hasExtraUnit': 'وحدة إضافية',
  'hasCarEntrance': 'مدخل سيارة',
  'hasElevator': 'مصعد',
  'maxGuests': 'السعة القصوى للضيوف',
  'minNights': 'الحد الأدنى لليالي',
  'checkInTime': 'وقت الدخول',
  'checkOutTime': 'وقت الخروج',
  'pricePerHalfDay': 'سعر نصف اليوم (ريال)',
  'includedServices': 'الخدمات المشمولة',
  'commission': 'توجد عمولة',
  'commissionPercent': 'نسبة العمولة',
  'categoryId': 'الفئة',
  'mediaUrls': 'الصور',
  'advertiserType': 'نوع المعلن',
  'licenseId': 'الترخيص',
};
