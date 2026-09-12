import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/preview/ui_preview.dart';
import '../providers/add_listing_provider.dart';
import '../data/listing_locations.dart';

class Step6Location extends ConsumerStatefulWidget {
  const Step6Location({super.key});
  @override
  ConsumerState<Step6Location> createState() => _Step6LocationState();
}

class _Step6LocationState extends ConsumerState<Step6Location> {
  Offset pin = const Offset(.5, .5);
  @override
  void initState() {
    super.initState();
    final s = ref.read(addListingProvider);
    pin = Offset(
      double.tryParse(s.value('pinX')) ?? .5,
      double.tryParse(s.value('pinY')) ?? .5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(addListingProvider);
    final n = ref.read(addListingProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('أين يقع العقار؟', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 8),
        Text(
          uiPreview
              ? 'اختر المدينة والحي وحدد الموقع على خريطة المعاينة'
              : 'اختر المدينة والحي وحدد الموقع على الخريطة',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: s.value('city').isEmpty ? null : s.value('city'),
          decoration: const InputDecoration(labelText: 'المدينة *'),
          items: listingCities.entries
              .map((c) => DropdownMenuItem(value: c.key, child: Text(c.value)))
              .toList(),
          onChanged: (v) {
            n.field('city', v!);
            n.field('district', '');
          },
        ),
        const SizedBox(height: 16),
        if ((listingDistricts[s.value('city')] ?? {}).isNotEmpty ||
            s.value('city').isEmpty)
          DropdownButtonFormField<String>(
            key: ValueKey(s.value('city')),
            initialValue: s.value('district').isEmpty
                ? null
                : s.value('district'),
            decoration: const InputDecoration(labelText: 'الحي (اختياري)'),
            items: (listingDistricts[s.value('city')] ?? <String, String>{})
                .entries
                .map(
                  (c) => DropdownMenuItem(value: c.key, child: Text(c.value)),
                )
                .toList(),
            onChanged: s.value('city').isEmpty
                ? null
                : (v) => n.field('district', v!),
          )
        else
          PreviewField(
            key: ValueKey(s.value('city')),
            label: 'الحي (اختياري)',
            value: s.value('district'),
            onChanged: (v) => n.field('district', v),
          ),
        const SizedBox(height: 16),
        PreviewField(
          label: 'العنوان (اختياري)',
          value: s.address,
          onChanged: n.setAddress,
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 250,
            child: !uiPreview
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(s.lat, s.lng),
                      zoom: 14,
                    ),
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    onTap: (point) {
                      n.setLocation(point.latitude, point.longitude);
                      n.field('pin', 'selected');
                    },
                    markers: s.value('pin') == 'selected'
                        ? {
                            Marker(
                              markerId: const MarkerId('listing-pin'),
                              position: LatLng(s.lat, s.lng),
                              draggable: true,
                              onDragEnd: (point) {
                                n.setLocation(point.latitude, point.longitude);
                                n.field('pin', 'selected');
                              },
                            ),
                          }
                        : {},
                  )
                : LayoutBuilder(
                    builder: (context, box) => GestureDetector(
                      onTapDown: (d) {
                        setState(
                          () => pin = Offset(
                            (d.localPosition.dx / box.maxWidth).clamp(.05, .95),
                            (d.localPosition.dy / box.maxHeight).clamp(.1, .9),
                          ),
                        );
                        n.field('pin', 'selected');
                        n.field('pinX', '${pin.dx}');
                        n.field('pinY', '${pin.dy}');
                        n.setLocation(
                          24.7136 + pin.dy * .01,
                          46.6753 + pin.dx * .01,
                        );
                      },
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(painter: _MapPainter()),
                          ),
                          Positioned(
                            left: pin.dx * box.maxWidth - 22,
                            top: pin.dy * box.maxHeight - 44,
                            child: const Icon(
                              Icons.location_pin,
                              color: AppColors.error,
                              size: 44,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          s.value('pin').isEmpty
              ? 'تحديد الموقع على الخريطة *'
              : uiPreview
              ? 'تم تحديد موقع المعاينة'
              : 'تم تحديد الموقع',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}
// ── Map painter ───────────────────────────────────────────────────────────────

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFE8F0E0);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Road paint
    final roadPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final minorRoadPaint = Paint()
      ..color = const Color(0xFFF5F5F0)
      ..strokeWidth = 6;

    // Block paint
    final blockPaint = Paint()..color = const Color(0xFFD4C9B0);

    // Draw blocks
    final blocks = [
      Rect.fromLTWH(20, 30, size.width * 0.3, size.height * 0.18),
      Rect.fromLTWH(
        size.width * 0.4,
        30,
        size.width * 0.25,
        size.height * 0.18,
      ),
      Rect.fromLTWH(
        size.width * 0.72,
        30,
        size.width * 0.25,
        size.height * 0.18,
      ),
      Rect.fromLTWH(
        20,
        size.height * 0.28,
        size.width * 0.2,
        size.height * 0.2,
      ),
      Rect.fromLTWH(
        size.width * 0.3,
        size.height * 0.28,
        size.width * 0.35,
        size.height * 0.2,
      ),
      Rect.fromLTWH(
        size.width * 0.72,
        size.height * 0.28,
        size.width * 0.25,
        size.height * 0.2,
      ),
      Rect.fromLTWH(
        20,
        size.height * 0.56,
        size.width * 0.28,
        size.height * 0.18,
      ),
      Rect.fromLTWH(
        size.width * 0.36,
        size.height * 0.56,
        size.width * 0.28,
        size.height * 0.18,
      ),
      Rect.fromLTWH(
        size.width * 0.72,
        size.height * 0.56,
        size.width * 0.25,
        size.height * 0.18,
      ),
      Rect.fromLTWH(
        20,
        size.height * 0.8,
        size.width * 0.45,
        size.height * 0.18,
      ),
      Rect.fromLTWH(
        size.width * 0.55,
        size.height * 0.8,
        size.width * 0.42,
        size.height * 0.18,
      ),
    ];
    for (final b in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(b, const Radius.circular(3)),
        blockPaint,
      );
    }

    // Horizontal roads
    for (final y in [
      size.height * 0.25,
      size.height * 0.52,
      size.height * 0.77,
    ]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }
    // Vertical roads
    for (final x in [size.width * 0.35, size.width * 0.68]) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }
    // Minor roads
    canvas.drawLine(
      Offset(0, size.height * 0.13),
      Offset(size.width, size.height * 0.13),
      minorRoadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.15, 0),
      Offset(size.width * 0.15, size.height),
      minorRoadPaint,
    );
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) => false;
}
