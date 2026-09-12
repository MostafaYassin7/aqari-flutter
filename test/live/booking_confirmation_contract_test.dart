import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqar_app/core/network/api_client.dart';
import 'package:aqar_app/core/network/api_failure.dart';
import 'package:aqar_app/features/bookings/data/booking_repository.dart';
import 'package:aqar_app/features/bookings/domain/stay_dates.dart';
import 'package:aqar_app/features/wallet/data/wallet_repository.dart';

// Confirms only the explicitly authorized ID. Never retries an uncertain write.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final id = Platform.environment['AQARI_LIVE_CONFIRM_BOOKING_ID'];
  test(
    'authorized pending booking confirms once and reconciles both wallets',
    () async {
      final oldOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = oldOverrides);
      final directory = Platform.environment['AQARI_TEST_AUTH_DIR']!;
      final auth = {
        for (final account in ['first', 'second'])
          account: jsonDecode(
            await File('$directory/$account.json').readAsString(),
          ),
      };
      void account(String name) => SharedPreferences.setMockInitialValues({
        'aqar_auth_token': auth[name]['token'],
      });
      final dio = createApiClient();
      final bookings = BookingRepository(dio);
      final wallet = WalletRepository(dio);
      final ledger = File('$directory/confirmation-$id.json');
      Future<int> references(String endpoint) async {
        final raw = (await dio.get(
          endpoint,
          queryParameters: {'limit': 100, 'referenceType': 'booking'},
        )).data;
        final rows = raw is List ? raw : raw['data'] as List;
        return rows.where((row) => row['referenceId'] == id).length;
      }

      try {
        account('first');
        final pending = (await bookings.guestBookings(
          limit: 100,
        )).data.singleWhere((b) => b.id == id);
        expect(pending.rawStatus, 'pending');
        expect(pending.listing?.rules.isDailyRental, true);
        final range = StayRange(pending.checkInDate!, pending.checkOutDate!);
        expect(
          (await bookings.checkAvailability(
            pending.listingId,
            range,
          )).isAvailable,
          true,
        );
        final guestBefore = await wallet.summary();
        expect(guestBefore.balance >= pending.totalPrice, true);
        expect(await references('/wallet/transactions'), 0);
        expect(await references('/wallet/invoices'), 0);
        account('second');
        final owned = (await bookings.ownerBookings(
          limit: 100,
        )).data.singleWhere((b) => b.id == id);
        expect(owned.rawStatus, 'pending');
        final ownerBefore = await wallet.summary();
        await ledger.writeAsString(
          jsonEncode({
            'bookingId': id,
            'status': 'before-confirmation',
            'guest': {'balance': guestBefore.balance, 'held': guestBefore.held},
            'owner': {
              'balance': ownerBefore.balance,
              'pending': ownerBefore.pending,
            },
          }),
        );
        final confirmed = await bookings.confirm(id!);
        await ledger.writeAsString(
          jsonEncode({'bookingId': id, 'status': confirmed.rawStatus}),
        );
        expect(confirmed.rawStatus, 'confirmed');
        final ownerAfter = await wallet.summary();
        expect(ownerAfter.balance, ownerBefore.balance);
        expect(
          ownerAfter.pending,
          closeTo(ownerBefore.pending + pending.totalPrice, 0.001),
        );
        account('first');
        final guestAfter = await wallet.summary();
        expect(
          guestAfter.balance,
          closeTo(guestBefore.balance - pending.totalPrice, 0.001),
        );
        expect(
          guestAfter.held,
          closeTo(guestBefore.held + pending.totalPrice, 0.001),
        );
        expect(await references('/wallet/transactions'), 1);
        expect(await references('/wallet/invoices'), 1);
        for (final month
            in range.bookedNights.map((d) => '${d.year}-${d.month}').toSet()) {
          final parts = month.split('-').map(int.parse).toList();
          final calendar = await bookings.calendar(
            pending.listingId,
            parts[0],
            parts[1],
          );
          for (final date in range.bookedNights.where(
            (d) => d.year == parts[0] && d.month == parts[1],
          )) {
            expect(calendar.where((block) => block.date == date).length, 1);
          }
        }
        expect(
          (await bookings.guestBookings(
            limit: 100,
          )).data.singleWhere((b) => b.id == id).rawStatus,
          'confirmed',
        );
        account('second');
        await expectLater(
          bookings.confirm(id),
          throwsA(
            isA<ApiFailure>().having(
              (e) => e.statusCode,
              'duplicate confirmation rejected',
              400,
            ),
          ),
        );
        expect(await wallet.summary(), ownerAfter);
        account('first');
        expect(await wallet.summary(), guestAfter);
        expect(await references('/wallet/transactions'), 1);
        expect(await references('/wallet/invoices'), 1);
        await ledger.writeAsString(
          jsonEncode({
            'bookingId': id,
            'status': 'confirmed',
            'verificationPassed': true,
            'releaseVerified': false,
          }),
        );
      } finally {
        dio.close(force: true);
      }
    },
    skip: id == null || id.isEmpty,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
