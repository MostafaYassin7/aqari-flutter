import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/rentals_provider.dart';

// ── Public entry-point ────────────────────────────────────────────────────────

void showRentalCalendar({
  Future<List<DateTime>> Function(int year, int month)? loadMonth,
  List<DateTime> blockedDates = const [],
  int minNights = 1,
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
      loadMonth: loadMonth,
      blockedDates: blockedDates,
      minNights: minNights,
      initialCheckIn: checkIn,
      initialCheckOut: checkOut,
      onConfirm: onConfirm,
    ),
  );
}

// ── Modal shell ───────────────────────────────────────────────────────────────

class _RentalCalendarModal extends StatefulWidget {
  final Future<List<DateTime>> Function(int year, int month)? loadMonth;
  final List<DateTime> blockedDates;
  final int minNights;
  final DateTime? initialCheckIn;
  final DateTime? initialCheckOut;
  final void Function(DateTime, DateTime) onConfirm;

  const _RentalCalendarModal({
    this.loadMonth,
    this.blockedDates = const [],
    this.minNights = 1,
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

  // Sun-first abbreviated day labels
  static const _dayLabels = ['أحد', 'اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'];

  @override
  void initState() {
    super.initState();
    final now = widget.initialCheckIn ?? DateTime.now();
    _viewMonth = DateTime(now.year, now.month);
    _checkIn = widget.initialCheckIn;
    _checkOut = widget.initialCheckOut;
    _loadVisibleMonth();
  }

  final _monthCache = <String, List<DateTime>>{};
  bool _loading = false, _loadFailed = false;
  int _loadGeneration = 0;
  String _monthKey(DateTime d) => '${d.year}-${d.month}';
  List<DateTime> get _blockedDates => [
    ...widget.blockedDates,
    ..._monthCache.values.expand((v) => v),
  ];
  Future<void> _loadVisibleMonth() async {
    if (widget.loadMonth == null) return;
    final generation = ++_loadGeneration;
    final month = _viewMonth;
    setState(() {
      _loading = true;
      _loadFailed = false;
      _error = null;
    });
    try {
      final key = _monthKey(month);
      _monthCache[key] ??= await widget.loadMonth!(month.year, month.month);
      if (mounted && generation == _loadGeneration) {
        setState(() {
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && generation == _loadGeneration) {
        setState(() {
          _loading = false;
          _loadFailed = true;
          _error = 'تعذر تحميل التواريخ المتاحة. أعد المحاولة.';
        });
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isPast(DateTime day) {
    final today = DateTime.now();
    return day.isBefore(DateTime(today.year, today.month, today.day));
  }

  String? _error;
  bool _blocked(DateTime day) => _blockedDates.any((d) => _sameDay(d, day));
  bool _validRange(DateTime a, DateTime b) =>
      !_isPast(a) &&
      !_blocked(a) &&
      RentalDateRange(checkIn: a, checkOut: b).nights >= widget.minNights &&
      !_blockedDates.any((d) => d.isAfter(a) && d.isBefore(b));

  Future<void> _onDayTap(DateTime day) async {
    if (_isPast(day) || _loading || _loadFailed) return;
    if (_blocked(day) &&
        (_checkIn == null || _checkOut != null || !day.isAfter(_checkIn!))) {
      return;
    }
    if (widget.loadMonth != null &&
        _checkIn != null &&
        _checkOut == null &&
        day.isAfter(_checkIn!)) {
      setState(() => _loading = true);
      try {
        for (
          var m = DateTime(_checkIn!.year, _checkIn!.month);
          !m.isAfter(DateTime(day.year, day.month));
          m = DateTime(m.year, m.month + 1)
        ) {
          _monthCache[_monthKey(m)] ??= await widget.loadMonth!(
            m.year,
            m.month,
          );
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _loading = false;
            _loadFailed = true;
            _error = 'تعذر تحميل التواريخ المتاحة. أعد المحاولة.';
          });
        }
        return;
      }
      if (!mounted) return;
      setState(() => _loading = false);
    }
    setState(() {
      _error = null;
      if (_checkIn == null || _checkOut != null || !day.isAfter(_checkIn!)) {
        _checkIn = day;
        _checkOut = null;
        return;
      }
      if (_blockedDates.any((d) => d.isAfter(_checkIn!) && d.isBefore(day))) {
        _error = 'يوجد تواريخ محجوزة في هذا النطاق';
        _checkIn = null;
        _checkOut = null;
        return;
      }
      if (RentalDateRange(checkIn: _checkIn, checkOut: day).nights <
          widget.minNights) {
        _error = 'الحد الأدنى للإقامة ${widget.minNights} ليالٍ';
        _checkIn = day;
        _checkOut = null;
        return;
      }
      _checkOut = day;
    });
  }

  int get _monthOffset {
    final today = DateTime.now();
    return (_viewMonth.year - today.year) * 12 + _viewMonth.month - today.month;
  }

  void _prevMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
    });
    _loadVisibleMonth();
  }

  void _nextMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
    });
    _loadVisibleMonth();
  }

  bool get _canConfirm =>
      !_loading &&
      !_loadFailed &&
      _checkIn != null &&
      _checkOut != null &&
      _validRange(_checkIn!, _checkOut!);

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.87,
      decoration: BoxDecoration(
        color: context.appColors.card,
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
              color: context.appColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'اختر تواريخ إقامتك',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: context.appColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (_loading) const LinearProgressIndicator(),
          if (_loadFailed)
            TextButton(
              onPressed: _loadVisibleMonth,
              child: const Text('إعادة المحاولة'),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _error!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          Wrap(
            spacing: 16,
            children: [
              for (final entry in {
                'متاح': context.appColors.textSecondary,
                'محجوز': AppColors.error,
                'محدد': AppColors.primary,
              }.entries)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: entry.value),
                    const SizedBox(width: 5),
                    Text(entry.key, style: AppTextStyles.bodySmall),
                  ],
                ),
            ],
          ),
          // Month navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _NavArrow(
                  icon: Icons.chevron_right_rounded,
                  onTap: _monthOffset > 0 ? _prevMonth : null,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${_monthNames[_viewMonth.month - 1]} ${_viewMonth.year}',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                _NavArrow(
                  icon: Icons.chevron_left_rounded,
                  onTap: _monthOffset < 12 ? _nextMonth : null,
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
                              color: context.appColors.textSecondary,
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
          Divider(height: 1, color: context.appColors.divider),
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
          Divider(height: 1, color: context.appColors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Row(
              children: [
                // Clear button
                TextButton(
                  onPressed: () => setState(() {
                    _checkIn = null;
                    _checkOut = null;
                    _error = null;
                  }),
                  child: Text(
                    'مسح',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: context.appColors.textPrimary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Confirm button
                Expanded(
                  child: FilledButton(
                    onPressed: _canConfirm
                        ? () {
                            Navigator.of(context).pop();
                            widget.onConfirm(_checkIn!, _checkOut!);
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: context.appColors.divider,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _canConfirm
                          ? 'تأكيد  (${RentalDateRange(checkIn: _checkIn, checkOut: _checkOut).nights} ليالٍ)'
                          : _checkIn == null
                          ? 'اختر تاريخ الوصول'
                          : 'اختر تاريخ المغادرة',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: _canConfirm
                            ? AppColors.onPrimary
                            : context.appColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
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
    final isPast =
        _isPast(day) ||
        _loading ||
        _loadFailed ||
        (_blocked(day) &&
            (_checkIn == null || _checkOut != null || !day.isAfter(_checkIn!)));
    final isCheckIn = _checkIn != null && _sameDay(day, _checkIn!);
    final isCheckOut = _checkOut != null && _sameDay(day, _checkOut!);
    final isSelected = isCheckIn || isCheckOut;
    final hasRange = _checkIn != null && _checkOut != null;
    final isInRange =
        hasRange && day.isAfter(_checkIn!) && day.isBefore(_checkOut!);

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
                child: Container(color: context.appColors.primaryTint),
              )
            else if (isCheckIn && hasRange)
              // Fill right half to connect to range
              Positioned.fill(
                child: Row(
                  children: [
                    const Spacer(),
                    Expanded(
                      child: Container(color: context.appColors.primaryTint),
                    ),
                  ],
                ),
              )
            else if (isCheckOut && hasRange)
              // Fill left half to connect from range
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(color: context.appColors.primaryTint),
                    ),
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
                      ? AppColors.onPrimary
                      : _blocked(day)
                      ? AppColors.error
                      : isPast
                      ? context.appColors.textHint
                      : isInRange
                      ? AppColors.primary
                      : context.appColors.textPrimary,
                  decoration: _blocked(day) ? TextDecoration.lineThrough : null,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
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
  final VoidCallback? onTap;

  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: context.appColors.divider),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null
              ? context.appColors.textHint
              : context.appColors.textPrimary,
        ),
      ),
    );
  }
}
