import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/listing.dart' show formatPrice;
import '../../../../shared/models/project.dart';
import '../../../property_details/presentation/widgets/photo_gallery_viewer.dart';
import '../providers/project_details_provider.dart';

class ProjectDetailsScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailsScreen({required this.projectId, super.key});

  @override
  ConsumerState<ProjectDetailsScreen> createState() =>
      _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends ConsumerState<ProjectDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(projectDetailsProvider.notifier).load(widget.projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncProject = ref.watch(projectDetailsProvider);

    return asyncProject.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'حدث خطأ أثناء تحميل البيانات',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(projectDetailsProvider.notifier)
                    .load(widget.projectId),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
      data: (project) {
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PhotoSection(project: project),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TitleSection(project: project),
                          const _Divider(),
                          _StatsRow(project: project),
                          const _Divider(),
                          _DescriptionSection(project: project),
                          if (project.units.isNotEmpty) ...[
                            const _Divider(),
                            _UnitsSection(units: project.units),
                          ],
                          const _Divider(),
                          _LocationSection(project: project),
                          const _Divider(),
                          _PriceSection(project: project),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _TopOverlayBar(),
            ],
          ),
          bottomNavigationBar: _BottomBar(project: project),
        );
      },
    );
  }
}

// ── Photo section ─────────────────────────────────────────────────────────────

class _PhotoSection extends StatefulWidget {
  final Project project;
  const _PhotoSection({required this.project});

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
    final urls = widget.project.imageUrls;

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
                  color: AppColors.surfaceLight,
                  child: const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.surfaceLight,
                  child: const Center(
                    child: Icon(Icons.apartment_rounded,
                        size: 64, color: AppColors.primary),
                  ),
                ),
              ),
            ),
          ),

          // Bottom gradient
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

          // Photo counter
          if (urls.length > 1)
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.overlay,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_rounded,
                          size: 13, color: AppColors.white),
                      const SizedBox(width: 5),
                      Text(
                        '${_current + 1} / ${urls.length}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _OverlayIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            _OverlayIconButton(
              icon: Icons.share_rounded,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('مشاركة المشروع — قريباً'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _OverlayIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimaryLight),
      ),
    );
  }
}

// ── Title section ─────────────────────────────────────────────────────────────

