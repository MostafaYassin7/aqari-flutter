class CityEntry {
  final String ar;
  final String en;
  const CityEntry(this.ar, this.en);
}

const cities = [
  CityEntry('الرياض', 'Riyadh'),
  CityEntry('جدة', 'Jeddah'),
  CityEntry('مكة المكرمة', 'Mecca'),
  CityEntry('المدينة المنورة', 'Medina'),
  CityEntry('الدمام', 'Dammam'),
  CityEntry('الخبر', 'Khobar'),
  CityEntry('الظهران', 'Dhahran'),
  CityEntry('الأحساء', 'Al Ahsa'),
  CityEntry('القطيف', 'Qatif'),
  CityEntry('أبها', 'Abha'),
  CityEntry('خميس مشيط', 'Khamis Mushait'),
  CityEntry('الطائف', 'Taif'),
  CityEntry('تبوك', 'Tabuk'),
  CityEntry('بريدة', 'Buraidah'),
  CityEntry('عنيزة', 'Unaizah'),
  CityEntry('حائل', 'Hail'),
  CityEntry('نجران', 'Najran'),
  CityEntry('جازان', 'Jizan'),
  CityEntry('ينبع', 'Yanbu'),
  CityEntry('القنفذة', 'Al Qunfudhah'),
];

/// Returns the Arabic label for a stored English city value.
/// Falls back to the English value if not found.
String cityArLabel(String en) {
  for (final c in cities) {
    if (c.en == en) return c.ar;
  }
  return en;
}

class DistrictEntry {
  final String ar;
  final String en;
  const DistrictEntry(this.ar, this.en);
}

const districtsByCity = <String, List<DistrictEntry>>{
  'Riyadh': [
    DistrictEntry('العليا', 'Al Olaya'),
    DistrictEntry('السليمانية', 'Al Sulaimaniyah'),
    DistrictEntry('الملز', 'Al Malaz'),
    DistrictEntry('المربع', 'Al Murabba'),
    DistrictEntry('الروضة', 'Al Rawdah'),
    DistrictEntry('النرجس', 'Al Narjis'),
    DistrictEntry('حطين', 'Hittin'),
    DistrictEntry('الرحمانية', 'Al Rahmaniyah'),
    DistrictEntry('الربوة', 'Al Rabwah'),
    DistrictEntry('الياسمين', 'Al Yasmin'),
    DistrictEntry('الوادي', 'Al Wadi'),
    DistrictEntry('النفل', 'Al Nafal'),
    DistrictEntry('العارض', 'Al Arid'),
    DistrictEntry('الصحافة', 'Al Sahafa'),
    DistrictEntry('قرطبة', 'Qurtubah'),
  ],
  'Jeddah': [
    DistrictEntry('البلد', 'Al Balad'),
    DistrictEntry('الحمراء', 'Al Hamra'),
    DistrictEntry('الروضة', 'Al Rawdah'),
    DistrictEntry('الأندلس', 'Al Andalus'),
    DistrictEntry('الصفا', 'Al Safa'),
    DistrictEntry('الزهراء', 'Al Zahra'),
    DistrictEntry('مشرفة', 'Mushrifah'),
    DistrictEntry('بن خلدون', 'Ibn Khaldoun'),
    DistrictEntry('الربوة', 'Al Rabwah'),
    DistrictEntry('النعيم', 'Al Naim'),
    DistrictEntry('أم السلم', 'Um Al Salam'),
    DistrictEntry('السلامة', 'Al Salamah'),
    DistrictEntry('الفيصلية', 'Al Faisaliyah'),
    DistrictEntry('النزهة', 'Al Nuzhah'),
    DistrictEntry('الشاطئ', 'Al Shati'),
  ],
  'Dammam': [
    DistrictEntry('الفيصلية', 'Al Faisaliyah'),
    DistrictEntry('الشاطئ', 'Al Shati'),
    DistrictEntry('العنود', 'Al Anoud'),
    DistrictEntry('البادية', 'Al Badiyah'),
    DistrictEntry('النور', 'Al Nour'),
    DistrictEntry('المنار', 'Al Manar'),
    DistrictEntry('الريان', 'Al Rayyan'),
    DistrictEntry('الروابي', 'Al Rawabi'),
    DistrictEntry('القزاز', 'Al Qazzaz'),
    DistrictEntry('الدواسر', 'Al Dawasir'),
  ],
  'Khobar': [
    DistrictEntry('العزيزية', 'Al Aziziyah'),
    DistrictEntry('الراكة', 'Al Rakah'),
    DistrictEntry('الثقبة', 'Al Thuqbah'),
    DistrictEntry('الكورنيش', 'Al Corniche'),
    DistrictEntry('الصفا', 'Al Safa'),
    DistrictEntry('اليرموك', 'Al Yarmuk'),
    DistrictEntry('الخبر الشمالية', 'Khobar North'),
  ],
  'Mecca': [
    DistrictEntry('العزيزية', 'Al Aziziyah'),
    DistrictEntry('أجياد', 'Ajyad'),
    DistrictEntry('الزاهر', 'Al Zaher'),
    DistrictEntry('الشوقية', 'Al Shawqiyah'),
    DistrictEntry('النسيم', 'Al Naseem'),
  ],
  'Medina': [
    DistrictEntry('العزيزية', 'Al Aziziyah'),
    DistrictEntry('قباء', 'Quba'),
    DistrictEntry('السيح', 'Al Sayh'),
    DistrictEntry('بني حارثة', 'Bani Harithah'),
    DistrictEntry('النور', 'Al Nour'),
  ],
};

/// Returns the Arabic label for a stored English district value.
/// Falls back to the English value if not found.
String districtArLabel(String en) {
  for (final list in districtsByCity.values) {
    for (final d in list) {
      if (d.en == en) return d.ar;
    }
  }
  return en;
}
