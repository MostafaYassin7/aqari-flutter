import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../shared/models/listing.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum MapViewMode { list, map }

// ── City cluster data ─────────────────────────────────────────────────────────

class CityCluster {
  final String city;
  final LatLng center;
  final int count;

  const CityCluster({
    required this.city,
    required this.center,
    required this.count,
  });
}

// ── State ─────────────────────────────────────────────────────────────────────

class MapState {
  final MapViewMode viewMode;
  final String? selectedListingId;
  final LatLngBounds? visibleBounds;
  final double currentZoom;
  final bool showSearchArea;
  final List<Listing> allListings;

  const MapState({
    this.viewMode = MapViewMode.list,
    this.selectedListingId,
    this.visibleBounds,
    this.currentZoom = 5.5,
    this.showSearchArea = false,
    this.allListings = const [],
  });

  MapState copyWith({
    MapViewMode? viewMode,
    String? selectedListingId,
    bool clearSelectedListing = false,
    LatLngBounds? visibleBounds,
    double? currentZoom,
    bool? showSearchArea,
    List<Listing>? allListings,
  }) {
    return MapState(
      viewMode: viewMode ?? this.viewMode,
      selectedListingId: clearSelectedListing
          ? null
          : (selectedListingId ?? this.selectedListingId),
      visibleBounds: visibleBounds ?? this.visibleBounds,
      currentZoom: currentZoom ?? this.currentZoom,
      showSearchArea: showSearchArea ?? this.showSearchArea,
      allListings: allListings ?? this.allListings,
    );
  }

  /// Whether to show city-level clusters (zoomed out) or individual pins.
  bool get showClusters => currentZoom < 8.5;

  /// Listings visible inside the current map bounds.
  /// Returns ALL listings with valid coordinates — the map itself handles
  /// which markers are rendered based on the viewport.
  List<Listing> get visibleListings {
    // Return all listings that have valid coordinates.
    // Items without coordinates still appear in the card shelf.
    return allListings;
  }

  /// Only listings with valid lat/lng for placing markers on the map.
  List<Listing> get mappableListings {
    return allListings.where((l) => l.lat != 0.0 || l.lng != 0.0).toList();
  }

  /// City-level clusters derived from all listings.
  List<CityCluster> get cityClusters {
    final map = <String, List<Listing>>{};
    for (final l in allListings) {
      if (l.lat == 0.0 && l.lng == 0.0) continue;
      map.putIfAbsent(l.city, () => []).add(l);
    }
    return map.entries.map((e) {
      final lats = e.value.map((l) => l.lat);
      final lngs = e.value.map((l) => l.lng);
      final centerLat = lats.reduce((a, b) => a + b) / e.value.length;
      final centerLng = lngs.reduce((a, b) => a + b) / e.value.length;
      return CityCluster(
        city: e.key,
        center: LatLng(centerLat, centerLng),
        count: e.value.length,
      );
    }).toList();
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class MapNotifier extends Notifier<MapState> {
  @override
  MapState build() => const MapState();

  void toggleViewMode() {
    state = state.copyWith(
      viewMode: state.viewMode == MapViewMode.list
          ? MapViewMode.map
          : MapViewMode.list,
      clearSelectedListing: true,
      showSearchArea: false,
    );
  }

  void selectListing(String id) {
    state = state.copyWith(selectedListingId: id);
  }

  void clearSelection() {
    state = state.copyWith(clearSelectedListing: true);
  }

  void updateBoundsAndZoom(LatLngBounds bounds, double zoom) {
    state = state.copyWith(visibleBounds: bounds, currentZoom: zoom);
  }

  void markSearchAreaDirty() {
    state = state.copyWith(showSearchArea: true);
  }

  void clearSearchAreaFlag() {
    state = state.copyWith(showSearchArea: false);
  }

  void setListings(List<Listing> listings) {
    if (listings != state.allListings) {
      state = state.copyWith(allListings: listings);
    }
  }
}

final mapProvider = NotifierProvider<MapNotifier, MapState>(MapNotifier.new);