class _TitleSection extends StatelessWidget {
  final Project project;
  const _TitleSection({required this.project});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Availability badge
        _AvailabilityBadge(availability: project.availability),
        const SizedBox(height: 12),
        Text(
          project.name,
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          [
            if (project.district.isNotEmpty) project.district,
            project.city,
          ].join('، '),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        if (project.developerName.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.business_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                project.developerName,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final ProjectAvailability availability;
  const _AvailabilityBadge({required this.availability});

  @override
  Widget build(BuildContext context) {
    final isReady = availability == ProjectAvailability.ready;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isReady ? AppColors.success : AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        availability.label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Project project;
  const _StatsRow({required this.project});

  @override
  Widget build(BuildContext context) {
    final stats = <Map<String, dynamic>>[
      if (project.totalUnits > 0)
        {
          'value': '${project.totalUnits}',
          'label': 'وحدة',
          'icon': Icons.grid_view_rounded,
        },
      if (project.units.isNotEmpty)
        {
          'value': '${project.units.length}',
          'label': 'نوع وحدة',
          'icon': Icons.category_rounded,
        },
      {
        'value': project.availability.label,
        'label': 'الحالة',
        'icon': Icons.check_circle_rounded,
      },
    ];

    if (stats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Column(
              children: [
                Icon(s['icon'] as IconData,
                    size: 22, color: AppColors.primary),
                const SizedBox(height: 6),
                Text(
                  s['value'] as String,
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s['label'] as String,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Description section ───────────────────────────────────────────────────────

class _DescriptionSection extends StatefulWidget {
  final Project project;
  const _DescriptionSection({required this.project});

  @override
  State<_DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<_DescriptionSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.project.description.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'عن المشروع',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Text(
              widget.project.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
                height: 1.7,
              ),
            ),
            secondChild: Text(
              widget.project.description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
                height: 1.7,
              ),
            ),
          ),
          if (widget.project.description.length > 100) ...[
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
                      decoration: TextDecoration.underline,
                    ),
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
        ],
      ),
    );
  }
}

// ── Units section ─────────────────────────────────────────────────────────────

const _unitTypeLabels = <String, String>{
  'studio': 'استوديو',
  '1br': 'غرفة نوم واحدة',
  '2br': 'غرفتين نوم',
  '3br': '3 غرف نوم',
  '4br': '4 غرف نوم',
  'villa': 'فيلا',
  'commercial': 'تجاري',
};

const _availabilityLabels = <String, String>{
  'available': 'متاح',
  'sold': 'مباع',
  'reserved': 'محجوز',
};

class _UnitsSection extends StatelessWidget {
  final List<ProjectUnit> units;
  const _UnitsSection({required this.units});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الوحدات المتاحة',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          ...units.map((unit) => _UnitCard(unit: unit)),
        ],
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  final ProjectUnit unit;
  const _UnitCard({required this.unit});

  @override
  Widget build(BuildContext context) {
    final typeLabel =
        _unitTypeLabels[unit.unitType] ?? unit.unitType;
    final availLabel =
        _availabilityLabels[unit.availability] ?? unit.availability;
    final isAvailable = unit.availability == 'available';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  typeLabel,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  availLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isAvailable
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _UnitStat(
                icon: Icons.straighten_rounded,
                label: '${unit.area.toInt()} م²',
              ),
              const SizedBox(width: 24),
              if (unit.floor > 0)
                _UnitStat(
                  icon: Icons.layers_rounded,
                  label: 'الدور ${unit.floor}',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${unit.displayPrice} ريال',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _UnitStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondaryLight),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

// ── Location section ──────────────────────────────────────────────────────────

class _LocationSection extends StatelessWidget {
  final Project project;
  const _LocationSection({required this.project});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الموقع',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 180,
              color: const Color(0xFFD6EAD6),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _MapGridPainter()),
                  ),
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
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            [
                              if (project.district.isNotEmpty) project.district,
                              project.city,
                            ].join('، '),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.location_on_rounded,
                            size: 36, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (project.address.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    project.address,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC0DCC0)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final roadPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.7)
      ..strokeWidth = 8;
    canvas.drawLine(Offset(0, size.height * 0.45),
        Offset(size.width, size.height * 0.45), roadPaint);
    canvas.drawLine(Offset(size.width * 0.55, 0),
        Offset(size.width * 0.55, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Price section ─────────────────────────────────────────────────────────────

class _PriceSection extends StatelessWidget {
  final Project project;
  const _PriceSection({required this.project});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'السعر',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'يبدأ من  ',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                TextSpan(
                  text: formatPrice(project.startingPrice),
                  style: AppTextStyles.headlineLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (project.priceTo != null && project.priceTo! > 0) ...[
            const SizedBox(height: 4),
            Text(
              'حتى  ${formatPrice(project.priceTo!)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final Project project;
  const _BottomBar({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.dividerLight)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'يبدأ من',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatPrice(project.startingPrice),
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              _BarButton(
                label: 'تواصل',
                icon: Icons.chat_bubble_outline_rounded,
                outlined: true,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('المحادثة — قريباً'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _BarButton(
                label: 'اتصال',
                icon: Icons.phone_rounded,
                color: AppColors.primary,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الاتصال — قريباً'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
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

class _BarButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final bool outlined;
  final VoidCallback onTap;

  const _BarButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: outlined ? AppColors.white : (color ?? AppColors.primary),
          borderRadius: BorderRadius.circular(10),
          border: outlined
              ? Border.all(color: AppColors.dividerLight)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: outlined
                    ? AppColors.textPrimaryLight
                    : AppColors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: outlined
                    ? AppColors.textPrimaryLight
                    : AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Divider ───────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Divider(height: 1, color: AppColors.dividerLight),
    );
  }
}
