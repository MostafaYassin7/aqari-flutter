import '../presentation/providers/add_listing_provider.dart';
import '../../../shared/domain/property_rules.dart';

Map<String, dynamic> listingLicensePayload(AddListingState s) {
  final idType = switch (s.value(
    s.role == 'broker' ? 'brokerIdType' : 'idType',
  )) {
    'commercial' => 'commercial_registration',
    'unified' => 'unified_700',
    _ => 'national_id',
  };
  if (s.role == 'host') {
    return {'tourismLicenseNumber': s.value('tourism').trim()};
  }
  if (s.role == 'broker') {
    return {
      'adLicenseNumber': s.value('adLicense').trim(),
      'ownerIdType': idType,
      'ownerIdNumber': s.value('brokerOwnerId').trim(),
    };
  }
  final values = <String, dynamic>{
    'advertiserType': s.role,
    'ownershipDocumentType': switch (s.value('documentType')) {
      'property' => 'property_number',
      'registry' => 'land_registry',
      'other' => 'other',
      _ => 'electronic_deed',
    },
    'ownershipDocumentNumber': s.value('document').trim(),
    'propertyOwnerIdType': idType,
    switch (idType) {
      'commercial_registration' => 'ownerCommercialRegNumber',
      'unified_700' => 'ownerUnifiedNumber',
      _ => 'ownerNationalIdNumber',
    }: s
        .value('ownerId')
        .trim(),
    if (idType == 'national_id') ...{
      'propertyOwnerBirthDate': s.value('birth'),
      'isHijriCalendar': s.value('calendar') == 'hijri',
    },
    'propertyOwnerPhone': s.value('phone').trim(),
    'oneOfOwnersNationalId': s.value('coOwner').trim(),
    if (s.role == 'agent') ...{
      'powerOfAttorneyNumber': s.value('agency').trim(),
      'agentNationalIdNumber': s.value('agentId').trim(),
      'agentBirthDate': s.value('agentBirth'),
      'agentPhone': s.value('agentPhone').trim(),
    },
  };
  return values..removeWhere((_, value) => value == '');
}

/// The whitelist is independent of state clearing, so stale hidden fields cannot leak.
Map<String, dynamic> listingPayload(AddListingState s) {
  num? number(String v) {
    final n = num.tryParse(v.trim());
    return n != null && n.isFinite ? n : null;
  }

  const features = {
    'ماء': 'hasWater',
    'كهرباء': 'hasElectricity',
    'صرف صحي': 'hasSewage',
    'سطح خاص': 'hasPrivateRoof',
    'داخل فيلا': 'isInVilla',
    'مدخلين': 'hasTwoEntrances',
    'مدخل خاص': 'hasSpecialEntrance',
  };
  final details = <String, dynamic>{
    for (final entry in features.entries)
      entry.value: s.features.contains(entry.key),
    'bedrooms': s.bedrooms,
    'livingRooms': s.livingRooms,
    'bathrooms': s.bathrooms,
    'floor': number(s.floorNumber),
    'propertyAge': number(s.propertyAge),
    'streetWidth': number(s.streetWidth),
    'facade': facadeLabels.entries
        .where((e) => e.value == s.facade || e.key == s.facade)
        .firstOrNull
        ?.key,
    'isFurnished': s.isFurnished,
    'hasKitchen': s.hasKitchen,
    'hasExtraUnit': s.hasExtraUnit,
    'hasCarEntrance': s.hasCarEntrance,
    'hasElevator': s.hasElevator,
    'maxGuests': int.tryParse(s.value('capacity')),
    'minNights': int.tryParse(s.value('minNights')),
    'checkInTime': s.value('checkIn'),
    'checkOutTime': s.value('checkOut'),
    'pricePerHalfDay': number(s.value('halfDay')),
    'includedServices': [
      for (final key in includedServiceLabels.keys)
        if (s.value(key) == 'true') key,
    ],
  };
  return {
    'categoryId': s.categoryId,
    'propertyType': s.propertyType,
    'listingType': s.listingType,
    'title': s.value('title').trim(),
    if (s.description.trim().isNotEmpty) 'description': s.description.trim(),
    'totalPrice': number(s.price),
    'area': number(s.area),
    'usageType': s.isResidential ? 'residential' : 'commercial',
    'commission': s.hasCommission,
    if (s.hasCommission && number(s.commissionPercent) != null)
      'commissionPercent': number(s.commissionPercent),
    'city': s.value('city'),
    if (s.value('district').isNotEmpty) 'district': s.value('district'),
    if (s.address.trim().isNotEmpty) 'address': s.address.trim(),
    'latitude': s.lat,
    'longitude': s.lng,
    if (s.photos.isNotEmpty) 'mediaUrls': s.photos,
    'advertiserType': s.role,
    if (s.value('licenseId').isNotEmpty) 'licenseId': s.value('licenseId'),
    ...s.rules.sanitizeDetails(details),
  };
}
