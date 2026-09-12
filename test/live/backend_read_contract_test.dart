import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqar_app/core/network/api_client.dart';
import 'package:aqar_app/core/network/api_failure.dart';
import 'package:aqar_app/features/bookings/data/booking_repository.dart';
import 'package:aqar_app/features/bookings/domain/stay_dates.dart';
import 'package:aqar_app/features/event_halls/data/event_halls_repository.dart';
import 'package:aqar_app/features/home/data/listings_repository.dart';
import 'package:aqar_app/features/wallet/data/wallet_repository.dart';
import 'package:aqar_app/features/wallet/domain/wallet.dart';

// Explicit opt-in only. Auth files stay outside the repository and are never logged.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final enabled = Platform.environment['AQARI_LIVE_READ_CHECKS'] == 'true';
  test(
    'deployed API is readable through the current Flutter repositories',
    () async {
      final previousHttpOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previousHttpOverrides);
      final directory = Platform.environment['AQARI_TEST_AUTH_DIR'];
      expect(directory, isNotNull);
      for (final account in ['first', 'second']) {
        final auth = jsonDecode(
          await File('$directory/$account.json').readAsString(),
        );
        SharedPreferences.setMockInitialValues({
          'aqar_auth_token': auth['token'],
        });
        final dio = createApiClient();
        try {
          final wallet = WalletRepository(dio);
          final summary = await wallet.summary();
          expect(
            summary.balance.isFinite &&
                summary.held.isFinite &&
                summary.pending.isFinite,
            true,
          );
          for (final direction in ['credit', 'debit']) {
            final page = await wallet.transactions(
              direction: direction,
              purpose: TransactionFilter.bookings,
            );
            expect(
              page.items.every(
                (item) =>
                    item.direction == direction &&
                    item.type == TransactionType.booking,
              ),
              true,
            );
          }
          final bookings = BookingRepository(dio);
          await bookings.guestBookings();
          await bookings.ownerBookings();
          final halls = await EventHallsRepository(dio).getPage();
          expect(halls.items.every((hall) => hall.rules.isEventHall), true);
          if (halls.items.isNotEmpty) {
            final start = StayDate.local(DateTime.now()).addDays(60);
            await expectLater(
              bookings.checkAvailability(
                halls.items.first.id,
                StayRange(start, start.addDays(2)),
              ),
              throwsA(
                isA<ApiFailure>().having(
                  (e) => e.statusCode,
                  'contact-only status',
                  400,
                ),
              ),
            );
          }
          final listings = ListingsRepository();
          final categories = await listings.getListingCategories();
          expect(
            categories
                .where(
                  (c) =>
                      c.isActive &&
                      c.propertyType == 'event_hall' &&
                      c.listingType == 'rent_short',
                )
                .length,
            1,
          );
          final rentals = await listings.getDailyRentalPage();
          expect(
            rentals.items.every((rental) => rental.rules.isDailyRental),
            true,
          );
          if (rentals.items.isNotEmpty) {
            final now = DateTime.now();
            await bookings.calendar(
              rentals.items.first.id,
              now.year,
              now.month,
            );
          }
        } finally {
          dio.close(force: true);
        }
      }
    },
    skip: !enabled,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
