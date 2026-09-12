import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hall_filters.dart';
import '../../../../shared/models/listing.dart';
import '../../../../core/network/api_failure.dart';
import '../../data/event_halls_repository.dart';

class EventHallsState {
  final List<Listing> listings;
  final int page;
  final bool hasMore, loadingMore;
  final String? pageError;
  const EventHallsState({
    this.listings = const [],
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.pageError,
  });
}

class EventHallsNotifier extends AsyncNotifier<EventHallsState> {
  int _generation = 0;
  @override
  Future<EventHallsState> build() async {
    _generation++;
    final page = await ref
        .watch(eventHallsRepositoryProvider)
        .getPage(filters: ref.watch(hallFiltersProvider));
    return EventHallsState(listings: page.items, hasMore: page.hasMore);
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    state = const AsyncLoading();
    try {
      final page = await ref
          .read(eventHallsRepositoryProvider)
          .getPage(filters: ref.read(hallFiltersProvider));
      if (ref.mounted && generation == _generation) {
        state = AsyncData(
          EventHallsState(listings: page.items, hasMore: page.hasMore),
        );
      }
    } catch (error, stack) {
      if (ref.mounted && generation == _generation) {
        state = AsyncError(error, stack);
      }
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (state.isLoading ||
        current == null ||
        current.loadingMore ||
        !current.hasMore) {
      return;
    }
    final generation = _generation;
    state = AsyncData(
      EventHallsState(
        listings: current.listings,
        page: current.page,
        hasMore: true,
        loadingMore: true,
      ),
    );
    try {
      final next = await ref
          .read(eventHallsRepositoryProvider)
          .getPage(
            page: current.page + 1,
            filters: ref.read(hallFiltersProvider),
          );
      if (!ref.mounted || generation != _generation) return;
      final unique = {
        for (final listing in [...current.listings, ...next.items])
          listing.id: listing,
      };
      state = AsyncData(
        EventHallsState(
          listings: unique.values.toList(),
          page: current.page + 1,
          hasMore: next.hasMore,
        ),
      );
    } catch (e) {
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(
        EventHallsState(
          listings: current.listings,
          page: current.page,
          hasMore: true,
          pageError: ApiFailure.fromError(e).message,
        ),
      );
    }
  }
}

final eventHallsProvider =
    AsyncNotifierProvider<EventHallsNotifier, EventHallsState>(
      EventHallsNotifier.new,
    );
