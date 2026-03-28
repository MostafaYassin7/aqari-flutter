import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/account/presentation/providers/account_provider.dart';
import '../../../../features/home/data/mock_listings.dart';
import '../../../../shared/models/listing.dart';
import '../providers/public_profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  final String profileId;
  const ProfileScreen({required this.profileId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(publicProfileProvider(profileId));
    final currentUser = ref.watch(userProfileProvider);
    final isOwnProfile = currentUser?.id == profileId;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              size: 20,
              color: AppColors.textPrimaryLight,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: const Center(child: Text('الملف غير موجود')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.backgroundLight,
            elevation: 0,
            scrolledUnderElevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                size: 20,
                color: AppColors.textPrimaryLight,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Text(
              'الملف الشخصي',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
            ),
            centerTitle: true,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.dividerLight),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top section ────────────────────────────────
                _TopSection(profile: profile),

                const Divider(
                  height: 1,
                  color: AppColors.dividerLight,
                  indent: AppConstants.spaceM,
                  endIndent: AppConstants.spaceM,
                ),

                if (profile.totalListings > 0 ||
                    profile.totalDeals > 0 ||
                    profile.responseRate > 0) ...[
                  // ── Stats row ────────────────────────────────
                  _StatsRow(profile: profile),

                  const Divider(height: 8, color: AppColors.surfaceLight),
                ],

                // ── Active listings ────────────────────────────
                _ListingsSection(listingIds: profile.listingIds),

                if (profile.reviewCount > 0) ...[
                  const Divider(height: 8, color: AppColors.surfaceLight),

                  // ── Reviews ──────────────────────────────────
                  _ReviewsSection(profile: profile),
                ],

                // Bottom padding for contact bar
                SizedBox(
                  height: isOwnProfile
                      ? AppConstants.spaceXL
                      : 100 + MediaQuery.of(context).padding.bottom,
                ),
              ],
            ),
          ),
        ],
      ),
      // ── Contact buttons (other user's profile) ────────────────
      bottomNavigationBar: isOwnProfile ? null : _ContactBar(profile: profile),
    );
  }
}

// ── Top section ───────────────────────────────────────────────────────────────

class _TopSection extends StatefulWidget {
  final PublicProfile profile;
  const _TopSection({required this.profile});

  @override
  State<_TopSection> createState() => _TopSectionState();
}

class _TopSectionState extends State<_TopSection> {
  bool _bioExpanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final bioText = p.bio ?? '';
    final bioIsLong = bioText.length > 120;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceM,
        vertical: AppConstants.spaceL,
      ),
      child: Column(
        children: [
          // ── Avatar ───────────────────────────────────────────
          Center(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: p.photoUrl,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.primaryLight,
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 52,
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.primaryLight,
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 52,
                        ),
                      ),
                    ),
                  ),
                ),
                // Aqar+ badge on avatar
                if (p.hasAqarPlus)
                  Transform.translate(
                    offset: const Offset(0, 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusCircle,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'عقار+',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: p.hasAqarPlus ? 20 : 12),

          // ── Name + verified badge ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                p.name,
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              if (p.isVerified) ...[
                const SizedBox(width: 6),
                const _VerifiedBadge(),
              ],
            ],
          ),

          if (p.establishmentName != null) ...[
            const SizedBox(height: 4),
            Text(
              p.establishmentName!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],

          if (p.phone.isNotEmpty || (p.email?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                if (p.phone.isNotEmpty)
                  _MetaChip(icon: Icons.phone_outlined, label: p.phone),
                if (p.email != null && p.email!.isNotEmpty)
                  _MetaChip(icon: Icons.email_outlined, label: p.email!),
              ],
            ),
          ],

          // ── Rating ────────────────────────────────────────────
          if (p.reviewCount > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  p.rating.toStringAsFixed(1),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${p.reviewCount} تقييم)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
          ] else
            const SizedBox(height: 12),

          // ── Meta row: member since · last active ──────────────
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 4,
            children: [
              _MetaChip(
                icon: Icons.calendar_today_outlined,
                label: 'عضو منذ ${_formatYear(p.memberSince)}',
              ),
              _MetaChip(
                icon: Icons.access_time_rounded,
                label: 'آخر نشاط: ${_formatLastActive(p.lastActive)}',
              ),
              if (p.isBroker)
                _MetaChip(
                  icon: Icons.business_center_outlined,
                  label: 'وسيط معتمد',
                ),
            ],
          ),

          // ── Bio ───────────────────────────────────────────────
          if (bioText.isNotEmpty) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: bioIsLong
                  ? () => setState(() => _bioExpanded = !_bioExpanded)
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _bioExpanded || !bioIsLong
                        ? bioText
                        : '${bioText.substring(0, 120)}...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (bioIsLong) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        _bioExpanded ? 'أقل' : 'اقرأ المزيد',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatYear(DateTime dt) {
    const months = [
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
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _formatLastActive(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return 'منذ أكثر من أسبوع';
  }
}

