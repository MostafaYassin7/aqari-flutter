import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../providers/add_listing_provider.dart';

class Step6Location extends ConsumerStatefulWidget {
  const Step6Location({super.key});

  @override
  ConsumerState<Step6Location> createState() => _Step6LocationState();
}

class _Step6LocationState extends ConsumerState<Step6Location> {
  late TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    _addressCtrl =
        TextEditingController(text: ref.read(addListingProvider).address);
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppConstants.spaceM, AppConstants.spaceS,
              AppConstants.spaceM, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أين يقع العقار؟',
                style: AppTextStyles.headlineMedium
                    .copyWith(color: AppColors.textPrimaryLight),
              ),
              const SizedBox(height: 4),
              Text(
                'اضغط على الخريطة لتحديد الموقع بدقة',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // ── Map placeholder ───────────────────────────────────
        Expanded(
          child: Stack(
            children: [
              // Map canvas
              SizedBox.expand(
                child: CustomPaint(painter: _MapPainter()),
              ),

              // Pin
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_pin,
                      color: AppColors.error,
                      size: 48,
                    ),
                    SizedBox(height: 2),
                    SizedBox(width: 4, height: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.overlay,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // "Open Maps" button
              PositionedDirectional(
                bottom: 12,
                end: 12,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'سيتم فتح خرائط جوجل عند التكامل الكامل')),
                    );
                  },
                  icon: const Icon(Icons.open_in_new_rounded,
                      size: 16),
                  label: const Text('فتح الخريطة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.textPrimaryLight,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusCircle),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.shadowLight,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Address input ─────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppConstants.spaceM),
          decoration: const BoxDecoration(
            color: AppColors.backgroundLight,
            border: Border(
                top: BorderSide(color: AppColors.dividerLight)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'العنوان',
                style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addressCtrl,
                onChanged: (v) =>
                    ref.read(addListingProvider.notifier).setAddress(v),
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimaryLight),
                decoration: InputDecoration(
                  hintText: 'مثال: حي العليا، شارع الملك فهد، الرياض',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textHintLight),
                  prefixIcon: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusM),
                    borderSide:
                        const BorderSide(color: AppColors.dividerLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusM),
                    borderSide:
                        const BorderSide(color: AppColors.dividerLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusM),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                ),
              ),
            ],
          ),
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
      Rect.fromLTWH(size.width * 0.4, 30, size.width * 0.25, size.height * 0.18),
      Rect.fromLTWH(size.width * 0.72, 30, size.width * 0.25, size.height * 0.18),
      Rect.fromLTWH(20, size.height * 0.28, size.width * 0.2, size.height * 0.2),
      Rect.fromLTWH(size.width * 0.3, size.height * 0.28, size.width * 0.35, size.height * 0.2),
      Rect.fromLTWH(size.width * 0.72, size.height * 0.28, size.width * 0.25, size.height * 0.2),
      Rect.fromLTWH(20, size.height * 0.56, size.width * 0.28, size.height * 0.18),
      Rect.fromLTWH(size.width * 0.36, size.height * 0.56, size.width * 0.28, size.height * 0.18),
      Rect.fromLTWH(size.width * 0.72, size.height * 0.56, size.width * 0.25, size.height * 0.18),
      Rect.fromLTWH(20, size.height * 0.8, size.width * 0.45, size.height * 0.18),
      Rect.fromLTWH(size.width * 0.55, size.height * 0.8, size.width * 0.42, size.height * 0.18),
    ];
    for (final b in blocks) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(b, const Radius.circular(3)), blockPaint);
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
    for (final x in [
      size.width * 0.35,
      size.width * 0.68,
    ]) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }
    // Minor roads
    canvas.drawLine(
        Offset(0, size.height * 0.13),
        Offset(size.width, size.height * 0.13),
        minorRoadPaint);
    canvas.drawLine(
        Offset(size.width * 0.15, 0),
        Offset(size.width * 0.15, size.height),
        minorRoadPaint);
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) => false;
}
