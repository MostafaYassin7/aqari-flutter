// نوع المُعلن — advertiser types used in property advertisement licenses
// Values are lowercase strings that must match backend enum exactly (see RULE 6)
class AdvertiserType {
  // مالك — property owner advertising their own property
  // Required documents: ownership deed + owner ID + optional POA
  // Used by: owner flow (step0a + step0b)
  static const owner  = 'owner';

  // وكيل — agent acting on behalf of property owner via power of attorney
  // Required documents: same as owner PLUS power of attorney number + agent ID
  // Issued by: Saudi Ministry of Justice (وزارة العدل)
  // Used by: agent flow (step0a + step0b with agent-specific fields)
  static const agent  = 'agent';

  // مسوق عقاري — licensed real estate broker
  // Required documents: فال license number + brokerage contract number
  // Issued by: General Real Estate Authority (الهيئة العامة للعقار)
  // Used by: broker flow (step0c)
  static const broker = 'broker';

  // مضيف — short-term rental host
  // No license required — listing publishes immediately
  // Used by: host flow (no license steps)
  static const host   = 'host';
}

// نوع وثيقة الملكية — property ownership document type
// Determines which document number field label is shown in step0b
class OwnershipDocumentType {
  // صك إلكتروني — electronic property deed (most common)
  static const electronicDeed = 'electronic_deed';

  // رقم العقار — property number assigned by municipality
  static const propertyNumber = 'property_number';

  // رقم السجل العيني — land registry number
  // Registered in: eservicesredp.rega.gov.sa
  static const landRegistry   = 'land_registry';

  // غير ذلك — other document type not covered above
  static const other          = 'other';
}

// نوع هوية المالك — property owner identity document type
// Determines which fields are shown: individuals show birth date,
// companies/entities show commercial registration number instead
class PropertyOwnerIdType {
  // هوية وطنية — Saudi national ID for individual owners
  // When selected: shows تاريخ ميلاد المالك field
  static const nationalId             = 'national_id';

  // سجل تجاري — commercial registration for company owners
  // When selected: shows رقم السجل التجاري للمنشأة (no birth date)
  static const commercialRegistration = 'commercial_registration';

  // الرقم الموحد 700 — unified 700 number for entities/institutions
  // When selected: shows رقم السجل التجاري للمنشأة (no birth date)
  static const unified700             = 'unified_700';
}
