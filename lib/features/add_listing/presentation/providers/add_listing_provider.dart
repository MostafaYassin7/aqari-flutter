import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/domain/property_rules.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Sentinel for nullable copyWith fields
class _Unset {
  const _Unset();
}

const _kUnset = _Unset();

// ── State ─────────────────────────────────────────────────────────────────────

class AddListingState {
  final Map<String, String> draft;
  final String propertyType, listingType, role;
  PropertyRules get rules => PropertyRules(propertyType, listingType);
  String get group => rules.isEventHall ? 'hall' : rules.group.name;
  bool get isDaily => rules.isDailyRental;
  List<String> get steps => [
    'role',
    if (role == 'owner' || role == 'agent') 'ownerInfo',
    'license',
    'category',
    'media',
    'info',
    'features',
    'details',
    if (isDaily) 'booking',
    'location',
    'review',
  ];
  String value(String key) =>
      draft[key] ??
      switch (key) {
        'minNights' => '1',
        'idType' || 'brokerIdType' => 'national',
        'documentType' => 'deed',
        'calendar' => 'gregorian',
        _ => '',
      };
  String get categoryId =>
      draft['categoryId'] ??
      (propertyType.isEmpty ? '' : 'preview-$propertyType-$listingType');
  // Step 1 — Category
  final String? category;

  // Step 2 — Media (simulated URLs)
  final List<String> photos;

  // Step 3 — Info
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
  final String address;
  final double lat;
  final double lng;

  const AddListingState({
    this.draft = const {},
    this.propertyType = '',
    this.listingType = 'sale',
    this.role = 'owner',
    this.category,
    this.photos = const <String>[],
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
    this.address = '',
    this.lat = 24.7136,
    this.lng = 46.6753,
  });

  AddListingState copyWith({
    Map<String, String>? draft,
    String? propertyType,
    String? listingType,
    String? role,
    Object? category = _kUnset,
    List<String>? photos,
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
    String? address,
    double? lat,
    double? lng,
  }) {
    return AddListingState(
      draft: draft ?? this.draft,
      propertyType: propertyType ?? this.propertyType,
      listingType: listingType ?? this.listingType,
      role: role ?? this.role,
      category: identical(category, _kUnset)
          ? this.category
          : category as String?,
      photos: photos ?? this.photos,
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
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AddListingNotifier extends Notifier<AddListingState> {
  @override
  AddListingState build() {
    ref.listen(authProvider.select((s) => s.user?.id), (previous, next) {
      if (previous != null && previous != next) reset();
    });
    return const AddListingState();
  }

  void field(String key, String value) {
    final draft = {...state.draft, key: value};
    if (key == 'idType') {
      draft.remove('ownerId');
      draft.remove('birth');
    }
    if (key == 'document' ||
        key == 'ownerId' ||
        key == 'birth' ||
        key == 'agency' ||
        key == 'agentId' ||
        key == 'agentBirth') {
      draft.remove('skipLicense');
    }
    if (licenseFields.contains(key)) {
      draft.remove('licenseId');
      draft.remove('licenseFingerprint');
    }
    state = state.copyWith(draft: draft);
  }

  void setRole(String role) {
    final draft = {...state.draft}
      ..remove('licenseId')
      ..remove('licenseFingerprint')
      ..remove('skipLicense');
    state = state.copyWith(role: role, draft: draft);
  }

  void selectType(
    String type,
    String listingType,
    String label, {
    String? categoryId,
  }) {
    if (type == 'event_hall') listingType = 'rent_short';
    final common = {
      for (final entry in state.draft.entries)
        if (!categoryFields.contains(entry.key)) entry.key: entry.value,
    };
    state = state.copyWith(
      category: label,
      propertyType: type,
      listingType: listingType,
      draft: {
        ...common,
        if (categoryId != null) 'categoryId': categoryId,
      }..removeWhere((key, value) => key == 'categoryId' && categoryId == null),
      features: {},
      bedrooms: 0,
      bathrooms: 0,
      livingRooms: 0,
      facade: null,
      streetWidth: '',
      floorNumber: '',
      propertyAge: '',
      isFurnished: false,
      hasKitchen: false,
      hasExtraUnit: false,
      hasCarEntrance: false,
      hasElevator: false,
    );
  }

  static const licenseFields = {
    'idType',
    'brokerIdType',
    'documentType',
    'document',
    'ownerId',
    'birth',
    'calendar',
    'phone',
    'coOwner',
    'agency',
    'agentId',
    'agentBirth',
    'agentPhone',
    'adLicense',
    'brokerOwnerId',
    'tourism',
    'skipLicense',
  };
  static const categoryFields = [
    'capacity',
    'halfDay',
    'minNights',
    'checkIn',
    'checkOut',
    'catering',
    'sound_system',
    'projector',
    'decoration',
    'security',
    'parking',
    'bedrooms',
    'livingRooms',
    'bathrooms',
    'floor',
    'age',
    'street',
    'facade',
    'furnished',
    'kitchen',
    'extra',
    'car',
    'elevator',
  ];
  // Step 1
  void setCategory(String v) => state = state.copyWith(category: v);

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
  void setBedrooms(int v) => state = state.copyWith(bedrooms: v < 0 ? 0 : v);
  void setLivingRooms(int v) =>
      state = state.copyWith(livingRooms: v < 0 ? 0 : v);
  void setBathrooms(int v) => state = state.copyWith(bathrooms: v < 0 ? 0 : v);
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
  void setAddress(String v) => state = state.copyWith(address: v);
  void setLocation(double lat, double lng) =>
      state = state.copyWith(lat: lat, lng: lng);

  // Reset
  void reset() => state = const AddListingState();
}

final addListingProvider =
    NotifierProvider<AddListingNotifier, AddListingState>(
      AddListingNotifier.new,
    );
