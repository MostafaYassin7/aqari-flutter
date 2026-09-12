import 'booking_providers.dart';
import '../domain/booking.dart';
import '../domain/stay_dates.dart';
import '../../../core/router/auth_return.dart';
import '../../../core/network/auth_storage.dart';
import '../../event_halls/domain/hall_contact.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/booking_repository.dart';
import '../../../core/network/api_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/preview/ui_preview.dart';
import 'booking_ui_rules.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/rental.dart';
import '../../home/presentation/providers/rentals_provider.dart';
import '../../home/presentation/widgets/rental_calendar_modal.dart';

final bookingDatesProvider =
    NotifierProvider.family<RentalDateRangeNotifier, RentalDateRange, String>(
      (id) => RentalDateRangeNotifier(),
    );
final bookingPreviewProvider =
    NotifierProvider<BookingPreviewNotifier, List<BookingPreview>>(
      BookingPreviewNotifier.new,
    );

class BookingPreview {
  final Booking? live;
  final String id, title, status, notes;
  final DateTime start, end;
  final int? guests;
  final double total;
  const BookingPreview({
    this.live,
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.total,
    this.guests,
    this.notes = '',
    this.status = 'pending',
  });
  factory BookingPreview.fromBooking(Booking b) => BookingPreview(
    live: b,
    id: b.id,
    title: b.listing?.title ?? 'حجز',
    status: b.rawStatus,
    start: b.checkInDate == null
        ? DateTime(1970)
        : DateTime(
            b.checkInDate!.year,
            b.checkInDate!.month,
            b.checkInDate!.day,
          ),
    end: b.checkOutDate == null
        ? DateTime(1970)
        : DateTime(
            b.checkOutDate!.year,
            b.checkOutDate!.month,
            b.checkOutDate!.day,
          ),
    total: b.totalPrice,
    guests: b.guestCount,
    notes: b.notes ?? '',
  );
  BookingPreview withStatus(String v) => BookingPreview(
    id: id,
    title: title,
    start: start,
    end: end,
    total: total,
    guests: guests,
    notes: notes,
    status: v,
  );
}

class BookingPreviewNotifier extends Notifier<List<BookingPreview>> {
  @override
  List<BookingPreview> build() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day + 3);
    return [
      for (final status in ['pending', 'confirmed', 'cancelled', 'completed'])
        BookingPreview(
          id: 'sample-$status',
          title: 'شاليه النخيل',
          start: start,
          end: start.add(const Duration(days: 2)),
          total: 900,
          status: status,
        ),
    ];
  }

  void add(BookingPreview booking) => state = [booking, ...state];
  void update(String id, String status) =>
      state = [for (final b in state) b.id == id ? b.withStatus(status) : b];
}

String stayDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
List<DateTime> previewBlockedDates() {
  final now = DateTime.now();
  return [
    DateTime(now.year, now.month, now.day + 8),
    DateTime(now.year, now.month, now.day + 9),
  ];
}

Future<List<DateTime>> Function(int, int)? rentalCalendarLoader(
  BuildContext context,
  DailyRental rental,
) {
  if (uiPreview) return null;
  final repository = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(bookingRepositoryProvider);
  return (year, month) async {
    if (!rental.rules.isDailyRental) {
      throw const ApiFailure('قاعات المناسبات للتواصل فقط.');
    }
    final blocks = await repository.calendar(rental.id, year, month);
    return [
      for (final b in blocks) DateTime(b.date.year, b.date.month, b.date.day),
    ];
  };
}

void openBookingPreview(BuildContext context, DailyRental rental) {
  if (!rental.rules.isDailyRental) return;
  final container = ProviderScope.containerOf(context, listen: false);
  void openConfirmation() {
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BookingPreviewSheet(rental: rental),
    );
  }

  final dates = container.read(bookingDatesProvider(rental.id));
  if (bookingInputError(
        dates: dates,
        guests: '',
        notes: '',
        minNights: rental.minNights,
        blockedDates: uiPreview ? previewBlockedDates() : [],
      ) ==
      null) {
    openConfirmation();
    return;
  }
  showRentalCalendar(
    loadMonth: rentalCalendarLoader(context, rental),
    context: context,
    checkIn: dates.checkIn,
    checkOut: dates.checkOut,
    minNights: rental.minNights,
    blockedDates: uiPreview ? previewBlockedDates() : [],
    onConfirm: (start, end) {
      container
          .read(bookingDatesProvider(rental.id).notifier)
          .setRange(start, end);
      openConfirmation();
    },
  );
}

