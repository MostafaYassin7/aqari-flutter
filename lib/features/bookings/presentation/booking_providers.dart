import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/network/auth_storage.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/booking_repository.dart';
import '../../wallet/presentation/providers/wallet_provider.dart';
import '../domain/booking.dart';
import '../domain/stay_dates.dart';

final bookingSignedInProvider = Provider<Future<bool> Function()>(
  (ref) => AuthStorage.isLoggedIn,
);
final bookingTodayProvider = Provider<StayDate Function()>(
  (ref) =>
      () => StayDate.local(DateTime.now()),
);

class BookingDraft {
  final StayRange? range;
  final String guests, notes;
  final bool submissionUncertain;
  const BookingDraft({
    this.range,
    this.guests = '',
    this.notes = '',
    this.submissionUncertain = false,
  });
}

// Intentionally retained across route disposal during authentication. No effects
// or submission are triggered when a draft is restored.
class BookingDrafts extends Notifier<Map<String, BookingDraft>> {
  @override
  Map<String, BookingDraft> build() {
    ref.listen(authProvider.select((s) => s.user?.id), (previous, next) {
      if (previous != null && previous != next) state = {};
    });
    return {};
  }

  void save(String id, BookingDraft draft) => state = {...state, id: draft};
  void clear(String id) => state = {...state}..remove(id);
}

final bookingDraftsProvider =
    NotifierProvider<BookingDrafts, Map<String, BookingDraft>>(
      BookingDrafts.new,
    );

enum BookingAction { cancel, confirm, decline }

class GuestBookingsState {
  final List<Booking> items;
  final bool loading, loaded, retryMore;
  final int page, pages;
  final ApiFailure? error;
  final Set<String> mutating;
  final Map<String, ApiFailure> actionErrors;
  const GuestBookingsState({
    this.items = const [],
    this.loading = false,
    this.loaded = false,
    this.retryMore = false,
    this.page = 0,
    this.pages = 1,
    this.error,
    this.mutating = const {},
    this.actionErrors = const {},
  });
  GuestBookingsState copyWith({
    List<Booking>? items,
    bool? loading,
    bool? loaded,
    bool? retryMore,
    int? page,
    int? pages,
    ApiFailure? error,
    bool clearError = false,
    Set<String>? mutating,
    Map<String, ApiFailure>? actionErrors,
  }) => GuestBookingsState(
    items: items ?? this.items,
    loading: loading ?? this.loading,
    loaded: loaded ?? this.loaded,
    retryMore: retryMore ?? this.retryMore,
    page: page ?? this.page,
    pages: pages ?? this.pages,
    error: clearError ? null : error ?? this.error,
    mutating: mutating ?? this.mutating,
    actionErrors: actionErrors ?? this.actionErrors,
  );
}

class GuestBookings extends Notifier<GuestBookingsState> {
  int _generation = 0, _session = 0;
  final _localIds = <String>{};
  bool get isOwner => false;
  @override
  GuestBookingsState build() {
    ref.watch(authProvider.select((s) => (s.user?.id, s.step)));
    ++_generation;
    ++_session;
    _localIds.clear();
    return const GuestBookingsState();
  }

  void add(Booking booking) {
    _localIds.add(booking.id);
    final existing = state.items.where((b) => b.id == booking.id).firstOrNull;
    final replacement = Booking.withListing(booking, existing?.listing);
    state = state.copyWith(
      items: [replacement, ...state.items.where((b) => b.id != booking.id)],
    );
  }

  Future<void> load({bool more = false}) async {
    if (more && (state.loading || state.page >= state.pages)) return;
    final generation = ++_generation;
    final page = more ? state.page + 1 : 1;
    state = state.copyWith(loading: true, clearError: true, retryMore: more);
    try {
      final repository = ref.read(bookingRepositoryProvider);
      final result = await (isOwner
          ? repository.ownerBookings(page: page)
          : repository.guestBookings(page: page));
      if (!ref.mounted || generation != _generation) return;
      final merged = {
        for (final b in state.items)
          if (more || _localIds.contains(b.id)) b.id: b,
      };
      for (final incoming in result.data) {
        final old = merged[incoming.id];
        // A lagging read must not undo an acknowledged mutation. A newer server
        // record still wins and can reconcile changes made on another device.
        final older =
            old?.updatedAt != null &&
            incoming.updatedAt != null &&
            incoming.updatedAt!.isBefore(old!.updatedAt!);
        final regressesPending =
            old != null &&
            old.status != BookingStatus.pending &&
            old.status != BookingStatus.unknown &&
            incoming.status == BookingStatus.pending &&
            (old.updatedAt == null ||
                incoming.updatedAt == null ||
                !incoming.updatedAt!.isAfter(old.updatedAt!));
        if (!older && !regressesPending) {
          merged[incoming.id] = Booking.withListing(incoming, old?.listing);
        }
      }
      final errors = {...state.actionErrors};
      for (final record in result.data) {
        if (record.status != BookingStatus.pending) errors.remove(record.id);
      }
      state = state.copyWith(
        actionErrors: errors,
        items: merged.values.toList(),
        loading: false,
        loaded: true,
        page: page,
        pages: result.pages,
      );
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        loading: false,
        error: ApiFailure.fromError(error),
      );
    }
  }

  Future<Booking?> act(
    String id,
    BookingAction action, {
    String? reason,
  }) async {
    final booking = state.items.where((b) => b.id == id).firstOrNull;
    if (state.mutating.contains(id) ||
        booking?.canManagePending != true ||
        (isOwner == (action == BookingAction.cancel))) {
      return null;
    }
    final session = _session;
    _localIds.add(id);
    state = state.copyWith(
      mutating: {...state.mutating, id},
      actionErrors: {...state.actionErrors}..remove(id),
    );
    try {
      final repo = ref.read(bookingRepositoryProvider);
      final result = await switch (action) {
        BookingAction.cancel => repo.cancel(id),
        BookingAction.confirm => repo.confirm(id),
        BookingAction.decline => repo.decline(
          id,
          reason: reason?.trim().isEmpty == true ? null : reason?.trim(),
        ),
      };
      if (!ref.mounted || session != _session) return null;
      ++_generation; // Discard any reads started before the mutation committed.
      add(result);
      state = state.copyWith(loading: false);
      if (action == BookingAction.confirm) {
        await Future.wait([
          load(),
          ref.read(walletProvider.notifier).refresh(),
        ]);
      }
      if (!ref.mounted || session != _session) return null;
      return result;
    } catch (error) {
      if (!ref.mounted || session != _session) return null;
      state = state.copyWith(
        actionErrors: {...state.actionErrors, id: ApiFailure.fromError(error)},
      );
      // Cancellation/decline can also commit before notification delivery fails.
      await load();
      return null;
    } finally {
      if (ref.mounted && session == _session) {
        state = state.copyWith(mutating: {...state.mutating}..remove(id));
      }
    }
  }
}

class OwnerBookings extends GuestBookings {
  @override
  bool get isOwner => true;
}

final guestBookingsProvider =
    NotifierProvider<GuestBookings, GuestBookingsState>(GuestBookings.new);
final ownerBookingsProvider =
    NotifierProvider<OwnerBookings, GuestBookingsState>(OwnerBookings.new);
