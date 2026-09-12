import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqar_app/features/bookings/presentation/booking_preview.dart';
import 'package:aqar_app/features/bookings/presentation/booking_providers.dart';
import 'package:aqar_app/features/bookings/data/booking_repository.dart';
import 'package:aqar_app/features/bookings/domain/booking.dart';
import 'package:aqar_app/features/home/presentation/widgets/rental_calendar_modal.dart';
import 'package:aqar_app/shared/models/rental.dart';
import 'package:aqar_app/shared/models/listing.dart';
import 'package:aqar_app/features/event_halls/presentation/event_halls_ui.dart';
import 'package:aqar_app/features/rental_details/presentation/screens/rental_details_screen.dart';
import 'package:aqar_app/core/network/api_failure.dart';
import 'bookings/test_support.dart';
import 'test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureTestFonts);
  setUp(() {
    final payload = base64Url
        .encode(
          utf8.encode(
            jsonEncode({
              'exp':
                  DateTime.now()
                      .add(const Duration(days: 1))
                      .millisecondsSinceEpoch ~/
                  1000,
            }),
          ),
        )
        .replaceAll('=', '');
    SharedPreferences.setMockInitialValues({
      'aqar_auth_token': 'e30.$payload.signature',
    });
  });
  Future<void> render(WidgetTester t, Widget child, ProviderContainer c) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets(
    'live booking checks availability, disables duplicate submit, uses server total',
    (t) async {
      final complete = Completer<Booking>();
      final repo = FakeBookingRepository()..creator = () => complete.future;
      final c = ProviderContainer(
        overrides: [bookingRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      final rentalItem = DailyRental.fromListing(rental());
      final now = DateTime.now();
      c
          .read(bookingDatesProvider(rentalItem.id).notifier)
          .setRange(
            DateTime(now.year, now.month + 1, 10),
            DateTime(now.year, now.month + 1, 12),
          );
      await render(t, BookingPreviewSheet(rental: rentalItem), c);
      await t.ensureVisible(
        find.widgetWithText(FilledButton, 'تأكيد طلب الحجز'),
      );
      await t.tap(find.widgetWithText(FilledButton, 'تأكيد طلب الحجز'));
      await t.pumpAndSettle();
      expect(repo.checks.length, 1);
      expect(repo.creates.length, 1);
      expect(
        t.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
        isNull,
      );
      complete.complete(Booking.fromJson(bookingJson()));
      await t.pumpAndSettle();
      expect(find.textContaining('260.75'), findsOneWidget);
      expect(c.read(guestBookingsProvider).items.single.rawStatus, 'pending');
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('unavailable dates never create a booking and inputs remain', (
    t,
  ) async {
    final repo = FakeBookingRepository()
      ..availability = () =>
          AvailabilityResult.fromJson({'isAvailable': false});
    final c = ProviderContainer(
      overrides: [bookingRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    final r = DailyRental.fromListing(rental());
    final now = DateTime.now();
    c
        .read(bookingDatesProvider(r.id).notifier)
        .setRange(
          DateTime(now.year, now.month + 1, 10),
          DateTime(now.year, now.month + 1, 12),
        );
    await render(t, BookingPreviewSheet(rental: r), c);
    await t.enterText(find.byType(TextField).first, '2');
    await t.ensureVisible(find.widgetWithText(FilledButton, 'تأكيد طلب الحجز'));
    await t.tap(find.widgetWithText(FilledButton, 'تأكيد طلب الحجز'));
    await t.pumpAndSettle();
    expect(repo.creates, isEmpty);
    expect(find.textContaining('لم تعد متاحة'), findsOneWidget);
    expect(
      t.widget<TextField>(find.byType(TextField).first).controller!.text,
      '2',
    );
  });
  testWidgets(
    'stale hall rental link renders contact screen without booking API calls',
    (t) async {
      final hall = Listing.fromJson(rentalJson(propertyType: 'event_hall'));
      final repo = FakeBookingRepository();
      final c = ProviderContainer(
        overrides: [
          bookingRepositoryProvider.overrideWithValue(repo),
          rentalDetailProvider(
            'hall',
          ).overrideWith((ref) async => DailyRental.fromListing(hall)),
          hallDetailProvider(hall.id).overrideWith((ref) async => hall),
        ],
      );
      addTearDown(c.dispose);
      await render(t, const RentalDetailsScreen(rentalId: 'hall'), c);
      expect(find.text('واتساب'), findsOneWidget);
      expect(find.text('احجز الآن'), findsNothing);
      expect(repo.months, isEmpty);
      expect(repo.checks, isEmpty);
      expect(repo.creates, isEmpty);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'calendar retries failed month without pretending it is available',
    (t) async {
      var calls = 0;
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await render(
        t,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showRentalCalendar(
              context: context,
              checkIn: null,
              checkOut: null,
              onConfirm: (_, _) {},
              loadMonth: (year, month) async {
                calls++;
                if (calls == 1) throw const ApiFailure('offline');
                return [];
              },
            ),
            child: const Text('open'),
          ),
        ),
        c,
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      expect(find.text('إعادة المحاولة'), findsOneWidget);
      await t.tap(find.text('إعادة المحاولة'));
      await t.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('إعادة المحاولة'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
}