class BookingPreviewSheet extends ConsumerStatefulWidget {
  final DailyRental rental;
  const BookingPreviewSheet({super.key, required this.rental});
  @override
  ConsumerState<BookingPreviewSheet> createState() =>
      _BookingPreviewSheetState();
}

class _BookingPreviewSheetState extends ConsumerState<BookingPreviewSheet> {
  final _guests = TextEditingController();
  final _notes = TextEditingController();
  String? _error;
  bool _success = false, _busy = false;
  String _outcome = 'success';
  bool _uncertain = false;
  Booking? _created;
  @override
  void initState() {
    super.initState();
    if (!uiPreview) {
      final draft = ref.read(bookingDraftsProvider)[widget.rental.id];
      _guests.text = draft?.guests ?? '';
      _notes.text = draft?.notes ?? '';
      _uncertain = draft?.submissionUncertain ?? false;
    }
  }

  void _saveDraft() {
    final dates = ref.read(bookingDatesProvider(widget.rental.id));
    ref
        .read(bookingDraftsProvider.notifier)
        .save(
          widget.rental.id,
          BookingDraft(
            range: dates.hasRange
                ? StayRange(
                    StayDate.local(dates.checkIn!),
                    StayDate.local(dates.checkOut!),
                  )
                : null,
            guests: _guests.text,
            notes: _notes.text,
            submissionUncertain: _uncertain,
          ),
        );
  }

