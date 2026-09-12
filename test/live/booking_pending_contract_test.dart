import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqar_app/core/network/api_client.dart';
import 'package:aqar_app/features/bookings/data/booking_repository.dart';
import 'package:aqar_app/features/bookings/domain/stay_dates.dart';
import 'package:aqar_app/features/wallet/data/wallet_repository.dart';

// Opt-in, pending requests only. Never confirms, charges, or changes existing bookings.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'pending requests cancel and decline with no wallet movement',
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
      final ids = <String>[];
      final run = DateTime.now().microsecondsSinceEpoch.toString();
      final ledger = File('$directory/pending-check-$run.json');
      try {
        account('second');
        final response = await dio.get(
          '/listings/my',
          queryParameters: {'limit': 100},
        );
        final rows = response.data is List
            ? response.data as List
            : response.data['data'] as List;
        final listing = rows.firstWhere(
          (r) =>
              r['status'] == 'published' &&
              r['listingType'] == 'rent_short' &&
              r['propertyType'] != 'event_hall',
        );
        final detail = (await dio.get('/listings/${listing['id']}')).data;
        final nights = (detail['minNights'] as num?)?.toInt() ?? 1;
        final ownerBefore = await wallet.summary();
        account('first');
        final guestBefore = await wallet.summary();
        for (final action in ['cancel', 'decline']) {
          account('first');
          StayRange? stay;
          final start = StayDate.local(DateTime.now()).addDays(90);
          for (var offset = 0; offset < 30; offset += nights + 1) {
            final candidate = StayRange(
              start.addDays(offset),
              start.addDays(offset + nights),
            );
            if ((await bookings.checkAvailability(
              listing['id'],
              candidate,
            )).isAvailable) {
              stay = candidate;
              break;
            }
          }
          expect(
            stay,
            isNotNull,
            reason:
                'A free future interval is required for this controlled test.',
          );
          final created = await bookings.create(
            listing['id'],
            stay!,
            guestCount: 1,
            notes: 'Flutter integration pending test $run $action',
          );
          ids.add(created.id);
          await ledger.writeAsString(
            jsonEncode({'ids': ids, 'cleanupComplete': false}),
          );
          expect(created.rawStatus, 'pending');
          expect(await wallet.summary(), guestBefore);
          account('second');
          expect(await wallet.summary(), ownerBefore);
          if (action == 'cancel') account('first');
          final terminal = action == 'cancel'
              ? await bookings.cancel(created.id)
              : await bookings.decline(
                  created.id,
                  reason: 'Controlled integration test',
                );
          expect(terminal.rawStatus, 'cancelled');
          account('first');
          expect(
            (await bookings.guestBookings(
              limit: 100,
            )).data.firstWhere((b) => b.id == created.id).rawStatus,
            'cancelled',
          );
          expect(await wallet.summary(), guestBefore);
          account('second');
          expect(
            (await bookings.ownerBookings(
              limit: 100,
            )).data.firstWhere((b) => b.id == created.id).rawStatus,
            'cancelled',
          );
          expect(await wallet.summary(), ownerBefore);
        }
      } finally {
        try {
          account('first');
          if (ids.isNotEmpty) {
            final current = await bookings.guestBookings(limit: 100);
            for (final b in current.data.where(
              (b) => ids.contains(b.id) && b.rawStatus == 'pending',
            )) {
              await bookings.cancel(b.id);
            }
          }
          await ledger.writeAsString(
            jsonEncode({'ids': ids, 'cleanupComplete': true}),
          );
        } finally {
          dio.close(force: true);
        }
      }
    },
    skip: Platform.environment['AQARI_LIVE_PENDING_CHECKS'] != 'true',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
