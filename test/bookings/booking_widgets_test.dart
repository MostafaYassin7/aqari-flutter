import 'package:aqar_app/features/bookings/data/booking_repository.dart';
import 'package:aqar_app/features/bookings/domain/booking.dart';
import '../integration_logic/bookings/test_support.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as font_loader;
import 'package:aqar_app/features/bookings/presentation/booking_preview.dart';
import 'package:aqar_app/core/preview/ui_preview.dart';
import 'package:aqar_app/features/home/presentation/widgets/rental_calendar_modal.dart';
import 'package:aqar_app/features/home/data/mock_rentals.dart';
import 'package:aqar_app/features/wallet/presentation/screens/payment_preview_sheet.dart';

class _FontManifest implements AssetManifest {
  @override
  List<String> listAssets() => [
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'])
      'test-fonts/Cairo-$weight.ttf',
  ];
  @override
  List<AssetMetadata>? getAssetVariants(String key) => null;
}

class _PendingBookingsRepository extends FakeBookingRepository {
  @override
  Future<BookingPage> guestBookings({int page = 1, int limit = 20}) async =>
      BookingPage.fromJson({
        'data': [bookingJson()],
        'total': 1,
        'pages': 1,
      });
  @override
  Future<BookingPage> ownerBookings({int page = 1, int limit = 20}) =>
      guestBookings(page: page, limit: limit);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    font_loader.assetManifest = _FontManifest();
    final artifacts = File(Platform.resolvedExecutable).parent.parent.parent;
    final bytes = await File(
      '${artifacts.path}/material_fonts/Roboto-Regular.ttf',
    ).readAsBytes();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final path = const StringCodec().decodeMessage(message);
          if (path?.startsWith('test-fonts/') ?? false) {
            return ByteData.sublistView(bytes);
          }
          return null;
        });
    for (final weight in [
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700,
      FontWeight.w800,
    ]) {
      GoogleFonts.cairo(fontWeight: weight);
    }
    await GoogleFonts.pendingFonts();
  });

  Future<void> render(
    WidgetTester t,
    Widget child, {
    double scale = 1,
    double keyboard = 0,
    Size size = const Size(360, 780),
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          bookingRepositoryProvider.overrideWithValue(
            _PendingBookingsRepository(),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(scale),
              viewInsets: EdgeInsets.only(bottom: keyboard),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          ),
          home: Scaffold(body: child),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> calendar(
    WidgetTester t, {
    int minimum = 1,
    List<DateTime> blocked = const [],
  }) async {
    await render(
      t,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showRentalCalendar(
            context: context,
            checkIn: null,
            checkOut: null,
            minNights: minimum,
            blockedDates: blocked,
            onConfirm: (_, _) {},
          ),
          child: const Text('open'),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    // Use next month so every tested day is in the future.
    await t.tap(find.byIcon(Icons.chevron_left_rounded));
    await t.pumpAndSettle();
  }

  testWidgets('earlier date restarts check-in instead of swapping range', (
    t,
  ) async {
    await calendar(t);
    await t.tap(find.text('10'));
    await t.pump();
    await t.tap(find.text('8'));
    await t.pump();
    expect(find.text('اختر تاريخ المغادرة'), findsOneWidget);
    await t.tap(find.text('11'));
    await t.pump();
    expect(find.text('تأكيد  (3 ليالٍ)'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('minimum-stay rejection moves check-in to new date', (t) async {
    await calendar(t, minimum: 3);
    await t.tap(find.text('10'));
    await t.pump();
    await t.tap(find.text('11'));
    await t.pump();
    expect(find.text('الحد الأدنى للإقامة 3 ليالٍ'), findsOneWidget);
    await t.tap(find.text('14'));
    await t.pump();
    expect(find.text('تأكيد  (3 ليالٍ)'), findsOneWidget);
  });

  testWidgets('blocked range resets dates and clear removes error', (t) async {
    final now = DateTime.now();
    await calendar(t, blocked: [DateTime(now.year, now.month + 1, 12)]);
    await t.tap(find.text('10'));
    await t.pump();
    await t.tap(find.text('14'));
    await t.pump();
    expect(find.text('يوجد تواريخ محجوزة في هذا النطاق'), findsOneWidget);
    expect(find.text('اختر تاريخ الوصول'), findsOneWidget);
    await t.tap(find.text('مسح'));
    await t.pump();
    expect(find.text('يوجد تواريخ محجوزة في هذا النطاق'), findsNothing);
  });

  testWidgets('calendar cannot navigate past the twelve-month boundary', (
    t,
  ) async {
    await calendar(t);
    for (var i = 0; i < 11; i++) {
      await t.tap(find.byIcon(Icons.chevron_left_rounded));
      await t.pump();
    }
    final arrow = t.widget<GestureDetector>(
      find
          .ancestor(
            of: find.byIcon(Icons.chevron_left_rounded),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    expect(arrow.onTap, isNull);
  });

  testWidgets('booking optional fields and keyboard fit small RTL screen', (
    t,
  ) async {
    await render(
      t,
      BookingPreviewSheet(rental: mockRentals.first),
      scale: 1.3,
      keyboard: 300,
    );
    expect(find.text('عدد الضيوف (اختياري)'), findsOneWidget);
    expect(
      t.widget<TextField>(find.byType(TextField).first).controller!.text,
      isEmpty,
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('guest pending actions differ from host actions', (t) async {
    await render(t, const BookingsScreen());
    expect(find.text('إلغاء الطلب'), findsOneWidget);
    expect(find.text('رفض الطلب'), findsNothing);
    await t.tap(find.text('طلبات وحداتي'));
    await t.pumpAndSettle();
    expect(find.text('رفض الطلب'), findsOneWidget);
    expect(find.text('إلغاء الطلب'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('wallet uses web amounts and rejects non-finite amount', (
    t,
  ) async {
    await render(t, const PaymentPreviewSheet(), scale: 1.3, keyboard: 260);
    expect(find.text('5000 ريال'), findsOneWidget);
    expect(find.text('200 ريال'), findsNothing);
    await t.enterText(find.byType(TextField), 'NaN');
    await t.ensureVisible(find.text('التالي'));
    await t.tap(find.text('التالي'));
    await t.pump();
    expect(find.text('أدخل مبلغاً لا يقل عن 100 ريال'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('calendar remains usable at 320px with large text', (t) async {
    await render(
      t,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showRentalCalendar(
            context: context,
            checkIn: null,
            checkOut: null,
            onConfirm: (_, _) {},
          ),
          child: const Text('open'),
        ),
      ),
      size: const Size(320, 640),
      scale: 1.6,
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets('payment failure can retry without losing amount', (t) async {
    await render(t, const PaymentPreviewSheet(), size: const Size(320, 640));
    await t.tap(find.text('500 ريال'));
    await t.pump();
    await t.ensureVisible(find.text('التالي'));
    await t.tap(find.text('التالي'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byType(SwitchListTile));
    await t.tap(find.byType(SwitchListTile));
    await t.pump();
    await t.ensureVisible(find.text('معاينة الدفع'));
    await t.tap(find.text('معاينة الدفع'));
    await t.pumpAndSettle();
    expect(
      find.text('تعذر إكمال معاينة الدفع. يمكنك المحاولة مجدداً.'),
      findsOneWidget,
    );
    expect(find.text('500 ريال'), findsOneWidget);
    await t.ensureVisible(find.byType(SwitchListTile));
    await t.tap(find.byType(SwitchListTile));
    await t.pump();
    await t.ensureVisible(find.text('معاينة الدفع'));
    await t.tap(find.text('معاينة الدفع'));
    await t.pumpAndSettle();
    expect(find.text('العودة للمحفظة'), findsOneWidget);
    expect(t.takeException(), isNull);
  }, skip: !uiPreview);
  testWidgets(
    'booking error retains fields and retry creates one pending preview',
    (t) async {
      await render(t, BookingPreviewSheet(rental: mockRentals.first));
      final context = t.element(find.byType(BookingPreviewSheet));
      final container = ProviderScope.containerOf(context);
      final now = DateTime.now();
      container
          .read(bookingDatesProvider(mockRentals.first.id).notifier)
          .setRange(
            DateTime(now.year, now.month + 1, 10),
            DateTime(now.year, now.month + 1, 13),
          );
      await t.pump();
      await t.enterText(find.byType(TextField).first, '3');
      await t.enterText(find.byType(TextField).last, 'وصول متأخر');
      await t.ensureVisible(find.byType(PopupMenuButton<String>));
      await t.tap(find.byType(PopupMenuButton<String>));
      await t.pumpAndSettle();
      await t.tap(find.text('تعذر إرسال الطلب'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('معاينة تأكيد الطلب'));
      await t.tap(find.text('معاينة تأكيد الطلب'));
      await t.pump();
      expect(
        t.widget<TextField>(find.byType(TextField).first).enabled,
        isFalse,
      );
      await t.pumpAndSettle();
      expect(
        find.text('تعذر إرسال الطلب. حاول مجدداً؛ تم الاحتفاظ ببياناتك.'),
        findsOneWidget,
      );
      expect(
        t.widget<TextField>(find.byType(TextField).last).controller!.text,
        'وصول متأخر',
      );
      await t.ensureVisible(find.byType(PopupMenuButton<String>));
      await t.tap(find.byType(PopupMenuButton<String>));
      await t.pumpAndSettle();
      await t.tap(find.text('طلب في الانتظار'));
      await t.pumpAndSettle();
      final before = container.read(bookingPreviewProvider).length;
      await t.ensureVisible(find.text('معاينة تأكيد الطلب'));
      await t.tap(find.text('معاينة تأكيد الطلب'));
      await t.pumpAndSettle();
      final bookings = container.read(bookingPreviewProvider);
      expect(bookings.length, before + 1);
      expect(bookings.first.status, 'pending');
      expect(bookings.first.guests, 3);
      expect(bookings.first.notes, 'وصول متأخر');
      expect(bookings.first.total, mockRentals.first.pricePerNight * 3);
      expect(find.text('الطلب في انتظار تأكيد المضيف'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
    skip: !uiPreview,
  );
}
