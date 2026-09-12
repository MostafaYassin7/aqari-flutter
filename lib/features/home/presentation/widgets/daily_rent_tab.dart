import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/network/api_failure.dart';
import '../providers/rentals_provider.dart';
import 'category_chips_row.dart';
import 'country_chips_row.dart';
import 'rental_calendar_modal.dart';
import 'rental_card.dart';

// ── Entry point for the tab ───────────────────────────────────────────────────

class DailyRentTab extends ConsumerWidget {
  const DailyRentTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rentals = ref.watch(filteredRentalsProvider);
    final rentalState = ref.watch(rentalsNotifierProvider);
    final isLoading = rentalState.isLoading;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          ref.read(rentalsNotifierProvider.notifier).loadMore().catchError((
            Object error,
          ) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ApiFailure.fromError(error).message)),
              );
            }
          });
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          try {
            await ref.read(rentalsNotifierProvider.notifier).refresh();
          } catch (_) {
            // The provider retains the error for the retry state below.
          }
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Date picker bar
            const SliverToBoxAdapter(child: _DateBar()),

            // Guest count selector
            const SliverToBoxAdapter(child: _GuestSelector()),

            // Country filter
            SliverToBoxAdapter(
              child: CountryChipsRow(cityProvider: selectedRentalCityProvider),
            ),

            // Property type filter
            SliverToBoxAdapter(
              child: CategoryChipsRow(
                propertyTypeProvider: selectedRentalPropertyTypeProvider,
              ),
            ),

            SliverToBoxAdapter(
              child: Divider(
                height: 1,
                thickness: 1,
                color: context.appColors.divider,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Loading state
            if (isLoading && rentals.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (rentalState.hasError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ApiFailure.fromError(rentalState.error!).message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(rentalsNotifierProvider),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              )
            else if (rentals.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.home_work_outlined,
                        size: 64,
                        color: context.appColors.icon,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد وحدات في هذه الفئة',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => RentalCard(rental: rentals[i]),
                  childCount: rentals.length,
                ),
              ),

            if (isLoading && rentals.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
}

// ── Date picker bar ───────────────────────────────────────────────────────────

class _DateBar extends ConsumerWidget {
  const _DateBar();

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
    final range = ref.watch(rentalDateRangeProvider);

    void openCalendar() {
      showRentalCalendar(
        context: context,
        checkIn: range.checkIn,
        checkOut: range.checkOut,
        onConfirm: (ci, co) =>
            ref.read(rentalDateRangeProvider.notifier).setRange(ci, co),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: openCalendar,
        child: Container(
          decoration: BoxDecoration(
            color: context.appColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appColors.divider),
            boxShadow: [
              BoxShadow(
                color: context.appColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Check-in
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

              // Divider
              Container(width: 1, height: 44, color: context.appColors.divider),

              // Check-out
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
    );
  }
}

class _DateCell extends StatelessWidget {
  final String label;
  final String value;
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
  Widget build(BuildContext context) {
    return GestureDetector(
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
}

// ── Guest count selector ──────────────────────────────────────────────────────

class _GuestSelector extends ConsumerWidget {
  const _GuestSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(rentalGuestCountProvider);
    final notifier = ref.read(rentalGuestCountProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Icon(
            Icons.person_outline_rounded,
            size: 20,
            color: context.appColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            'الضيوف',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const Spacer(),
          // Decrement
          _CounterButton(
            icon: Icons.remove_rounded,
            onTap: notifier.decrement,
            enabled: count > 1,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$count ضيف',
              style: AppTextStyles.titleSmall.copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Increment
          _CounterButton(
            icon: Icons.add_rounded,
            onTap: notifier.increment,
            enabled: true,
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _CounterButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? context.appColors.textSecondary
                : context.appColors.divider,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? context.appColors.textPrimary
              : context.appColors.divider,
        ),
      ),
    );
  }
}

// ── Category chips ────────────────────────────────────────────────────────────
// Removed: _RentalCategoryChips — now using shared CategoryChipsRow widget
