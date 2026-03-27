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

class RentalDetailsScreen extends ConsumerWidget {
  final String rentalId;
  const RentalDetailsScreen({required this.rentalId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rental = mockRentals.firstWhere(
      (r) => r.id == rentalId,
      orElse: () => mockRentals.first,
    );
    final host = getHostForRental(rental.id);
    final amenities = getAmenitiesForRental(rental);
    final isFav = ref.watch(favoritedRentalsProvider).contains(rental.id);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
          context: context, imageUrls: urls, initialIndex: _current),
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
                  color: AppColors.surfaceLight,
                  child: const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.surfaceLight,
                  child: const Center(
                      child: Icon(Icons.home_rounded,
                          size: 64, color: AppColors.primary)),
                ),
              ),
            ),
          ),
          // Gradient
          Positioned(
            bottom: 0, left: 0, right: 0,
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
            bottom: 14, left: 0, right: 0,
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
                        : AppColors.white.withValues(alpha: 0.7),
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
  const _TopOverlayBar(
      {required this.rental, required this.isFav, required this.ref});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _OBtn(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop()),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.dividerLight,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            _SheetAction(
                icon: Icons.thumb_up_outlined,
                label: 'أعجبني',
                onTap: () {
                  Navigator.pop(context);
                  _snack(context, 'تم الإعجاب — قريباً');
                }),
            _SheetAction(
                icon: Icons.visibility_off_outlined,
                label: 'إخفاء هذه الوحدة',
                onTap: () {
                  Navigator.pop(context);
                  _snack(context, 'تم الإخفاء — قريباً');
                }),
            _SheetAction(
                icon: Icons.flag_outlined,
                label: 'الإبلاغ عن مشكلة',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  _snack(context, 'تم الإبلاغ — قريباً');
                }),
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
  const _SheetAction(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimaryLight;
    return ListTile(
      leading: Icon(icon, color: c),
      title:
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: c)),
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
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppColors.shadowLight, blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Icon(icon,
              size: 18,
              color: iconColor ?? AppColors.textPrimaryLight),
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
              color: AppColors.textPrimaryLight),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              '${rental.city}  ·  ${rental.district}',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondaryLight),
            ),
            const Spacer(),
            const Icon(Icons.star_rounded,
                size: 14, color: AppColors.primary),
            const SizedBox(width: 3),
            Text(
              rental.rating.toStringAsFixed(1),
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700),
            ),
            Text(
              '  (${rental.reviewCount})',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondaryLight),
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
        {'v': '${rental.livingRooms}', 'l': 'مجالس', 'i': Icons.weekend_rounded},
      {'v': '${rental.area.toInt()}', 'l': 'م²', 'i': Icons.straighten_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: stats.map((s) => Expanded(
          child: Column(
            children: [
              Icon(s['i'] as IconData, size: 22, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(s['v'] as String,
                  style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryLight)),
              const SizedBox(height: 2),
              Text(s['l'] as String,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textSecondaryLight)),
            ],
          ),
        )).toList(),
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
                    color: AppColors.primaryLight,
                    child: const Icon(Icons.person_rounded,
                        size: 34, color: AppColors.primary),
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
                        color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded,
                        size: 13, color: AppColors.white),
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
                          color: AppColors.textPrimaryLight),
                    ),
                    if (host.isVerified) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('موثق',
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${host.memberSince}  ·  نسبة الرد ${host.responseRate}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondaryLight),
                ),
                Text(
                  'وقت الرد: ${host.responseTime}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondaryLight),
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
          Text('عن الوحدة',
              style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight)),
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
                  color: AppColors.textSecondaryLight, height: 1.7),
            ),
            secondChild: Text(
              widget.rental.description,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight, height: 1.7),
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
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.textPrimaryLight,
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
          Text('المرافق والخدمات',
              style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
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
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(amenities[i].icon,
                      size: 19, color: AppColors.textPrimaryLight),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    amenities[i].label,
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimaryLight),
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
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  String _fmt(DateTime? d) =>
      d == null ? 'أضف تاريخ' : '${d.day} ${_months[d.month - 1]}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(rentalDateRangeProvider);

    void openCalendar() => showRentalCalendar(
          context: context,
          checkIn: range.checkIn,
          checkOut: range.checkOut,
          onConfirm: (ci, co) =>
              ref.read(rentalDateRangeProvider.notifier).setRange(ci, co),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('التوافر',
              style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: openCalendar,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.dividerLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _DateCell(
                      label: 'الوصول',
                      value: _fmt(range.checkIn),
                      isSet: range.checkIn != null,
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(12)),
                      onTap: openCalendar,
                    ),
                  ),
                  Container(
                      width: 1, height: 44, color: AppColors.dividerLight),
                  Expanded(
                    child: _DateCell(
                      label: 'المغادرة',
                      value: _fmt(range.checkOut),
                      isSet: range.checkOut != null,
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12)),
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
  const _DateCell(
      {required this.label,
      required this.value,
      required this.isSet,
      required this.borderRadius,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(borderRadius: borderRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value,
                  style: AppTextStyles.titleSmall.copyWith(
                      color: isSet
                          ? AppColors.textPrimaryLight
                          : AppColors.textHintLight,
                      fontWeight: isSet
                          ? FontWeight.w700
                          : FontWeight.w400)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الموقع',
              style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 160,
              color: const Color(0xFFD6EAD6),
              child: Stack(
                children: [
                  Positioned.fill(
                      child: CustomPaint(painter: _MapGrid())),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.shadowLight,
                                  blurRadius: 8)
                            ],
                          ),
                          child: Text(
                            '${rental.district}، ${rental.city}',
                            style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.location_on_rounded,
                            size: 32, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('فتح الخريطة — قريباً'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating)),
            icon: const Icon(Icons.map_rounded, size: 16),
            label: const Text('فتح الخريطة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimaryLight,
              side: const BorderSide(color: AppColors.dividerLight),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
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
    canvas.drawLine(Offset(0, size.height * 0.5),
        Offset(size.width, size.height * 0.5), road);
    canvas.drawLine(Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height), road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Other units horizontal scroll ─────────────────────────────────────────────

class _OtherUnitsSection extends StatelessWidget {
  final String currentId;
  const _OtherUnitsSection({required this.currentId});

  @override
  Widget build(BuildContext context) {
    final others =
        mockRentals.where((r) => r.id != currentId).take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            'وحدات أخرى قد تعجبك',
            style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight),
          ),
        ),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: others.length,
            itemBuilder: (_, i) =>
                _SmallRentalCard(rental: others[i]),
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
                    color: AppColors.surfaceLight,
                    child: const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary))),
                errorWidget: (_, __, ___) => Container(
                    color: AppColors.surfaceLight,
                    child: const Icon(Icons.home_rounded,
                        size: 40, color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${rental.city}  ·  ${rental.district}',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 3),
            Text(
              rental.name,
              style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    size: 12, color: AppColors.primary),
                const SizedBox(width: 3),
                Text(
                  rental.rating.toStringAsFixed(1),
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${rental.pricePerNight.toInt()} ريال',
                  style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight),
                ),
                Text(' /ليلة',
                    style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondaryLight)),
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
    final range = ref.watch(rentalDateRangeProvider);
    final nights = range.nights;
    final total = rental.pricePerNight * (nights > 0 ? nights : 1);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.dividerLight)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                            text:
                                '${rental.pricePerNight.toInt()} ريال',
                            style: AppTextStyles.titleLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryLight),
                          ),
                          TextSpan(
                            text: ' / ليلة',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                    if (nights > 0)
                      Text(
                        'الإجمالي: ${total.toInt()} ريال ($nights ليالٍ)',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                            decoration: TextDecoration.underline),
                      ),
                  ],
                ),
              ),

              // Reserve button
              ElevatedButton(
                onPressed: () =>
                    ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الحجز — قريباً'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: Size.zero, // override theme's full-width default
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'احجز الآن',
                  style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.white),
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
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Divider(height: 1, color: AppColors.dividerLight),
      );
}
