import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/listing.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../data/mock_property_extras.dart';
import '../providers/property_details_provider.dart';
import '../widgets/photo_gallery_viewer.dart';

class PropertyDetailsScreen extends ConsumerStatefulWidget {
  final String listingId;

  const PropertyDetailsScreen({required this.listingId, super.key});

  @override
  ConsumerState<PropertyDetailsScreen> createState() =>
      _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends ConsumerState<PropertyDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(propertyDetailsProvider.notifier).load(widget.listingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetails = ref.watch(propertyDetailsProvider);

    return asyncDetails.when(
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
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
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
                    .read(propertyDetailsProvider.notifier)
                    .load(widget.listingId),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
      data: (details) {
        final listing = details.listing;
        final isFav = details.isFavorited;
        final owner = getOwnerForListing(listing.id);
        final features = getFeaturesFromListing(listing);

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PhotoSection(listing: listing),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TitleSection(listing: listing),
                          const _Divider(),
                          _StatsRow(listing: listing),
                          const _Divider(),
                          _OwnerCard(owner: owner),
                          const _Divider(),
                          _DescriptionSection(listing: listing),
                          if (features.isNotEmpty) ...[
                            const _Divider(),
                            _FeaturesGrid(features: features),
                          ],
                          const _Divider(),
                          _LocationSection(listing: listing),
                          const _Divider(),
                          _PriceSection(listing: listing),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _TopOverlayBar(isFav: isFav, ref: ref),
            ],
          ),
          bottomNavigationBar: _BottomBar(listing: listing),
        );
      },
    );
  }
}

// ── Photo section ─────────────────────────────────────────────────────────────

class _PhotoSection extends StatefulWidget {
  final Listing listing;
  const _PhotoSection({required this.listing});

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
    final urls = widget.listing.imageUrls;

