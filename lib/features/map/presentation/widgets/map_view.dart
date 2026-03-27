import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/listing.dart';
import '../../../home/data/mock_listings.dart';
import '../providers/map_provider.dart';

// ── Map View ──────────────────────────────────────────────────────────────────

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  GoogleMapController? _mapController;
  late PageController _pageController;

  // Cache for generated markers so we don't redraw every frame.
  final Map<String, BitmapDescriptor> _markerCache = {};

  // Track page changes vs camera-driven changes to avoid loops.
  bool _programmingPageChange = false;
  bool _programmingCameraMove = false;

  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(23.5, 43.5),
    zoom: 5.5,
  );

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ── Marker helpers ───────────────────────────────────────────────────────

  String _compactPrice(double price) {
    if (price >= 1000000) {
      final m = price / 1000000;
      return m == m.truncateToDouble()
          ? '${m.toInt()}M'
          : '${m.toStringAsFixed(1)}M';
    }
    if (price >= 1000) {
      return '${(price / 1000).round()}K';
    }
    return price.toInt().toString();
  }

  Future<BitmapDescriptor> _buildPriceMarker(
      double price, bool selected) async {
    final label = _compactPrice(price);
    final cacheKey = '${label}_$selected';
    if (_markerCache.containsKey(cacheKey)) return _markerCache[cacheKey]!;

    const double w = 110, h = 44, r = 22, arrowH = 8;
    final totalH = h + arrowH;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final fillColor = selected ? AppColors.primary : Colors.white;
    final textColor = selected ? Colors.white : AppColors.textPrimaryLight;

    final paint = Paint()..color = fillColor;
    final borderPaint = Paint()
      ..color = selected ? AppColors.primaryDark : const Color(0xFF222222)
      ..strokeWidth = selected ? 0 : 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(r),
    );

    // Shadow
    final shadowPaint = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(
      rrect.shift(const Offset(0, 2)),
      shadowPaint,
    );

    // Fill
    canvas.drawRRect(rrect, paint);
    // Border
    canvas.drawRRect(rrect, borderPaint);

    // Downward arrow/triangle
    final arrowPath = Path()
      ..moveTo(w / 2 - 8, h)
      ..lineTo(w / 2 + 8, h)
      ..lineTo(w / 2, h + arrowH)
      ..close();
    canvas.drawPath(arrowPath, paint);
    if (!selected) {
      final arrowBorder = Paint()
        ..color = const Color(0xFF222222)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawPath(arrowPath, arrowBorder);
    }

    // Text
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w);
    tp.paint(canvas, Offset((w - tp.width) / 2, (h - tp.height) / 2));

    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), totalH.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final descriptor = BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: 55,
    );
    _markerCache[cacheKey] = descriptor;
    return descriptor;
  }

  Future<BitmapDescriptor> _buildClusterMarker(int count) async {
    final cacheKey = 'cluster_$count';
    if (_markerCache.containsKey(cacheKey)) return _markerCache[cacheKey]!;

    const double size = 72;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Outer ring (translucent)
    final ringPaint = Paint()..color = AppColors.primary.withValues(alpha: 0.25);
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, ringPaint);

    // Inner filled circle
    final fillPaint = Paint()..color = AppColors.primary;
    canvas.drawCircle(const Offset(size / 2, size / 2), size * 0.38, fillPaint);

    // Count text
    final tp = TextPainter(
      text: TextSpan(
        text: '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size);
    tp.paint(
        canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2));

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final descriptor = BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: 44,
    );
    _markerCache[cacheKey] = descriptor;
    return descriptor;
  }

  Future<Set<Marker>> _buildMarkers(MapState mapState) async {
    final markers = <Marker>{};

    if (mapState.showClusters) {
      // City-level clusters
      for (final cluster in mapState.cityClusters) {
        final icon = await _buildClusterMarker(cluster.count);
        markers.add(Marker(
          markerId: MarkerId('cluster_${cluster.city}'),
          position: cluster.center,
          icon: icon,
          onTap: () {
            _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: cluster.center, zoom: 10.0),
              ),
            );
          },
        ));
      }
    } else {
      // Individual price pins
      final listings = mapState.visibleListings.isEmpty
          ? mockListings
          : mapState.visibleListings;

      for (final listing in listings) {
        if (listing.lat == 0.0 && listing.lng == 0.0) continue;
        final selected = listing.id == mapState.selectedListingId;
        final icon = await _buildPriceMarker(listing.price, selected);
        markers.add(Marker(
          markerId: MarkerId(listing.id),
          position: LatLng(listing.lat, listing.lng),
          icon: icon,
          anchor: const Offset(0.5, 1.0),
          zIndex: selected ? 1.0 : 0.0,
          onTap: () {
            ref.read(mapProvider.notifier).selectListing(listing.id);
            _scrollCardToListing(listing.id);
          },
        ));
      }
    }
    return markers;
  }

  // ── Card shelf helpers ───────────────────────────────────────────────────

  void _scrollCardToListing(String id) {
    final listings =
        ref.read(mapProvider).visibleListings.isEmpty
            ? mockListings
            : ref.read(mapProvider).visibleListings;
    final idx = listings.indexWhere((l) => l.id == id);
    if (idx < 0) return;
    _programmingPageChange = true;
    _pageController.animateToPage(
      idx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _onCardPageChanged(int index) {
    if (_programmingPageChange) {
      _programmingPageChange = false;
      return;
    }
    final listings =
        ref.read(mapProvider).visibleListings.isEmpty
            ? mockListings
            : ref.read(mapProvider).visibleListings;
    if (index >= listings.length) return;
    final listing = listings[index];
    ref.read(mapProvider.notifier).selectListing(listing.id);

    // Pan camera to the listing
    if (!_programmingCameraMove) {
      _programmingCameraMove = true;
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(listing.lat, listing.lng)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final listings = mapState.visibleListings.isEmpty
        ? mockListings
        : mapState.visibleListings;

    return FutureBuilder<Set<Marker>>(
      future: _buildMarkers(mapState),
      builder: (context, snapshot) {
        final markers = snapshot.data ?? {};

        return Stack(
          children: [
            // ── Google Map ────────────────────────────────────────────────
            GoogleMap(
              initialCameraPosition: _initialCamera,
              markers: markers,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onCameraIdle: () async {
                if (_mapController == null) return;
                // Reset the programmatic flag so the next user gesture
                // can mark the search area as dirty again.
                _programmingCameraMove = false;
                final bounds =
                    await _mapController!.getVisibleRegion();
                final zoom = await _mapController!.getZoomLevel();
                ref
                    .read(mapProvider.notifier)
                    .updateBoundsAndZoom(bounds, zoom);
              },
              onCameraMove: (_) {
                if (!_programmingCameraMove) {
                  ref
                      .read(mapProvider.notifier)
                      .markSearchAreaDirty();
                }
              },
            ),

            // ── "Search this area" button ─────────────────────────────────
            if (mapState.showSearchArea)
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: _SearchAreaButton(
                    onTap: () {
                      ref
                          .read(mapProvider.notifier)
                          .clearSearchAreaFlag();
                    },
                  ),
                ),
              ),

            // ── Bottom card shelf ─────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 80,
              child: SizedBox(
                height: 130,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onCardPageChanged,
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    final selected =
                        listing.id == mapState.selectedListingId;
                    return _MapCard(
                      listing: listing,
                      selected: selected,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Search area button ────────────────────────────────────────────────────────

class _SearchAreaButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchAreaButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_rounded,
                size: 16, color: AppColors.textPrimaryLight),
            const SizedBox(width: 6),
            Text(
              'ابحث في هذه المنطقة',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Horizontal map listing card ───────────────────────────────────────────────

class _MapCard extends StatelessWidget {
  final Listing listing;
  final bool selected;

  const _MapCard({required this.listing, required this.selected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/property/${listing.id}'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : const Color(0x26000000),
              blurRadius: selected ? 16 : 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Photo
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: listing.imageUrls.first,
                width: 110,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                    color: AppColors.surfaceLight,
                    child: const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary))),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.surfaceLight,
                  child: const Center(
                    child: Icon(Icons.home_rounded,
                        size: 32, color: AppColors.primary),
                  ),
                ),
              ),
            ),

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      listing.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${listing.city}  ·  ${listing.district}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatPrice(listing.price),
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