// ── Verified badge ────────────────────────────────────────────────────────────

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 13, color: AppColors.info),
          const SizedBox(width: 3),
          Text(
            'موثّق',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.info,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Meta chip ─────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textHintLight),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final PublicProfile profile;
  const _StatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.spaceL,
        horizontal: AppConstants.spaceM,
      ),
      child: Row(
        children: [
          _StatCell(value: '${profile.totalListings}', label: 'إعلان نشط'),
          _StatDivider(),
          _StatCell(value: '${profile.totalDeals}', label: 'صفقة مُنجزة'),
          _StatDivider(),
          _StatCell(value: '${profile.responseRate}%', label: 'نسبة الرد'),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AppColors.dividerLight);
  }
}

// ── Active listings section ───────────────────────────────────────────────────

class _ListingsSection extends StatelessWidget {
  final List<String> listingIds;
  const _ListingsSection({required this.listingIds});

  @override
  Widget build(BuildContext context) {
    final listings = mockListings
        .where((l) => listingIds.contains(l.id))
        .toList();

    if (listings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.spaceM,
            AppConstants.spaceL,
            AppConstants.spaceM,
            AppConstants.spaceM,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'الإعلانات النشطة',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.search),
                child: Text(
                  'عرض الكل',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Horizontal scroll
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceM,
            ),
            itemCount: listings.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: _ProfileListingCard(listing: listings[i]),
            ),
          ),
        ),

        const SizedBox(height: AppConstants.spaceL),
      ],
    );
  }
}

class _ProfileListingCard extends StatelessWidget {
  final Listing listing;
  const _ProfileListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/property/${listing.id}'),
      child: SizedBox(
        width: 190,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              child: CachedNetworkImage(
                imageUrl: listing.imageUrls.first,
                width: 190,
                height: 140,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 190,
                  height: 140,
                  color: AppColors.surfaceLight,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 190,
                  height: 140,
                  color: AppColors.surfaceLight,
                  child: const Center(
                    child: Icon(
                      Icons.home_rounded,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              listing.title,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              _formatPrice(listing.price),
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${listing.city}  ·  ${listing.category}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      final m = price / 1000000;
      final s = m == m.truncateToDouble()
          ? m.toInt().toString()
          : m.toStringAsFixed(1);
      return '$s م ريال';
    }
    final f = price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$f ريال';
  }
}

// ── Reviews section ───────────────────────────────────────────────────────────

class _ReviewsSection extends StatelessWidget {
  final PublicProfile profile;
  const _ReviewsSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final reviews = profile.reviews;
    final shown = reviews.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppConstants.spaceL),

          // Section title
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                '${profile.rating.toStringAsFixed(1)}  ·  ${profile.reviewCount} تقييم',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spaceM),

          // ── Star breakdown bars ──────────────────────────
          _RatingBreakdown(
            breakdown: profile.ratingBreakdown,
            total: profile.reviewCount,
          ),

          const SizedBox(height: AppConstants.spaceL),
          const Divider(height: 1, color: AppColors.dividerLight),

          // ── Individual reviews ───────────────────────────
          ...shown.map((r) => _ReviewCard(review: r)),

          // Show all button
          if (reviews.length > 3) ...[
            const SizedBox(height: AppConstants.spaceS),
            Center(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.dividerLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                  minimumSize: const Size(220, 46),
                ),
                child: Text(
                  'عرض جميع التقييمات (${reviews.length})',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: AppConstants.spaceL),
        ],
      ),
    );
  }
}

// ── Rating breakdown bars ─────────────────────────────────────────────────────

class _RatingBreakdown extends StatelessWidget {
  final Map<int, int> breakdown;
  final int total;
  const _RatingBreakdown({required this.breakdown, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (i) {
        final star = 5 - i;
        final count = breakdown[star] ?? 0;
        final frac = total > 0 ? count / total : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text(
                '$star',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.star_rounded,
                size: 13,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, constraints) => Stack(
                    children: [
                      Container(
                        height: 6,
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                          color: AppColors.dividerLight,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusCircle,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        height: 6,
                        width: constraints.maxWidth * frac,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusCircle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 28,
                child: Text(
                  '$count',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Review card ───────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final UserReview review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer row
          Row(
            children: [
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: review.reviewerPhotoUrl,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 42,
                    height: 42,
                    color: AppColors.primaryLight,
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 42,
                    height: 42,
                    color: AppColors.primaryLight,
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    Row(
                      children: [
                        // Stars
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(review.date),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textHintLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.6,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Divider(height: 1, color: AppColors.dividerLight),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
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
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

// ── Contact bar ───────────────────────────────────────────────────────────────

class _ContactBar extends ConsumerWidget {
  final PublicProfile profile;
  const _ContactBar({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spaceM,
        AppConstants.spaceM,
        AppConstants.spaceM,
        AppConstants.spaceM + bottomPad,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(top: BorderSide(color: AppColors.dividerLight)),
      ),
      child: Row(
        children: [
          // Send message
          Expanded(
            flex: 3,
            child: SizedBox(
              height: AppConstants.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.chat),
                icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                label: Text(
                  'إرسال رسالة',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimaryLight,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Call button
          SizedBox(
            height: AppConstants.buttonHeight,
            width: AppConstants.buttonHeight,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('الاتصال بـ ${profile.phone}'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: const BorderSide(color: AppColors.dividerLight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
              ),
              child: const Icon(
                Icons.phone_rounded,
                color: AppColors.textPrimaryLight,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
