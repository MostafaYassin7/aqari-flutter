import '../../../../core/preview/ui_preview.dart';
import '../../../../core/network/api_failure.dart';
import '../../../home/data/listings_repository.dart';
import '../../../event_halls/presentation/event_halls_ui.dart';
import '../../../property_details/presentation/screens/property_details_screen.dart';
import '../../../property_details/presentation/providers/property_details_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/home/data/mock_rentals.dart';
import '../../../../features/home/presentation/providers/rentals_provider.dart';
import '../../../../features/home/presentation/widgets/rental_calendar_modal.dart';
import '../../../../features/property_details/presentation/widgets/photo_gallery_viewer.dart';
import '../../../../shared/models/rental.dart';
import '../../data/mock_rental_extras.dart';
import '../../../bookings/presentation/booking_preview.dart';

class RentalDetailsScreen extends ConsumerWidget {
  final String rentalId;
  const RentalDetailsScreen({required this.rentalId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = uiPreview ? null : ref.watch(rentalDetailProvider(rentalId));
    if (live?.isLoading == true) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (live?.hasError == true) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: TextButton(
            onPressed: () => ref.invalidate(rentalDetailProvider(rentalId)),
            child: Text(
              '${ApiFailure.fromError(live!.error!).message} · إعادة المحاولة',
            ),
          ),
        ),
      );
    }
    final rental = uiPreview
        ? mockRentals.where((r) => r.id == rentalId).firstOrNull
        : live?.value;
    if (rental == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('الإعلان غير موجود')),
      );
    }
    if (!rental.rules.isDailyRental) {
      return rental.rules.isEventHall
          ? EventHallDetailsScreen(id: rental.id)
          : PropertyDetailsScreen(listingId: rental.id);
    }
    final owner = rental.source?.owner;
    final host = uiPreview
        ? getHostForRental(rental.id)
        : RentalHost(
            name: owner?.name ?? 'المعلن',
            photoUrl: owner?.profilePhoto ?? '',
            isVerified: false,
            responseRate: '',
            responseTime: '',
            memberSince: '',
            rating: 0,
            reviewCount: 0,
          );
    final amenities = uiPreview
        ? getAmenitiesForRental(rental)
        : [
            for (final f in getFeaturesFromListing(rental.source!))
              RentalAmenity(label: f.label, icon: f.icon),
          ];
    final isFav = ref.watch(favoritedRentalsProvider).contains(rental.id);

    return Scaffold(
      backgroundColor: context.appColors.background,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PhotoSection(rental: rental),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TitleSection(rental: rental),
                      _StatsRow(rental: rental),
                      const _Divider(),
                      _HostCard(host: host),
                      const _Divider(),
                      _DescriptionSection(rental: rental),
                      const _Divider(),
                      _AmenitiesGrid(amenities: amenities),
                      const _Divider(),
                      Text(
                        '${rental.maxGuests == null ? '' : 'حتى ${rental.maxGuests} ضيوف · '}الحد الأدنى ${rental.minNights} ليلة${rental.checkInTime.isEmpty ? '' : '\nالوصول ${rental.checkInTime}'}${rental.checkOutTime.isEmpty ? '' : '\nالمغادرة ${rental.checkOutTime}'}',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      _DateSection(rental: rental),
                      const _Divider(),
                      _LocationSection(rental: rental),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                _OtherUnitsSection(currentId: rental.id),
                const SizedBox(height: 100),
              ],
            ),
          ),
          _TopOverlayBar(rental: rental, isFav: isFav, ref: ref),
        ],
      ),
      bottomNavigationBar: _BottomBar(rental: rental),
    );
  }
}

// ── Photo section ─────────────────────────────────────────────────────────────

class _PhotoSection extends StatefulWidget {
  final DailyRental rental;
  const _PhotoSection({required this.rental});

  @override
  State<_PhotoSection> createState() => _PhotoSectionState();
}

