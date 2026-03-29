import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/listing.dart';
import '../../../home/data/listings_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

@immutable
class PropertyDetailsState {
  final Listing listing;
  final bool isFavorited;

  const PropertyDetailsState({
    required this.listing,
    required this.isFavorited,
  });

  PropertyDetailsState copyWith({Listing? listing, bool? isFavorited}) {
    return PropertyDetailsState(
      listing: listing ?? this.listing,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class PropertyDetailsNotifier
    extends Notifier<AsyncValue<PropertyDetailsState>> {
  final _repo = ListingsRepository();
  String _listingId = '';

  @override
  AsyncValue<PropertyDetailsState> build() => const AsyncLoading();

  Future<void> load(String listingId) async {
    _listingId = listingId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final results = await Future.wait([
        _repo.getListingById(listingId),
        _repo.getEngagementStatus(listingId),
      ]);
      return PropertyDetailsState(
        listing: results[0] as Listing,
        isFavorited: results[1] as bool,
      );
    });
  }

  Future<void> toggleFavorite() async {
    final current = state.value;
    if (current == null || _listingId.isEmpty) return;
    state = AsyncData(current.copyWith(isFavorited: !current.isFavorited));
    try {
      await _repo.toggleFavorite(targetId: _listingId);
    } catch (_) {
      state = AsyncData(current);
    }
  }
}

final propertyDetailsProvider =
    NotifierProvider<PropertyDetailsNotifier, AsyncValue<PropertyDetailsState>>(
      PropertyDetailsNotifier.new,
    );

// ── Feature helpers ───────────────────────────────────────────────────────────

class ListingFeature {
  final String label;
  final IconData icon;
  const ListingFeature({required this.label, required this.icon});
}

List<ListingFeature> getFeaturesFromListing(Listing listing) {
  final features = <ListingFeature>[];

  if (listing.hasWater) {
    features.add(
      const ListingFeature(label: 'ماء', icon: Icons.water_drop_rounded),
    );
  }
  if (listing.hasElectricity) {
    features.add(
      const ListingFeature(label: 'كهرباء', icon: Icons.electric_bolt_rounded),
    );
  }
  if (listing.hasSewage) {
    features.add(
      const ListingFeature(label: 'صرف صحي', icon: Icons.plumbing_rounded),
    );
  }
  if (listing.hasPrivateRoof) {
    features.add(
      const ListingFeature(label: 'سطح خاص', icon: Icons.roofing_rounded),
    );
  }
  if (listing.isInVilla) {
    features.add(
      const ListingFeature(label: 'داخل فيلا', icon: Icons.villa_rounded),
    );
  }
  if (listing.hasTwoEntrances) {
    features.add(
      const ListingFeature(
        label: 'مدخلين',
        icon: Icons.door_front_door_rounded,
      ),
    );
  }
  if (listing.hasSpecialEntrance) {
    features.add(
      const ListingFeature(label: 'مدخل خاص', icon: Icons.door_sliding_rounded),
    );
  }
  if (listing.isFurnished) {
    features.add(
      const ListingFeature(label: 'مؤثث', icon: Icons.chair_rounded),
    );
  }
  if (listing.hasKitchen) {
    features.add(
      const ListingFeature(label: 'مطبخ راكب', icon: Icons.kitchen_rounded),
    );
  }
  if (listing.hasExtraUnit) {
    features.add(
      const ListingFeature(label: 'ملحق', icon: Icons.add_home_rounded),
    );
  }
  if (listing.hasCarEntrance) {
    features.add(
      const ListingFeature(label: 'مدخل سيارة', icon: Icons.garage_rounded),
    );
  }
  if (listing.hasElevator) {
    features.add(
      const ListingFeature(label: 'مصعد', icon: Icons.elevator_rounded),
    );
  }

  return features;
}
