import 'providers/add_listing_provider.dart';

/// Form-only checks, matching the web's visible requirements and input bounds.
/// No license, publishing, availability, or payment requests are made here.
Map<String, String> listingStepErrors(AddListingState s, String step) {
  final errors = <String, String>{};
  void required(String key, String label, String value) {
    if (value.trim().isEmpty) errors[key] = '$label مطلوب';
  }

  void number(
    String key,
    String label,
    String value, {
    double min = 0,
    bool positive = false,
    bool integer = false,
    bool mandatory = false,
    double? max,
  }) {
    if (value.trim().isEmpty) {
      if (mandatory) errors[key] = '$label مطلوب';
      return;
    }
    final v = double.tryParse(value);
    if (v == null ||
        !v.isFinite ||
        (positive ? v <= 0 : v < min) ||
        (integer && v != v.roundToDouble()) ||
        (max != null && v > max)) {
      errors[key] = '$label غير صالح';
    }
  }

  switch (step) {
    case 'license':
      if (s.role == 'host') {
        required('tourism', 'رقم رخصة وزارة السياحة', s.value('tourism'));
      } else if (s.role == 'broker') {
        required('adLicense', 'رقم ترخيص الإعلان', s.value('adLicense'));
        required('brokerOwnerId', 'رقم هوية المالك', s.value('brokerOwnerId'));
      } else if (s.value('skipLicense') != 'true') {
        required('document', 'رقم وثيقة الملكية', s.value('document'));
        required('ownerId', 'رقم هوية المالك', s.value('ownerId'));
        if (s.value('idType') == 'national') {
          required('birth', 'تاريخ ميلاد المالك', s.value('birth'));
        }
        if (s.role == 'agent') {
          required('agency', 'رقم الوكالة', s.value('agency'));
          required('agentId', 'رقم هوية الوكيل', s.value('agentId'));
          required('agentBirth', 'تاريخ ميلاد الوكيل', s.value('agentBirth'));
        }
      }
    case 'media':
      if (s.value('uploading') == 'true' || s.value('uploadError').isNotEmpty) {
        errors['mediaUrls'] = 'أكمل رفع الصور أو أعد محاولة الرفع';
      }
    case 'category':
      required('category', 'نوع العقار', s.propertyType);
    case 'info':
      required('title', 'عنوان الإعلان', s.value('title'));
      if (s.value('title').length > 100) {
        errors['title'] = 'الحد الأقصى للعنوان 100 حرف';
      }
      if (s.description.length > 2000) {
        errors['description'] = 'الحد الأقصى للوصف 2000 حرف';
      }
      number('price', 'السعر', s.price, positive: true, mandatory: true);
      number('area', 'المساحة', s.area, positive: true, mandatory: true);
      if (s.hasCommission) {
        number('commission', 'نسبة العمولة', s.commissionPercent, max: 100);
      }
    case 'details':
      if (s.group == 'hall') {
        number(
          'capacity',
          'عدد الضيوف',
          s.value('capacity'),
          positive: true,
          integer: true,
        );
        number('halfDay', 'سعر نصف يوم', s.value('halfDay'));
      } else if (['residential', 'commercial', 'land'].contains(s.group)) {
        number('street', 'عرض الشارع', s.streetWidth);
        if (s.group != 'land') {
          number('floor', 'رقم الدور', s.floorNumber, integer: true);
          number('age', 'عمر العقار', s.propertyAge);
        }
      }
    case 'booking':
      if (s.isDaily) {
        number(
          'capacity',
          'عدد الضيوف',
          s.value('capacity'),
          positive: true,
          integer: true,
        );
        number(
          'minNights',
          'الحد الأدنى لليالي',
          s.value('minNights'),
          min: 1,
          integer: true,
          mandatory: true,
        );
      }
      for (final key in ['checkIn', 'checkOut']) {
        if (s.isDaily &&
            s.value(key).isNotEmpty &&
            !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(s.value(key))) {
          errors[key] = 'اختر وقتاً صالحاً بصيغة HH:mm';
        }
      }
    case 'location':
      required('city', 'المدينة', s.value('city'));
      if (s.value('pin') != 'selected' ||
          !s.lat.isFinite ||
          !s.lng.isFinite ||
          s.lat < -90 ||
          s.lat > 90 ||
          s.lng < -180 ||
          s.lng > 180) {
        errors['pin'] = 'حدد موقع العقار على الخريطة';
      }
  }
  return errors;
}

const licenseRequiredKeys = {
  'document',
  'ownerId',
  'birth',
  'agency',
  'agentId',
  'agentBirth',
  'adLicense',
  'brokerOwnerId',
  'tourism',
};