class _PhotoSectionState extends State<_PhotoSection> {
  int _current = 0;
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.rental.imageUrls;
    return GestureDetector(
      onTap: () => showPhotoGallery(
        context: context,
        imageUrls: urls,
        initialIndex: _current,
      ),
      child: Stack(
        children: [
          SizedBox(
            height: 320,
            child: PageView.builder(
              controller: _controller,
              itemCount: urls.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: urls[i],
                width: double.infinity,
                height: 320,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: context.appColors.surface,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: context.appColors.surface,
                  child: const Center(
                    child: Icon(
                      Icons.home_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppColors.overlay, Colors.transparent],
                ),
              ),
            ),
          ),
          // Dot indicators
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                urls.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _current ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _current
                        ? AppColors.primary
                        : context.appColors.card.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top overlay bar ───────────────────────────────────────────────────────────

class _TopOverlayBar extends StatelessWidget {
  final DailyRental rental;
  final bool isFav;
  final WidgetRef ref;
  const _TopOverlayBar({
    required this.rental,
    required this.isFav,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _OBtn(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            _OBtn(
              icon: Icons.share_rounded,
              onTap: () => _snack(context, 'مشاركة الوحدة — قريباً'),
            ),
            const SizedBox(width: 8),
            _OBtn(
              icon: isFav
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              iconColor: isFav ? AppColors.error : null,
              onTap: () =>
                  ref.read(favoritedRentalsProvider.notifier).toggle(rental.id),
            ),
            const SizedBox(width: 8),
            _OBtn(
              icon: Icons.more_horiz_rounded,
              onTap: () => _showMoreSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.appColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            _SheetAction(
              icon: Icons.thumb_up_outlined,
              label: 'أعجبني',
              onTap: () {
                Navigator.pop(context);
                _snack(context, 'تم الإعجاب — قريباً');
              },
            ),
            _SheetAction(
              icon: Icons.visibility_off_outlined,
              label: 'إخفاء هذه الوحدة',
              onTap: () {
                Navigator.pop(context);
                _snack(context, 'تم الإخفاء — قريباً');
              },
            ),
            _SheetAction(
              icon: Icons.flag_outlined,
              label: 'الإبلاغ عن مشكلة',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                _snack(context, 'تم الإبلاغ — قريباً');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.appColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: c)),
      onTap: onTap,
    );
  }
}

class _OBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  const _OBtn({required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: context.appColors.card,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 18,
        color: iconColor ?? context.appColors.textPrimary,
      ),
    ),
  );
}

// ── Title section ─────────────────────────────────────────────────────────────

class _TitleSection extends StatelessWidget {
  final DailyRental rental;
  const _TitleSection({required this.rental});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rental.name,
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: context.appColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              '${rental.city}  ·  ${rental.district}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
            const Spacer(),
            const Icon(Icons.star_rounded, size: 14, color: AppColors.primary),
            const SizedBox(width: 3),
            Text(
              rental.rating.toStringAsFixed(1),
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '  (${rental.reviewCount})',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final DailyRental rental;
  const _StatsRow({required this.rental});

  @override
  Widget build(BuildContext context) {
    final stats = <Map<String, dynamic>>[
      if (rental.bedrooms > 0)
        {'v': '${rental.bedrooms}', 'l': 'غرف', 'i': Icons.bed_rounded},
      if (rental.bathrooms > 0)
        {'v': '${rental.bathrooms}', 'l': 'حمامات', 'i': Icons.shower_rounded},
      if (rental.livingRooms > 0)
        {
          'v': '${rental.livingRooms}',
          'l': 'مجالس',
          'i': Icons.weekend_rounded,
        },
      {'v': '${rental.area.toInt()}', 'l': 'م²', 'i': Icons.straighten_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: stats
            .map(
              (s) => Expanded(
                child: Column(
                  children: [
                    Icon(
                      s['i'] as IconData,
                      size: 22,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s['v'] as String,
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s['l'] as String,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Host card ─────────────────────────────────────────────────────────────────

class _HostCard extends StatelessWidget {
  final RentalHost host;
  const _HostCard({required this.host});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Stack(
            children: [
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: host.photoUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: context.appColors.primaryTint,
                    child: const Icon(
                      Icons.person_rounded,
                      size: 34,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              if (host.isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: AppColors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      host.name,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    if (host.isVerified) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.appColors.primaryTint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'موثق',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (host.memberSince.isNotEmpty || host.responseRate.isNotEmpty)
                  Text(
                    '${host.memberSince}  ·  نسبة الرد ${host.responseRate}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                if (host.responseTime.isNotEmpty)
                  Text(
                    'وقت الرد: ${host.responseTime}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Description ───────────────────────────────────────────────────────────────

class _DescriptionSection extends StatefulWidget {
  final DailyRental rental;
  const _DescriptionSection({required this.rental});

  @override
  State<_DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<_DescriptionSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'عن الوحدة',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Text(
              widget.rental.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.appColors.textSecondary,
                height: 1.7,
              ),
            ),
            secondChild: Text(
              widget.rental.description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.appColors.textSecondary,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _expanded ? 'عرض أقل' : 'اقرأ المزيد',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: context.appColors.textPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Amenities grid ────────────────────────────────────────────────────────────

class _AmenitiesGrid extends StatelessWidget {
  final List<RentalAmenity> amenities;
  const _AmenitiesGrid({required this.amenities});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المرافق والخدمات',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3.5,
            ),
            itemCount: amenities.length,
            itemBuilder: (_, i) => Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: context.appColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    amenities[i].icon,
                    size: 19,
                    color: context.appColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    amenities[i].label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.appColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date section ──────────────────────────────────────────────────────────────

class _DateSection extends ConsumerWidget {
  final DailyRental rental;
  const _DateSection({required this.rental});

  static const _months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  String _fmt(DateTime? d) =>
      d == null ? 'أضف تاريخ' : '${d.day} ${_months[d.month - 1]}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(bookingDatesProvider(rental.id));

    void openCalendar() => showRentalCalendar(
      loadMonth: rentalCalendarLoader(context, rental),
      blockedDates: uiPreview ? previewBlockedDates() : [],
      minNights: rental.minNights,
      context: context,
      checkIn: range.checkIn,
      checkOut: range.checkOut,
      onConfirm: (ci, co) =>
          ref.read(bookingDatesProvider(rental.id).notifier).setRange(ci, co),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'التوافر',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: openCalendar,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appColors.divider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _DateCell(
                      label: 'الوصول',
                      value: _fmt(range.checkIn),
                      isSet: range.checkIn != null,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(12),
                      ),
                      onTap: openCalendar,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: context.appColors.divider,
                  ),
                  Expanded(
                    child: _DateCell(
                      label: 'المغادرة',
                      value: _fmt(range.checkOut),
                      isSet: range.checkOut != null,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                      onTap: openCalendar,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateCell extends StatelessWidget {
  final String label, value;
  final bool isSet;
  final BorderRadius borderRadius;
  final VoidCallback onTap;
  const _DateCell({
    required this.label,
    required this.value,
    required this.isSet,
    required this.borderRadius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(borderRadius: borderRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(
              color: isSet
                  ? context.appColors.textPrimary
                  : context.appColors.textHint,
              fontWeight: isSet ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Location ──────────────────────────────────────────────────────────────────

class _LocationSection extends StatelessWidget {
  final DailyRental rental;
  const _LocationSection({required this.rental});

  @override
  Widget build(BuildContext context) {
    if (!uiPreview && rental.source?.hasCoordinates != true) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الموقع',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 160,
              color: const Color(0xFFD6EAD6),
              child: !uiPreview
                  ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(rental.source!.lat, rental.source!.lng),
                        zoom: 14,
                      ),
                      zoomControlsEnabled: false,
                      markers: {
                        Marker(
                          markerId: const MarkerId('rental'),
                          position: LatLng(
                            rental.source!.lat,
                            rental.source!.lng,
                          ),
                        ),
                      },
                    )
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(painter: _MapGrid()),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: context.appColors.card,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.appColors.shadow,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${rental.district}، ${rental.city}',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: context.appColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Icon(
                                Icons.location_on_rounded,
                                size: 32,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: !uiPreview
                ? () async {
                    final uri = Uri.https('www.google.com', '/maps/search/', {
                      'api': '1',
                      'query': '${rental.source!.lat},${rental.source!.lng}',
                    });
                    if (!await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        ) &&
                        context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تعذر فتح الخريطة')),
                      );
                    }
                  }
                : () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('فتح الخريطة — قريباً'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
            icon: const Icon(Icons.map_rounded, size: 16),
            label: const Text('فتح الخريطة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.appColors.textPrimary,
              side: BorderSide(color: context.appColors.divider),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGrid extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC0DCC0)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final road = Paint()
      ..color = AppColors.white.withValues(alpha: 0.7)
      ..strokeWidth = 8;
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height),
      road,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Other units horizontal scroll ─────────────────────────────────────────────

class _OtherUnitsSection extends ConsumerWidget {
  final String currentId;
  const _OtherUnitsSection({required this.currentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final others =
        (uiPreview ? mockRentals : ref.watch(filteredRentalsProvider))
            .where((r) => r.id != currentId)
            .take(5)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            'وحدات أخرى قد تعجبك',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: others.length,
            itemBuilder: (_, i) => _SmallRentalCard(rental: others[i]),
          ),
        ),
      ],
    );
  }
}

class _SmallRentalCard extends StatelessWidget {
  final DailyRental rental;
  const _SmallRentalCard({required this.rental});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/rental/${rental.id}'),
      child: Container(
        width: 165,
        margin: const EdgeInsetsDirectional.only(end: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: rental.imageUrls.first,
                width: 165,
                height: 130,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: context.appColors.surface,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: context.appColors.surface,
                  child: const Icon(
                    Icons.home_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${rental.city}  ·  ${rental.district}',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              rental.name,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 12,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 3),
                Text(
                  rental.rating.toStringAsFixed(1),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${rental.pricePerNight.toInt()} ريال',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                ),
                Text(
                  ' /ليلة',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends ConsumerWidget {
  final DailyRental rental;
  const _BottomBar({required this.rental});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(bookingDatesProvider(rental.id));
    final nights = range.nights;
    final total = rental.pricePerNight * (nights > 0 ? nights : 1);

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.card,
        border: Border(top: BorderSide(color: context.appColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Price info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${rental.pricePerNight.toInt()} ريال',
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: ' / ليلة',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (nights > 0)
                      Text(
                        'الإجمالي: ${total.toInt()} ريال ($nights ليالٍ)',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.appColors.textSecondary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                  ],
                ),
              ),

              // Reserve button
              ElevatedButton(
                onPressed: () => openBookingPreview(context, rental),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: Size.zero, // override theme's full-width default
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'احجز الآن',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Divider ───────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 20),
    child: Divider(height: 1, color: context.appColors.divider),
  );
}

final rentalDetailProvider = FutureProvider.family<DailyRental, String>(
  (ref, id) async =>
      DailyRental.fromListing(await ListingsRepository().getListingById(id)),
);