  Future<void> _sendLive() async {
    if (_busy || _uncertain || !widget.rental.rules.isDailyRental) return;
    final r = widget.rental;
    final dates = ref.read(bookingDatesProvider(r.id));
    final error = bookingInputError(
      dates: dates,
      guests: _guests.text,
      notes: _notes.text,
      minNights: r.minNights,
      maxGuests: r.maxGuests,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    _saveDraft();
    if (!await AuthStorage.isLoggedIn()) {
      if (mounted) {
        Navigator.pop(context);
        context.go(authRoute('/login', '/rental/${r.id}'));
      }
      return;
    }
    if (!mounted) return;
    final session = ref.read(authProvider).user?.id;
    setState(() {
      _busy = true;
      _error = null;
    });
    FocusScope.of(context).unfocus();
    bool createStarted = false;
    try {
      final range = StayRange(
        StayDate.local(dates.checkIn!),
        StayDate.local(dates.checkOut!),
      );
      final repo = ref.read(bookingRepositoryProvider);
      final available = await repo.checkAvailability(r.id, range);
      if (!available.isAvailable) {
        throw const ApiFailure('هذه التواريخ لم تعد متاحة. اختر تواريخ أخرى.');
      }
      createStarted = true;
      final result = await repo.create(
        r.id,
        range,
        guestCount: int.tryParse(_guests.text.trim()),
        notes: _notes.text,
      );
      if (!mounted || ref.read(authProvider).user?.id != session) return;
      ref
          .read(guestBookingsProvider.notifier)
          .add(Booking.withListing(result, r.source));
      ref.read(bookingDraftsProvider.notifier).clear(r.id);
      setState(() {
        _created = result;
        _success = true;
      });
    } catch (e) {
      if (!mounted) return;
      final failure = ApiFailure.fromError(e);
      _uncertain = createStarted && failure.mayHaveCommitted;
      if (_uncertain) await ref.read(guestBookingsProvider.notifier).load();
      if (!mounted) return;
      _saveDraft();
      setState(
        () => _error =
            failure.message +
            (_uncertain
                ? '\nتحقق من حجوزاتك قبل إعادة الطلب؛ قد يكون قد حُفظ.'
                : ''),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _hostChat() async {
    if (uiPreview) {
      Navigator.pop(context);
      context.push('/preview-conversation');
      return;
    }
    final owner = widget.rental.source?.contactOwnerId ?? '';
    if (owner.isEmpty) {
      setState(() => _error = 'بيانات المضيف غير متاحة.');
      return;
    }
    try {
      final id = await ref.read(hallChatStarterProvider)(
        owner,
        widget.rental.id,
      );
      if (mounted) {
        Navigator.pop(context);
        context.push('/chat/$id');
      }
    } catch (e) {
      if (mounted) setState(() => _error = ApiFailure.fromError(e).message);
    }
  }

  @override
  void dispose() {
    _guests.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rental;
    final dates = ref.watch(bookingDatesProvider(r.id));
    final total = dates.nights * r.pricePerNight;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _success
                    ? (uiPreview ? 'معاينة طلب الحجز' : 'تم إرسال طلب الحجز')
                    : 'تأكيد طلب الحجز',
                style: AppTextStyles.headlineSmall,
              ),
              const PreviewNotice(),
              if (uiPreview && !_success)
                PopupMenuButton<String>(
                  enabled: !_busy,
                  onSelected: (value) => setState(() => _outcome = value),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'success',
                      child: Text('طلب في الانتظار'),
                    ),
                    PopupMenuItem(
                      value: 'unavailable',
                      child: Text('التواريخ لم تعد متاحة'),
                    ),
                    PopupMenuItem(
                      value: 'error',
                      child: Text('تعذر إرسال الطلب'),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'حالة المعاينة: ${_outcome == 'success'
                          ? 'طلب في الانتظار'
                          : _outcome == 'unavailable'
                          ? 'غير متاح'
                          : 'خطأ'}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ),
              if (_success) ...[
                const Center(
                  child: Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'الطلب في انتظار تأكيد المضيف',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  uiPreview
                      ? 'في الحجز الفعلي يُحجز المبلغ من المحفظة عند تأكيد المضيف. لم يتم إرسال طلب أو خصم أي مبلغ في هذه المعاينة.'
                      : 'سيتم إشعارك عند تأكيد المضيف. يُحجز مبلغ الحجز من محفظتك عند التأكيد. إجمالي الطلب: ${_created?.totalPrice.toStringAsFixed(2)} ريال.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/bookings');
                  },
                  child: const Text('عرض حجوزاتي'),
                ),
                TextButton(
                  onPressed: _hostChat,
                  child: const Text('محادثة المضيف'),
                ),
              ] else ...[
                Text(r.name, style: AppTextStyles.titleMedium),
                const SizedBox(height: 16),
                PreviewSection(
                  title: 'تواريخ الإقامة',
                  onEdit: _busy
                      ? null
                      : () => showRentalCalendar(
                          context: context,
                          loadMonth: rentalCalendarLoader(context, r),
                          checkIn: dates.checkIn,
                          checkOut: dates.checkOut,
                          blockedDates: uiPreview ? previewBlockedDates() : [],
                          minNights: r.minNights,
                          onConfirm: (a, b) => ref
                              .read(bookingDatesProvider(r.id).notifier)
                              .setRange(a, b),
                        ),
                  child: Text(
                    dates.hasRange
                        ? '${stayDate(dates.checkIn!)} ← ${stayDate(dates.checkOut!)}\n${dates.nights} ليالٍ × ${r.pricePerNight.toInt()} ريال\nالإجمالي: ${total.toInt()} ريال'
                        : 'اختر تاريخ الوصول والمغادرة',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                TextField(
                  controller: _guests,
                  onChanged: (_) {
                    if (!uiPreview) _saveDraft();
                  },
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'عدد الضيوف (اختياري)',
                    helperText: r.maxGuests == null
                        ? null
                        : 'الحد الأقصى ${r.maxGuests} ضيف',
                    filled: true,
                    fillColor: context.appColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notes,
                  onChanged: (_) {
                    if (!uiPreview) _saveDraft();
                  },
                  enabled: !_busy,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: 'ملاحظات للمضيف (اختياري)',
                    filled: true,
                    fillColor: context.appColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Text(
                  'لا يتم الدفع الآن. يُحجز المبلغ عند تأكيد المضيف.',
                  style: AppTextStyles.bodySmall,
                ),
                if (_uncertain)
                  TextButton(
                    onPressed: () => context.push('/bookings'),
                    child: const Text('عرض حجوزاتي'),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _error!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy || _uncertain
                        ? null
                        : () async {
                            if (!uiPreview) {
                              await _sendLive();
                              return;
                            }
                            final guests = int.tryParse(_guests.text.trim());
                            final error = bookingInputError(
                              dates: dates,
                              guests: _guests.text,
                              notes: _notes.text,
                              minNights: r.minNights,
                              maxGuests: r.maxGuests,
                              blockedDates: uiPreview
                                  ? previewBlockedDates()
                                  : [],
                            );
                            if (error != null) {
                              setState(() => _error = error);
                              return;
                            }
                            FocusScope.of(context).unfocus();
                            setState(() {
                              _busy = true;
                              _error = null;
                            });
                            await Future<void>.delayed(
                              const Duration(milliseconds: 350),
                            );
                            if (!mounted) return;
                            if (_outcome != 'success') {
                              setState(() {
                                _busy = false;
                                _error = _outcome == 'unavailable'
                                    ? 'هذه التواريخ لم تعد متاحة. اختر تواريخ أخرى.'
                                    : 'تعذر إرسال الطلب. حاول مجدداً؛ تم الاحتفاظ ببياناتك.';
                              });
                              return;
                            }
                            ref
                                .read(bookingPreviewProvider.notifier)
                                .add(
                                  BookingPreview(
                                    id: 'preview-${DateTime.now().microsecondsSinceEpoch}',
                                    title: r.name,
                                    start: dates.checkIn!,
                                    end: dates.checkOut!,
                                    total: total,
                                    guests: guests,
                                    notes: _notes.text,
                                  ),
                                );
                            setState(() {
                              _success = true;
                              _busy = false;
                            });
                          },
                    child: Text(
                      _busy
                          ? 'جارٍ الإرسال…'
                          : uiPreview
                          ? 'معاينة تأكيد الطلب'
                          : 'تأكيد طلب الحجز',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class BookingsScreen extends ConsumerStatefulWidget {
  final bool owner;
  const BookingsScreen({super.key, this.owner = false});
  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen>
    with WidgetsBindingObserver {
  late bool _owner = widget.owner;
  String _view = 'data';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_refresh);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (!uiPreview) {
      if (_owner) {
        await ref.read(ownerBookingsProvider.notifier).load();
      } else {
        await ref.read(guestBookingsProvider.notifier).load();
      }
    }
  }

  Future<void> _chat(BookingPreview b) async {
    if (uiPreview) {
      context.push('/preview-conversation');
      return;
    }
    final record = b.live!;
    final participant = _owner ? record.guestId : record.ownerId;
    try {
      final id = await ref.read(hallChatStarterProvider)(
        participant,
        record.listingId,
      );
      if (mounted) context.push('/chat/$id');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiFailure.fromError(e).message)),
        );
      }
    }
  }

  static const labels = {
    'pending': 'في الانتظار',
    'confirmed': 'مؤكد',
    'cancelled': 'ملغي',
    'completed': 'مكتمل',
  };
  Future<void> action(BookingPreview b, String status) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          status == 'confirmed'
              ? 'تأكيد الحجز؟'
              : status == 'declined'
              ? 'رفض الطلب؟'
              : 'إلغاء الطلب؟',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == 'confirmed')
              const Text(
                'عند تأكيد الحجز يُحجز المبلغ من محفظة الضيف، ويُحوّل للمضيف بعد 7 أيام من انتهاء الحجز.',
              ),
            if (uiPreview)
              const Text(
                'معاينة محلية فقط؛ لن يتم إرسال تحديث أو تحريك أموال.',
              ),
            if (status == 'declined')
              TextField(
                controller: reason,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'سبب الرفض (اختياري)',
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('رجوع'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(uiPreview ? 'تأكيد المعاينة' : 'تأكيد'),
          ),
        ],
      ),
    );
    final reasonText = reason.text;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    reason.dispose();
    if (ok != true || !mounted) return;
    if (uiPreview) {
      ref
          .read(bookingPreviewProvider.notifier)
          .update(b.id, status == 'declined' ? 'cancelled' : status);
      return;
    }
    final action = status == 'confirmed'
        ? BookingAction.confirm
        : status == 'declined'
        ? BookingAction.decline
        : BookingAction.cancel;
    if (_owner) {
      await ref
          .read(ownerBookingsProvider.notifier)
          .act(b.id, action, reason: reasonText);
    } else {
      await ref.read(guestBookingsProvider.notifier).act(b.id, action);
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = uiPreview
        ? null
        : _owner
        ? ref.watch(ownerBookingsProvider)
        : ref.watch(guestBookingsProvider);
    final bookings = uiPreview
        ? ref.watch(bookingPreviewProvider)
        : (live?.items ?? []).map(BookingPreview.fromBooking).toList();
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(title: const Text('حجوزاتي')),
      body: Column(
        children: [
          Row(
            children: [
              for (final owner in [false, true])
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() => _owner = owner);
                      _refresh();
                    },
                    child: Text(
                      owner ? 'طلبات وحداتي' : 'حجوزاتي',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: _owner == owner
                            ? AppColors.primary
                            : context.appColors.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const PreviewNotice(),
          if (uiPreview)
            Wrap(
              spacing: 8,
              children: {'data': 'البيانات', 'empty': 'فارغ', 'error': 'خطأ'}
                  .entries
                  .map(
                    (e) => PreviewChoice(
                      e.value,
                      selected: _view == e.key,
                      onTap: () => setState(() => _view = e.key),
                    ),
                  )
                  .toList(),
            ),
          Expanded(
            child: live?.loading == true && bookings.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _view == 'empty' ||
                      (live?.loaded == true &&
                          live?.error == null &&
                          bookings.isEmpty)
                ? const Center(child: Text('لا توجد حجوزات بعد'))
                : _view == 'error' || (live?.error != null && bookings.isEmpty)
                ? Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() => _view = 'data');
                        _refresh();
                      },
                      child: const Text('تعذر عرض الحجوزات · إعادة المحاولة'),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          bookings.length +
                          (live != null && live.page < live.pages ? 1 : 0),
                      itemBuilder: (c, i) {
                        if (i == bookings.length) {
                          return TextButton(
                            onPressed: live?.loading == true
                                ? null
                                : () {
                                    if (_owner) {
                                      ref
                                          .read(ownerBookingsProvider.notifier)
                                          .load(more: true);
                                    } else {
                                      ref
                                          .read(guestBookingsProvider.notifier)
                                          .load(more: true);
                                    }
                                  },
                            child: Text(live?.error?.message ?? 'عرض المزيد'),
                          );
                        }
                        final b = bookings[i];
                        final busy =
                            (live?.mutating.contains(b.id) ?? false) ||
                            live?.actionErrors[b.id]?.mayHaveCommitted == true;
                        return PreviewSection(
                          title: b.title,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Chip(
                                label: Text(labels[b.status] ?? b.status),
                                backgroundColor: b.status == 'confirmed'
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : context.appColors.primaryTint,
                              ),
                              Text(
                                b.live != null &&
                                        (b.live!.checkInDate == null ||
                                            b.live!.checkOutDate == null)
                                    ? 'تواريخ الإقامة غير متاحة'
                                    : '${stayDate(b.start)} ← ${stayDate(b.end)} · ${RentalDateRange(checkIn: b.start, checkOut: b.end).nights} ليالٍ',
                                style: AppTextStyles.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${b.total.toInt()} ريال',
                                style: AppTextStyles.titleLarge,
                              ),
                              if (_owner)
                                Text(
                                  [
                                    if (b.guests != null) '${b.guests} ضيوف',
                                    if (b.notes.isNotEmpty) b.notes,
                                  ].join('\n'),
                                  style: AppTextStyles.bodySmall,
                                ),
                              if (live?.actionErrors[b.id] != null)
                                Text(
                                  live!.actionErrors[b.id]!.message,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              if (b.status == 'pending' &&
                                  (uiPreview ||
                                      b.live?.canManagePending == true))
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if (_owner)
                                      FilledButton(
                                        onPressed: busy
                                            ? null
                                            : () => action(b, 'confirmed'),
                                        child: const Text('تأكيد'),
                                      ),
                                    TextButton(
                                      onPressed: busy
                                          ? null
                                          : () => action(
                                              b,
                                              _owner ? 'declined' : 'cancelled',
                                            ),
                                      child: Text(
                                        _owner ? 'رفض الطلب' : 'إلغاء الطلب',
                                      ),
                                    ),
                                  ],
                                ),
                              if (b.status == 'confirmed')
                                TextButton(
                                  onPressed: () => _chat(b),
                                  child: Text(
                                    _owner ? 'محادثة الضيف' : 'محادثة المضيف',
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class PreviewConversationScreen extends StatefulWidget {
  const PreviewConversationScreen({super.key});
  @override
  State<PreviewConversationScreen> createState() =>
      _PreviewConversationScreenState();
}

class _PreviewConversationScreenState extends State<PreviewConversationScreen> {
  final _text = TextEditingController();
  final _messages = <String>[];
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('معاينة المحادثة')),
    body: SafeArea(
      child: Column(
        children: [
          const PreviewNotice(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const PreviewSection(
                  title: 'المضيف',
                  child: Text('أهلاً بك، كيف يمكنني مساعدتك؟'),
                ),
                ..._messages.map(
                  (m) => Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.appColors.primaryTint,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(m),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالة تجريبية',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_text.text.trim().isEmpty) return;
                    setState(() => _messages.add(_text.text.trim()));
                    _text.clear();
                  },
                  icon: const Icon(
                    Icons.send_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
