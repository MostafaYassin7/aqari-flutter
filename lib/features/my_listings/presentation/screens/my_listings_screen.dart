import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/listing.dart';
import '../providers/my_listings_provider.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myListingsProvider);
    final listings = state.filtered;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 20, color: AppColors.textPrimaryLight),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'إعلاناتي',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _FilterTabBar(current: state.filter),
        ),
      ),

      body: listings.isEmpty
          ? _EmptyState(filter: state.filter)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spaceM),
              itemCount: listings.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppConstants.spaceS),
              itemBuilder: (_, i) => _SwipeableListingCard(
                listing: listings[i],
                onDelete: () => ref
                    .read(myListingsProvider.notifier)
                    .deleteListing(listings[i].id),
                onTogglePause: () => ref
                    .read(myListingsProvider.notifier)
                    .togglePause(listings[i].id),
              ),
            ),

      // ── FAB ──────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addListing),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

// ── Filter tab bar ────────────────────────────────────────────────────────────

class _FilterTabBar extends ConsumerWidget {
  final ListingFilter current;
  const _FilterTabBar({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.backgroundLight,
      padding: const EdgeInsets.fromLTRB(
          AppConstants.spaceM, 0, AppConstants.spaceM, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ListingFilter.values.map((f) {
            final isSelected = f == current;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: GestureDetector(
                onTap: () => ref
                    .read(myListingsProvider.notifier)
                    .setFilter(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(
                        AppConstants.radiusCircle),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.dividerLight,
                    ),
                  ),
                  child: Text(
                    f.label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textPrimaryLight,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Swipeable card ────────────────────────────────────────────────────────────

class _SwipeableListingCard extends StatefulWidget {
  final MyListing listing;
  final VoidCallback onDelete;
  final VoidCallback onTogglePause;
  const _SwipeableListingCard({
    required this.listing,
    required this.onDelete,
    required this.onTogglePause,
  });

  @override
  State<_SwipeableListingCard> createState() =>
      _SwipeableListingCardState();
}

class _SwipeableListingCardState
    extends State<_SwipeableListingCard>
    with SingleTickerProviderStateMixin {
  static const double _actionWidth = 144.0;
  late final AnimationController _controller;
  late final Animation<double> _offsetAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _offsetAnim = Tween<double>(begin: 0, end: -_actionWidth)
        .animate(CurvedAnimation(
            parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _dragStart = 0;

  void _onDragStart(DragStartDetails d) => _dragStart = d.localPosition.dx;

  void _onDragEnd(DragEndDetails d) {
    final velocity = d.velocity.pixelsPerSecond.dx;
    final currentOffset = _offsetAnim.value;
    if (velocity < -300 || currentOffset < -_actionWidth / 2) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final delta = d.localPosition.dx - _dragStart;
    _dragStart = d.localPosition.dx;
    final target =
        (_controller.value + delta / -_actionWidth).clamp(0.0, 1.0);
    _controller.value = target;
  }

  void _close() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final isPaused = widget.listing.status != ListingStatus.published;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceM),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        child: Stack(
          children: [
            // ── Action buttons (behind card) ──────────────
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Pause / Resume
                  GestureDetector(
                    onTap: () {
                      _close();
                      widget.onTogglePause();
                    },
                    child: Container(
                      width: 72,
                      color: AppColors.warning,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            color: AppColors.white,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPaused ? 'تفعيل' : 'إيقاف',
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Delete
                  GestureDetector(
                    onTap: () {
                      _close();
                      _confirmDelete(context);
                    },
                    child: Container(
                      width: 72,
                      color: AppColors.error,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_rounded,
                              color: AppColors.white, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            'حذف',
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Card (slides over buttons) ────────────────
            AnimatedBuilder(
              animation: _offsetAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(_offsetAnim.value, 0),
                child: child,
              ),
              child: GestureDetector(
                onHorizontalDragStart: _onDragStart,
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                onTap: () {
                  if (_controller.value > 0) {
                    _close();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('تفاصيل: ${widget.listing.title}'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
                child: _ListingCardContent(listing: widget.listing),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL)),
        title: Text('حذف الإعلان',
            style: AppTextStyles.titleLarge
                .copyWith(fontWeight: FontWeight.w700)),
        content: Text(
            'هل تريد حذف "${widget.listing.title}"؟ لا يمكن التراجع.',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إلغاء',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondaryLight)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete();
            },
            child: Text('حذف',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Card content ──────────────────────────────────────────────────────────────

class _ListingCardContent extends StatelessWidget {
  final MyListing listing;
  const _ListingCardContent({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundLight,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thumbnail ────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            child: CachedNetworkImage(
              imageUrl: listing.imageUrl,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 90,
                height: 90,
                color: AppColors.surfaceLight,
                child: const Icon(Icons.home_rounded,
                    color: AppColors.textHintLight, size: 32),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 90,
                height: 90,
                color: AppColors.surfaceLight,
                child: const Icon(Icons.home_rounded,
                    color: AppColors.textHintLight, size: 32),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ── Info ─────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  listing.title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),

                // Address
                Text(
                  listing.address,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 6),

                // Stats
                Wrap(
                  spacing: 8,
                  children: [
                    _Stat('${listing.area} م²'),
                    if (listing.bedrooms > 0)
                      _Stat('${listing.bedrooms} غرف'),
                    if (listing.bathrooms > 0)
                      _Stat('${listing.bathrooms} حمام'),
                    if (listing.livingRooms > 0)
                      _Stat('${listing.livingRooms} صالة'),
                  ],
                ),
                const SizedBox(height: 6),

                // Price + badges row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatPrice(listing.price),
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    // Message requests badge
                    if (listing.messageRequests > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                              AppConstants.radiusCircle),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.message_rounded,
                                size: 10,
                                color: AppColors.white),
                            const SizedBox(width: 3),
                            Text(
                              '${listing.messageRequests}',
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    // Status badge
                    _StatusBadge(listing.status),
                  ],
                ),
              ],
            ),
          ),

          // Swipe hint arrow
          const Padding(
            padding: EdgeInsetsDirectional.only(start: 4, top: 36),
            child: Icon(Icons.chevron_left_rounded,
                size: 16, color: AppColors.textHintLight),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String text;
  const _Stat(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondaryLight),
      );
}

class _StatusBadge extends StatelessWidget {
  final ListingStatus status;
  const _StatusBadge(this.status);

  Color get _bg {
    switch (status) {
      case ListingStatus.published:
        return AppColors.success.withAlpha(25);
      case ListingStatus.pausedTemp:
        return AppColors.warning.withAlpha(25);
      case ListingStatus.paused:
        return AppColors.textHintLight.withAlpha(40);
      case ListingStatus.expired:
        return AppColors.error.withAlpha(25);
    }
  }

  Color get _fg {
    switch (status) {
      case ListingStatus.published:
        return AppColors.success;
      case ListingStatus.pausedTemp:
        return AppColors.warning;
      case ListingStatus.paused:
        return AppColors.textSecondaryLight;
      case ListingStatus.expired:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius:
              BorderRadius.circular(AppConstants.radiusCircle),
          border: Border.all(color: _fg.withAlpha(80)),
        ),
        child: Text(
          status.label,
          style: AppTextStyles.labelSmall
              .copyWith(color: _fg, fontWeight: FontWeight.w700),
        ),
      );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ListingFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final isFiltered = filter != ListingFilter.all;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 80,
              color: AppColors.dividerLight,
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'لا توجد إعلانات بهذه الحالة'
                  : 'لا توجد إعلانات بعد',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'جرّب تصفية أخرى للعثور على إعلاناتك'
                  : 'أضف إعلانك الأول وابدأ في الوصول إلى المشترين',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
            if (!isFiltered) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.addListing),
                icon: const Icon(Icons.add_rounded),
                label: const Text('أضف أول إعلان'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(200, AppConstants.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusM),
                  ),
                  elevation: 0,
                  textStyle: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