    return GestureDetector(
      onTap: () => showPhotoGallery(
        context: context,
        imageUrls: urls,
        initialIndex: _current,
      ),
      child: Stack(
        children: [
          // Image PageView
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
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.surfaceLight,
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

          // Photo counter badge
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.overlay,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library_rounded,
                      size: 13,
                      color: AppColors.white,
                    ),
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
  final bool isFav;
  final WidgetRef ref;

  const _TopOverlayBar({required this.isFav, required this.ref});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Back
            _OverlayIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),

            const Spacer(),

            // Share
            _OverlayIconButton(
              icon: Icons.share_rounded,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('مشاركة العقار — قريباً'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),

            // Favorite
            _OverlayIconButton(
              icon: isFav
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              iconColor: isFav ? AppColors.error : null,
              onTap: () =>
                  ref.read(propertyDetailsProvider.notifier).toggleFavorite(),
            ),
            const SizedBox(width: 8),

            // Report (via "...")
            _OverlayIconButton(
              icon: Icons.more_horiz_rounded,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الإبلاغ عن العقار — قريباً'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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
  final Color? iconColor;

  const _OverlayIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

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
        child: Icon(
          icon,
          size: 18,
          color: iconColor ?? AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}

// ── Title section ─────────────────────────────────────────────────────────────

class _TitleSection extends StatelessWidget {
  final Listing listing;
  const _TitleSection({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          listing.title,
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${listing.city}  ·  ${listing.district}  ·  ${listing.category}',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Listing listing;
  const _StatsRow({required this.listing});

  @override
  Widget build(BuildContext context) {
    final stats = <Map<String, dynamic>>[
      if (listing.bedrooms > 0)
        {
          'value': '${listing.bedrooms}',
          'label': 'غرف نوم',
          'icon': Icons.bed_rounded,
        },
      if (listing.bathrooms > 0)
        {
          'value': '${listing.bathrooms}',
          'label': 'حمامات',
          'icon': Icons.shower_rounded,
        },
      if (listing.livingRooms > 0)
        {
          'value': '${listing.livingRooms}',
          'label': 'مجالس',
          'icon': Icons.weekend_rounded,
        },
      {
        'value': '${listing.area}',
        'label': 'م²',
        'icon': Icons.straighten_rounded,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Column(
              children: [
                Icon(s['icon'] as IconData, size: 22, color: AppColors.primary),
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

// ── Owner card ────────────────────────────────────────────────────────────────

class _OwnerCard extends StatelessWidget {
  final PropertyOwner owner;
  const _OwnerCard({required this.owner});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Avatar
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: owner.photoUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: AppColors.primaryLight,
                child: const Icon(
                  Icons.person_rounded,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      owner.name,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        owner.type,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      owner.rating.toStringAsFixed(1),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '  ·  ${owner.reviewCount} تقييم  ·  ${owner.lastActive}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Description section ───────────────────────────────────────────────────────

class _DescriptionSection extends StatefulWidget {
  final Listing listing;
  const _DescriptionSection({required this.listing});

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
            'عن العقار',
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
              widget.listing.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
                height: 1.7,
              ),
            ),
            secondChild: Text(
              widget.listing.description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
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
      ),
    );
  }
}

// ── Features grid ─────────────────────────────────────────────────────────────

class _FeaturesGrid extends StatelessWidget {
  final List<ListingFeature> features;
  const _FeaturesGrid({required this.features});

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
              color: AppColors.textPrimaryLight,
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
            itemCount: features.length,
            itemBuilder: (_, i) => _FeatureTile(feature: features[i]),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final ListingFeature feature;
  const _FeatureTile({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            feature.icon,
            size: 20,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            feature.label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Location section ──────────────────────────────────────────────────────────

class _LocationSection extends StatelessWidget {
  final Listing listing;
  const _LocationSection({required this.listing});

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
          // Map placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 180,
              color: const Color(0xFFD6EAD6),
              child: Stack(
                children: [
                  // Simulated map grid
                  Positioned.fill(
                    child: CustomPaint(painter: _MapGridPainter()),
                  ),
                  // Location pin
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
                            '${listing.district}، ${listing.city}',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(
                          Icons.location_on_rounded,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('فتح الخريطة — قريباً'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.map_rounded, size: 18),
            label: const Text('فتح الخريطة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimaryLight,
              side: const BorderSide(color: AppColors.dividerLight),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

// Minimal map-grid painter for the location placeholder
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
    // A few "road" lines
    final roadPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.7)
      ..strokeWidth = 8;
    canvas.drawLine(
      Offset(0, size.height * 0.45),
      Offset(size.width, size.height * 0.45),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.55, 0),
      Offset(size.width * 0.55, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Price section ─────────────────────────────────────────────────────────────

class _PriceSection extends StatelessWidget {
  final Listing listing;
  const _PriceSection({required this.listing});

  @override
  Widget build(BuildContext context) {
    final pricePerSqm = listing.area > 0
        ? (listing.price / listing.area).round()
        : 0;

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
          Text(
            formatPrice(listing.price),
            style: AppTextStyles.headlineLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryLight,
            ),
          ),
          if (pricePerSqm > 0) ...[
            const SizedBox(height: 4),
            Text(
              'السعر / م²  ≈  ${_fmtNum(pricePerSqm)} ريال',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtNum(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends ConsumerWidget {
  final Listing listing;
  const _BottomBar({required this.listing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              // Price info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'السعر الإجمالي',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatPrice(listing.price),
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Chat (outlined)
              _BarButton(
                label: 'تواصل',
                icon: Icons.chat_bubble_outline_rounded,
                outlined: true,
                onTap: () async {
                  if (listing.userId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('لا يمكن التواصل مع هذا المُعلن'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  final chatId = await ref
                      .read(chatsProvider.notifier)
                      .findOrCreateChat(
                        participantId: listing.userId,
                        listingId: listing.id,
                      );
                  if (chatId != null && context.mounted) {
                    context.push('/chat/$chatId');
                  }
                },
              ),
              const SizedBox(width: 8),

              // WhatsApp (green)
              _BarButton(
                label: 'واتساب',
                icon: Icons.message_rounded,
                color: const Color(0xFF25D366),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('فتح واتساب — قريباً'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Call (primary)
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
          border: outlined ? Border.all(color: AppColors.dividerLight) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: outlined ? AppColors.textPrimaryLight : AppColors.white,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: outlined ? AppColors.textPrimaryLight : AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable divider ──────────────────────────────────────────────────────────

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
