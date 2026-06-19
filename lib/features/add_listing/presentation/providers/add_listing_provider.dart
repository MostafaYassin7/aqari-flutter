import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/advertiser_types.dart';

// Sentinel for nullable copyWith fields
class _Unset {
  const _Unset();
}

const _kUnset = _Unset();

// ── State ─────────────────────────────────────────────────────────────────────

class AddListingState {
  // Step 0 — Role & Service
  final String selectedRole;
  final String selectedService;

  // ── License fields ────────────────────────────────────────────────────────

  // نوع المُعلن — advertiser type, set from Step 0 role selection
  // Values: 'owner' | 'agent' | 'broker' | 'host'
  // Determines which license screens are shown and which fields are required
  // Used by: all license flows
  // Required: YES (has default 'owner')
  final String advertiserType;

  // معرّف الترخيص — license ID returned from POST /property-advertisement-licenses
  // Null until user submits the license form; passed to POST /listings
  // Used by: all advertiserTypes except 'host'
  // Required: only when advertiserType != 'host' and skipLicenseInfo = false
  final String? licenseId;

  // حالة تخطي الترخيص — true when user chose "إدخال البيانات لاحقاً"
  // When true, listing is created as DRAFT without licenseId
  // User must complete license from My Listings to publish
  // Used by: owner and agent flows only
  // Required: NO (defaults false)
  final bool skipLicenseInfo;

  // true while POST /property-advertisement-licenses is in flight
  final bool isSubmittingLicense;

  // ── Ownership document fields (owner + agent) ─────────────────────────────

  // نوع وثيقة الملكية — type of property ownership document
  // 'electronic_deed' | 'property_number' | 'land_registry' | 'other'
  // Used by: owner, agent
  // Required: YES
  final String ownershipDocumentType;

  // رقم الوثيقة — the actual document number (deed / property / registry)
  // Label changes based on ownershipDocumentType:
  //   electronic_deed → "رقم الصك الإلكتروني"
  //   property_number → "رقم العقار"
  //   land_registry   → "رقم السجل العيني"
  //   other           → "رقم الوثيقة"
  // Used by: owner, agent
  // Required: YES
  final String? ownershipDocumentNumber;

  // نوع هوية المالك — identity document type of the property owner
  // 'national_id' | 'commercial_registration' | 'unified_700'
  // Used by: owner, agent, broker
  // Required: YES
  final String propertyOwnerIdType;

  // رقم هوية المالك — identity document number of the property owner
  // Label changes based on propertyOwnerIdType
  // Used by: owner, agent, broker
  // Required: YES
  final String? propertyOwnerIdNumber;

  // تاريخ ميلاد المالك — birth date of the property owner
  // Only collected when propertyOwnerIdType = 'national_id'
  // NULL for commercial_registration and unified_700 (companies have no birth date)
  // Used by: owner, agent (only when national_id)
  // Required: YES when national_id
  final String? propertyOwnerBirthDate;

  // هل التاريخ بالتقويم الهجري؟ — true = Hijri calendar, false = Gregorian
  // Used by: owner, agent (when showing birth date field)
  // Required: YES (has default true — Hijri is standard in Saudi Arabia)
  final bool isHijriCalendar;

  // رقم جوال المالك — property owner's mobile phone number
  // Pre-filled from logged-in user's phone for owner role
  // For agent role, pre-filled from agent's (current user's) phone
  // Used by: owner, agent
  // Required: NO
  final String? propertyOwnerPhone;

  // رقم هوية أحد الملاك — national ID of one co-owner
  // Only applicable when property has multiple owners
  // Used by: owner, agent
  // Required: NO (optional)
  final String? oneOfOwnersNationalId;

  // رقم السجل التجاري للمنشأة — commercial registration number of the owning entity
  // Required ONLY when propertyOwnerIdType = 'commercial_registration' or 'unified_700'
  // NULL when propertyOwnerIdType = 'national_id'
  // Used by: owner, agent (only when commercial entity)
  // Required: YES when commercial_registration or unified_700
  final String? establishmentCommercialRegNumber;

  // ── Agent-specific fields ─────────────────────────────────────────────────

