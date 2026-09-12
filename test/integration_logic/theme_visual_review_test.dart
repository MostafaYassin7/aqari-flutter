import 'package:cached_network_image/cached_network_image.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqar_app/core/theme/app_theme.dart';
import 'package:aqar_app/features/add_listing/presentation/widgets/listing_flow_steps.dart';
import 'package:aqar_app/features/add_listing/presentation/steps/step3_info.dart';
import 'package:aqar_app/features/add_listing/presentation/steps/step5_details.dart';
import 'package:aqar_app/features/add_listing/presentation/providers/add_listing_provider.dart';
import 'package:aqar_app/features/auth/presentation/screens/phone_input_screen.dart';
import 'package:aqar_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:aqar_app/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:aqar_app/features/event_halls/presentation/event_halls_ui.dart';
import 'package:aqar_app/features/bookings/presentation/booking_preview.dart';
import 'package:aqar_app/features/home/data/mock_rentals.dart';
import 'package:aqar_app/features/home/presentation/widgets/rental_calendar_modal.dart';
import 'test_fonts.dart';

class _ReviewImageCache implements BaseCacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => Stream.error(StateError('Image placeholder for visual review'));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final output = Platform.environment['AQARI_VISUAL_OUTPUT'];
  setUpAll(() async {
    await configureTestFonts();
    CachedNetworkImageProvider.defaultCacheManager = _ReviewImageCache();
  });
  final pages = <String, Widget Function()>{
    'licensing': () => const Scaffold(body: ListingFlowStep('ownerInfo')),
    'roles': () => const Scaffold(body: ListingFlowStep('role')),
    'license_fields': () => const Scaffold(body: ListingFlowStep('license')),
    'listing_info': () => const Scaffold(body: Step3Info()),
    'hall_fields': () => const Scaffold(body: Step5Details()),
    'halls': () => const Scaffold(body: EventHallsTab()),
    'booking': () => Scaffold(
      body: SingleChildScrollView(
        child: BookingPreviewSheet(rental: mockRentals.first),
      ),
    ),
    'wallet': () => const WalletScreen(),
    'phone': () => const PhoneInputScreen(),
    'settings': () => const SettingsScreen(),
    'calendar': () => Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showRentalCalendar(
            context: context,
            checkIn: null,
            checkOut: null,
            onConfirm: (_, __) {},
          ),
          child: const Text('open calendar'),
        ),
      ),
    ),
  };
  for (final mode in ['light', 'dark']) {
    for (final page in pages.entries) {
      testWidgets('visual review ${page.key} $mode', (tester) async {
        tester.view.physicalSize = const Size(402, 874);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        if (page.key == 'hall_fields') {
          container
              .read(addListingProvider.notifier)
              .selectType('event_hall', 'rent_short', 'قاعة مناسبات');
        }
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: RepaintBoundary(
              key: boundaryKey,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: mode == 'dark' ? AppTheme.dark : AppTheme.light,
                builder: (context, child) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: child!,
                ),
                home: page.value(),
              ),
            ),
          ),
        );
        if (page.key == 'halls') {
          await tester.pump(const Duration(milliseconds: 500));
        } else {
          await tester.pumpAndSettle();
        }
        if (page.key == 'calendar') {
          await tester.tap(find.text('open calendar'));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final picture = await boundary.toImage(pixelRatio: 2);
          final bytes = await picture.toByteData(
            format: ui.ImageByteFormat.png,
          );
          await Directory(output!).create(recursive: true);
          await File(
            '$output/${page.key}-$mode.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          picture.dispose();
        });
        await tester.pumpWidget(const SizedBox());
      }, skip: output == null);
    }
  }
}
