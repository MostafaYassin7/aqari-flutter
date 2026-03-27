import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../shared/models/listing.dart';
import '../../../home/data/mock_listings.dart';

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

  const MapState({
    this.viewMode = MapViewMode.list,
    this.selectedListingId,
    this.visibleBounds,
    this.currentZoom = 5.5,
    this.showSearchArea = false,
  });

  MapState copyWith({
    MapViewMode? viewMode,
    String? selectedListingId,
    bool clearSelectedListing = false,
    LatLngBounds? visibleBounds,
    double? currentZoom,
    bool? showSearchArea,
  }) {
    return MapState(
      viewMode: viewMode ?? this.viewMode,
      selectedListingId: clearSelectedListing
          ? null
          : (selectedListingId ?? this.selectedListingId),
      visibleBounds: visibleBounds ?? this.visibleBounds,
      currentZoom: currentZoom ?? this.currentZoom,
      showSearchArea: showSearchArea ?? this.showSearchArea,
    );
  }

  /// Whether to show city-level clusters (zoomed out) or individual pins.
  bool get showClusters => currentZoom < 8.5;

  /// Listings visible inside the current map bounds.
  List<Listing> get visibleListings {
    final bounds = visibleBounds;
    if (bounds == null) return mockListings;
    return mockListings.where((l) {
      if (l.lat == 0.0 && l.lng == 0.0) return false;
      return l.lat >= bounds.southwest.latitude &&
          l.lat <= bounds.northeast.latitude &&
          l.lng >= bounds.southwest.longitude &&
          l.lng <= bounds.northeast.longitude;
    }).toList();
  }

  /// City-level clusters derived from all listings.
  List<CityCluster> get cityClusters {
    final map = <String, List<Listing>>{};
    for (final l in mockListings) {
      map.putIfAbsent(l.city, () => []).add(l);
    }
    return map.entries.map((e) {
      final lats = e.value.map((l) => l.lat);
      final lngs = e.value.map((l) => l.lng);
      final centerLat =
          lats.reduce((a, b) => a + b) / e.value.length;
      final centerLng =
          lngs.reduce((a, b) => a + b) / e.value.length;
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
    state = state.copyWith(
      visibleBounds: bounds,
      currentZoom: zoom,
    );
  }

  void markSearchAreaDirty() {
    state = state.copyWith(showSearchArea: true);
  }

  void clearSearchAreaFlag() {
    state = state.copyWith(showSearchArea: false);
  }
}

final mapProvider =
    NotifierProvider<MapNotifier, MapState>(MapNotifier.new);