  // رقم الوكالة الرسمية — power of attorney number
  // Official POA document issued by Saudi Ministry of Justice (وزارة العدل)
  // Proves the agent is legally authorized to act on the owner's behalf
  // Used by: agent ONLY
  // Required: YES when advertiserType = 'agent'
  final String? powerOfAttorneyNumber;

  // رقم الهوية الوطنية للوكيل — national ID number of the agent (current user)
  // Used by: agent ONLY
  // Required: YES when advertiserType = 'agent'
  final String? agentNationalIdNumber;

  // تاريخ ميلاد الوكيل — birth date of the agent
  // Used by: agent ONLY
  // Required: YES when advertiserType = 'agent'
  final String? agentBirthDate;

  // رقم جوال الوكيل — agent's mobile phone number
  // Pre-filled from logged-in user's phone
  // Used by: agent ONLY
  // Required: NO
  final String? agentPhone;

  // ── Broker-specific fields ────────────────────────────────────────────────

  // رقم رخصة فال — FAL brokerage license number
  // License for real estate brokerage and marketing
  // Issued by: General Real Estate Authority (الهيئة العامة للعقار)
  // Used by: broker ONLY
  // Required: YES when advertiserType = 'broker'
  final String? falLicenseNumber;

  // رقم عقد الوساطة — brokerage contract number
  // Contract registered between broker and property owner
  // Registered on: eservicesredp.rega.gov.sa
  // Used by: broker ONLY
  // Required: YES when advertiserType = 'broker'
  final String? brokerageContractNumber;

  // ── Listing steps ─────────────────────────────────────────────────────────

  // Step 1 — Category (from API)
  final String? category;       // display name (nameAr)
  final String? categoryId;     // UUID for API
  final String? propertyType;   // apartment, villa, land, …
  final String? listingType;    // sale, rent_long, rent_short

  // Step 2 — Media (local paths until upload, then CDN URLs)
  final List<String> photos;

  // Step 3 — Info
  final String title;
  final String price;
  final String area;
  final bool isResidential;
  final bool hasCommission;
  final String commissionPercent;
  final String description;

  // Step 4 — Features
  final Set<String> features;

  // Step 5 — Details
  final int bedrooms;
  final int livingRooms;
  final int bathrooms;
  final String? facade;
  final String streetWidth;
  final String floorNumber;
  final String propertyAge;
  final bool isFurnished;
  final bool hasKitchen;
  final bool hasExtraUnit;
  final bool hasCarEntrance;
  final bool hasElevator;

  // Step 6 — Location
  final String city;
  final String district;
  final String address;
  final double lat;
  final double lng;

  const AddListingState({
    this.selectedRole = 'owner',
    this.selectedService = 'listing',
    this.advertiserType = AdvertiserType.owner,
    this.licenseId,
    this.skipLicenseInfo = false,
    this.isSubmittingLicense = false,
    this.ownershipDocumentType = OwnershipDocumentType.electronicDeed,
    this.ownershipDocumentNumber,
    this.propertyOwnerIdType = PropertyOwnerIdType.nationalId,
    this.propertyOwnerIdNumber,
    this.propertyOwnerBirthDate,
    this.isHijriCalendar = true,
    this.propertyOwnerPhone,
    this.oneOfOwnersNationalId,
    this.establishmentCommercialRegNumber,
    this.powerOfAttorneyNumber,
    this.agentNationalIdNumber,
    this.agentBirthDate,
    this.agentPhone,
    this.falLicenseNumber,
    this.brokerageContractNumber,
    this.category,
    this.categoryId,
    this.propertyType,
    this.listingType,
    this.photos = const <String>[],
    this.title = '',
    this.price = '',
    this.area = '',
    this.isResidential = true,
    this.hasCommission = false,
    this.commissionPercent = '',
    this.description = '',
    this.features = const <String>{},
    this.bedrooms = 1,
    this.livingRooms = 1,
    this.bathrooms = 1,
    this.facade,
    this.streetWidth = '',
    this.floorNumber = '',
    this.propertyAge = '',
    this.isFurnished = false,
    this.hasKitchen = false,
    this.hasExtraUnit = false,
    this.hasCarEntrance = false,
    this.hasElevator = false,
    this.city = '',
    this.district = '',
    this.address = '',
    this.lat = 24.7136,
    this.lng = 46.6753,
  });

