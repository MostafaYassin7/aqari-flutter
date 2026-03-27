import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

// ── Public entry-point ────────────────────────────────────────────────────────

void showRentalCalendar({
  required BuildContext context,
  required DateTime? checkIn,
  required DateTime? checkOut,
  required void Function(DateTime checkIn, DateTime checkOut) onConfirm,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RentalCalendarModal(
      initialCheckIn: checkIn,
      initialCheckOut: checkOut,
      onConfirm: onConfirm,
    ),
  );
}

// ── Modal shell ───────────────────────────────────────────────────────────────

class _RentalCalendarModal extends StatefulWidget {
  final DateTime? initialCheckIn;
  final DateTime? initialCheckOut;
  final void Function(DateTime, DateTime) onConfirm;

  const _RentalCalendarModal({
    this.initialCheckIn,
    this.initialCheckOut,
    required this.onConfirm,
  });

  @override
  State<_RentalCalendarModal> createState() => _RentalCalendarModalState();
}

class _RentalCalendarModalState extends State<_RentalCalendarModal> {
  late DateTime _viewMonth;
  DateTime? _checkIn;
  DateTime? _checkOut;

  static const _monthNames = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  // Sun-first abbreviated day labels
  static const _dayLabels = [
    'أحد', 'اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewMonth = DateTime(now.year, now.month);
    _checkIn = widget.initialCheckIn;
    _checkOut = widget.initialCheckOut;
  }

  // ── Helpers ─────────────────────────────────────────────

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isPast(DateTime day) {
    final today = DateTime.now();
    return day
        .isBefore(DateTime(today.year, today.month, today.day));
  }

  void _onDayTap(DateTime day) {
    if (_isPast(day)) return;
    setState(() {
      if (_checkIn == null || (_checkIn != null && _checkOut != null)) {
        _checkIn = day;
        _checkOut = null;
      } else {
        if (day.isAfter(_checkIn!)) {
          _checkOut = day;
        } else if (day.isBefore(_checkIn!)) {
          _checkOut = _checkIn;
          _checkIn = day;
        } else {
          _checkIn = day;
          _checkOut = null;
        }
      }
    });
  }

  void _prevMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
    });
  }

  bool get _canConfirm => _checkIn != null && _checkOut != null;

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.87,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.dividerLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'اختر تواريخ إقامتك',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.textPrimaryLight),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Month navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _NavArrow(
                  icon: Icons.chevron_right_rounded,
                  onTap: _prevMonth,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${_monthNames[_viewMonth.month - 1]} ${_viewMonth.year}',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ),
                _NavArrow(
                  icon: Icons.chevron_left_rounded,
                  onTap: _nextMonth,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Week day headers (LTR — calendar days always flow left→right)
          Directionality(
            textDirection: TextDirection.ltr,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: _dayLabels
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.dividerLight),
          const SizedBox(height: 8),

          // Calendar grid
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildGrid(),
              ),
            ),
          ),

          // Bottom bar
          const Divider(height: 1, color: AppColors.dividerLight),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Row(
              children: [
                // Clear button
                TextButton(
                  onPressed: () => setState(() {
                    _checkIn = null;
                    _checkOut = null;
                  }),
                  child: Text(
                    'مسح',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimaryLight,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Spacer(),
                // Confirm button
                FilledButton(
                  onPressed: _canConfirm
                      ? () {
                          widget.onConfirm(_checkIn!, _checkOut!);
                          Navigator.of(context).pop();
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.dividerLight,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _canConfirm
                        ? 'تأكيد  (${_checkOut!.difference(_checkIn!).inDays} ليالٍ)'
                        : 'اختر تاريخ المغادرة',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: _canConfirm
                          ? AppColors.white
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Calendar grid ────────────────────────────────────────

  Widget _buildGrid() {
    final year = _viewMonth.year;
    final month = _viewMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Sunday-first offset: Dart weekday Mon=1…Sun=7 → Sun=0,Mon=1,…Sat=6
    final startOffset = firstDay.weekday % 7;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final dayNum = cellIndex - startOffset + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 48));
            }
            final day = DateTime(year, month, dayNum);
            return Expanded(child: _buildDayCell(day));
          }),
        );
      }),
    );
  }

  Widget _buildDayCell(DateTime day) {
    final isPast = _isPast(day);
    final isCheckIn = _checkIn != null && _sameDay(day, _checkIn!);
    final isCheckOut = _checkOut != null && _sameDay(day, _checkOut!);
    final isSelected = isCheckIn || isCheckOut;
    final hasRange = _checkIn != null && _checkOut != null;
    final isInRange = hasRange &&
        day.isAfter(_checkIn!) &&
        day.isBefore(_checkOut!);

    return GestureDetector(
      onTap: isPast ? null : () => _onDayTap(day),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Range fill (full-width strip)
            if (isInRange)
              Positioned.fill(
                child: Container(color: AppColors.primaryLight),
              )
            else if (isCheckIn && hasRange)
              // Fill right half to connect to range
              Positioned.fill(
                child: Row(
                  children: [
                    const Spacer(),
                    Expanded(
                        child: Container(color: AppColors.primaryLight)),
                  ],
                ),
              )
            else if (isCheckOut && hasRange)
              // Fill left half to connect from range
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                        child: Container(color: AppColors.primaryLight)),
                    const Spacer(),
                  ],
                ),
              ),

            // Day circle
            Container(
              width: 38,
              height: 38,
              decoration: isSelected
                  ? const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    )
                  : null,
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected
                      ? AppColors.white
                      : isPast
                          ? AppColors.textHintLight
                          : isInRange
                              ? AppColors.primary
                              : AppColors.textPrimaryLight,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Navigation arrow ──────────────────────────────────────────────────────────

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.dividerLight),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimaryLight),
      ),
    );
  }
}
