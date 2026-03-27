import 'package:flutter_riverpod/flutter_riverpod.dart';

// Sentinel for nullable copyWith fields
class _Unset {
  const _Unset();
}

const _kUnset = _Unset();

// ── State ─────────────────────────────────────────────────────────────────────

class AddListingState {
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
      category: identical(category, _kUnset) ? this.category : category as String?,
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
  AddListingState build() => const AddListingState();

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
  void setBedrooms(int v) =>
      state = state.copyWith(bedrooms: v.clamp(0, 20));
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
  void setAddress(String v) => state = state.copyWith(address: v);
  void setLocation(double lat, double lng) =>
      state = state.copyWith(lat: lat, lng: lng);

  // Reset
  void reset() => state = const AddListingState();
}

final addListingProvider =
    NotifierProvider<AddListingNotifier, AddListingState>(
        AddListingNotifier.new);