  AddListingState copyWith({
    String? selectedRole,
    String? selectedService,
    String? advertiserType,
    Object? licenseId = _kUnset,
    bool? skipLicenseInfo,
    bool? isSubmittingLicense,
    String? ownershipDocumentType,
    Object? ownershipDocumentNumber = _kUnset,
    String? propertyOwnerIdType,
    Object? propertyOwnerIdNumber = _kUnset,
    Object? propertyOwnerBirthDate = _kUnset,
    bool? isHijriCalendar,
    Object? propertyOwnerPhone = _kUnset,
    Object? oneOfOwnersNationalId = _kUnset,
    Object? establishmentCommercialRegNumber = _kUnset,
    Object? powerOfAttorneyNumber = _kUnset,
    Object? agentNationalIdNumber = _kUnset,
    Object? agentBirthDate = _kUnset,
    Object? agentPhone = _kUnset,
    Object? falLicenseNumber = _kUnset,
    Object? brokerageContractNumber = _kUnset,
    Object? category = _kUnset,
    Object? categoryId = _kUnset,
    Object? propertyType = _kUnset,
    Object? listingType = _kUnset,
    List<String>? photos,
    String? title,
    String? price,
    String? area,
    bool? isResidential,
    bool? hasCommission,
    String? commissionPercent,
    String? description,
    Set<String>? features,
    int? bedrooms,
    int? livingRooms,
    int? bathrooms,
    Object? facade = _kUnset,
    String? streetWidth,
    String? floorNumber,
    String? propertyAge,
    bool? isFurnished,
    bool? hasKitchen,
    bool? hasExtraUnit,
    bool? hasCarEntrance,
    bool? hasElevator,
    String? city,
    String? district,
    String? address,
    double? lat,
    double? lng,
  }) {
    return AddListingState(
      selectedRole: selectedRole ?? this.selectedRole,
      selectedService: selectedService ?? this.selectedService,
      advertiserType: advertiserType ?? this.advertiserType,
      licenseId: identical(licenseId, _kUnset) ? this.licenseId : licenseId as String?,
      skipLicenseInfo: skipLicenseInfo ?? this.skipLicenseInfo,
      isSubmittingLicense: isSubmittingLicense ?? this.isSubmittingLicense,
      ownershipDocumentType: ownershipDocumentType ?? this.ownershipDocumentType,
      ownershipDocumentNumber: identical(ownershipDocumentNumber, _kUnset)
          ? this.ownershipDocumentNumber
          : ownershipDocumentNumber as String?,
      propertyOwnerIdType: propertyOwnerIdType ?? this.propertyOwnerIdType,
      propertyOwnerIdNumber: identical(propertyOwnerIdNumber, _kUnset)
          ? this.propertyOwnerIdNumber
          : propertyOwnerIdNumber as String?,
      propertyOwnerBirthDate: identical(propertyOwnerBirthDate, _kUnset)
          ? this.propertyOwnerBirthDate
          : propertyOwnerBirthDate as String?,
      isHijriCalendar: isHijriCalendar ?? this.isHijriCalendar,
      propertyOwnerPhone: identical(propertyOwnerPhone, _kUnset)
          ? this.propertyOwnerPhone
          : propertyOwnerPhone as String?,
      oneOfOwnersNationalId: identical(oneOfOwnersNationalId, _kUnset)
          ? this.oneOfOwnersNationalId
          : oneOfOwnersNationalId as String?,
      establishmentCommercialRegNumber: identical(establishmentCommercialRegNumber, _kUnset)
          ? this.establishmentCommercialRegNumber
          : establishmentCommercialRegNumber as String?,
      powerOfAttorneyNumber: identical(powerOfAttorneyNumber, _kUnset)
          ? this.powerOfAttorneyNumber
          : powerOfAttorneyNumber as String?,
      agentNationalIdNumber: identical(agentNationalIdNumber, _kUnset)
          ? this.agentNationalIdNumber
          : agentNationalIdNumber as String?,
      agentBirthDate: identical(agentBirthDate, _kUnset) ? this.agentBirthDate : agentBirthDate as String?,
      agentPhone: identical(agentPhone, _kUnset) ? this.agentPhone : agentPhone as String?,
      falLicenseNumber: identical(falLicenseNumber, _kUnset)
          ? this.falLicenseNumber
          : falLicenseNumber as String?,
      brokerageContractNumber: identical(brokerageContractNumber, _kUnset)
          ? this.brokerageContractNumber
          : brokerageContractNumber as String?,
      category: identical(category, _kUnset) ? this.category : category as String?,
      categoryId: identical(categoryId, _kUnset) ? this.categoryId : categoryId as String?,
      propertyType: identical(propertyType, _kUnset) ? this.propertyType : propertyType as String?,
      listingType: identical(listingType, _kUnset) ? this.listingType : listingType as String?,
      photos: photos ?? this.photos,
      title: title ?? this.title,
      price: price ?? this.price,
      area: area ?? this.area,
      isResidential: isResidential ?? this.isResidential,
      hasCommission: hasCommission ?? this.hasCommission,
      commissionPercent: commissionPercent ?? this.commissionPercent,
      description: description ?? this.description,
      features: features ?? this.features,
      bedrooms: bedrooms ?? this.bedrooms,
      livingRooms: livingRooms ?? this.livingRooms,
      bathrooms: bathrooms ?? this.bathrooms,
      facade: identical(facade, _kUnset) ? this.facade : facade as String?,
      streetWidth: streetWidth ?? this.streetWidth,
      floorNumber: floorNumber ?? this.floorNumber,
      propertyAge: propertyAge ?? this.propertyAge,
      isFurnished: isFurnished ?? this.isFurnished,
      hasKitchen: hasKitchen ?? this.hasKitchen,
      hasExtraUnit: hasExtraUnit ?? this.hasExtraUnit,
      hasCarEntrance: hasCarEntrance ?? this.hasCarEntrance,
      hasElevator: hasElevator ?? this.hasElevator,
      city: city ?? this.city,
      district: district ?? this.district,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AddListingNotifier extends Notifier<AddListingState> {
  @override
  AddListingState build() => const AddListingState();

  // Step 0 — also syncs advertiserType when role changes
  void setRole(String v) {
    // Map selectedRole (step0 value) → advertiserType (license flow value)
    // 'marketer' maps to 'broker' (مسوق عقاري); other values map 1:1
    final advertiserType = v == 'marketer' ? AdvertiserType.broker : v;
    state = state.copyWith(selectedRole: v, advertiserType: advertiserType);
  }

  void setService(String v) => state = state.copyWith(selectedService: v);

  // ── License methods ───────────────────────────────────────────────────────

  // نوع المُعلن — called from step0b when user toggles between مالك and وكيل
  void setAdvertiserType(String type) =>
      state = state.copyWith(advertiserType: type);

  // Sets the licenseId returned from POST /property-advertisement-licenses
  // Called just before creating the listing in step7 submit flow
  void setLicenseId(String id) => state = state.copyWith(licenseId: id);

  // Generic license field updater — used by step0b and step0c form fields
  // Avoids exposing 15+ individual setter methods for license fields
  void setLicenseField(String field, dynamic value) {
    switch (field) {
      case 'ownershipDocumentType':
        state = state.copyWith(ownershipDocumentType: value as String);
      case 'ownershipDocumentNumber':
        state = state.copyWith(ownershipDocumentNumber: value as String?);
      case 'propertyOwnerIdType':
        state = state.copyWith(propertyOwnerIdType: value as String);
      case 'propertyOwnerIdNumber':
        state = state.copyWith(propertyOwnerIdNumber: value as String?);
      case 'propertyOwnerBirthDate':
        state = state.copyWith(propertyOwnerBirthDate: value as String?);
      case 'isHijriCalendar':
        state = state.copyWith(isHijriCalendar: value as bool);
      case 'propertyOwnerPhone':
        state = state.copyWith(propertyOwnerPhone: value as String?);
      case 'oneOfOwnersNationalId':
        state = state.copyWith(oneOfOwnersNationalId: value as String?);
      case 'establishmentCommercialRegNumber':
        state = state.copyWith(
            establishmentCommercialRegNumber: value as String?);
      case 'powerOfAttorneyNumber':
        state = state.copyWith(powerOfAttorneyNumber: value as String?);
      case 'agentNationalIdNumber':
        state = state.copyWith(agentNationalIdNumber: value as String?);
      case 'agentBirthDate':
        state = state.copyWith(agentBirthDate: value as String?);
      case 'agentPhone':
        state = state.copyWith(agentPhone: value as String?);
      case 'falLicenseNumber':
        state = state.copyWith(falLicenseNumber: value as String?);
      case 'brokerageContractNumber':
        state = state.copyWith(brokerageContractNumber: value as String?);
      case 'skipLicenseInfo':
        state = state.copyWith(skipLicenseInfo: value as bool);
    }
  }

  // Step 1 — category comes from API with all required metadata
  void setCategory({
    required String id,
    required String nameAr,
    required String propertyType,
    required String listingType,
  }) =>
      state = state.copyWith(
        category: nameAr,
        categoryId: id,
        propertyType: propertyType,
        listingType: listingType,
      );

  // Step 2
  void addPhoto(String url) =>
      state = state.copyWith(photos: [...state.photos, url]);
  void removePhoto(int index) {
    final list = List<String>.from(state.photos)..removeAt(index);
    state = state.copyWith(photos: list);
  }
  void reorderPhotos(int oldIndex, int newIndex) {
    final list = List<String>.from(state.photos);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(photos: list);
  }

  // Step 3
  void setTitle(String v) => state = state.copyWith(title: v);
  void setPrice(String v) => state = state.copyWith(price: v);
  void setArea(String v) => state = state.copyWith(area: v);
  void setIsResidential(bool v) => state = state.copyWith(isResidential: v);
  void setHasCommission(bool v) => state = state.copyWith(hasCommission: v);
  void setCommissionPercent(String v) =>
      state = state.copyWith(commissionPercent: v);
  void setDescription(String v) => state = state.copyWith(description: v);

  // Step 4
  void toggleFeature(String f) {
    final s = Set<String>.from(state.features);
    if (s.contains(f)) {
      s.remove(f);
    } else {
      s.add(f);
    }
    state = state.copyWith(features: s);
  }

  // Step 5
  void setBedrooms(int v) => state = state.copyWith(bedrooms: v.clamp(0, 20));
  void setLivingRooms(int v) =>
      state = state.copyWith(livingRooms: v.clamp(0, 10));
  void setBathrooms(int v) =>
      state = state.copyWith(bathrooms: v.clamp(0, 20));
  void setFacade(String? v) => state = state.copyWith(facade: v);
  void setStreetWidth(String v) => state = state.copyWith(streetWidth: v);
  void setFloorNumber(String v) => state = state.copyWith(floorNumber: v);
  void setPropertyAge(String v) => state = state.copyWith(propertyAge: v);
  void setIsFurnished(bool v) => state = state.copyWith(isFurnished: v);
  void setHasKitchen(bool v) => state = state.copyWith(hasKitchen: v);
  void setHasExtraUnit(bool v) => state = state.copyWith(hasExtraUnit: v);
  void setHasCarEntrance(bool v) => state = state.copyWith(hasCarEntrance: v);
  void setHasElevator(bool v) => state = state.copyWith(hasElevator: v);

  // Step 6
  void setCity(String v) => state = state.copyWith(city: v);
  void setDistrict(String v) => state = state.copyWith(district: v);
  void setAddress(String v) => state = state.copyWith(address: v);
  void setLocation(double lat, double lng) =>
      state = state.copyWith(lat: lat, lng: lng);

  // Reset
  void reset() => state = const AddListingState();
}

final addListingProvider =
    NotifierProvider<AddListingNotifier, AddListingState>(
        AddListingNotifier.new);
