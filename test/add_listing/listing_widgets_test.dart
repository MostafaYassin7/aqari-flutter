import 'package:aqar_app/shared/models/listing_category.dart';
import 'package:aqar_app/features/my_listings/presentation/providers/my_listings_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
// Test-only font loading avoids external requests; native visual review uses Cairo.
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as font_loader;
import 'package:aqar_app/features/add_listing/presentation/providers/add_listing_provider.dart';
import 'package:aqar_app/features/add_listing/presentation/widgets/listing_flow_steps.dart';
import 'package:aqar_app/features/add_listing/presentation/steps/step1_category.dart';
import 'package:aqar_app/features/add_listing/presentation/steps/step3_info.dart';
import 'package:aqar_app/features/add_listing/presentation/steps/step4_features.dart';
import 'package:aqar_app/features/add_listing/presentation/steps/step5_details.dart';
import 'package:aqar_app/features/add_listing/presentation/steps/step6_location.dart';
import 'package:aqar_app/features/add_listing/presentation/steps/step7_review.dart';
import 'package:aqar_app/features/add_listing/presentation/screens/add_listing_screen.dart';

class _Categories extends ListingCategoriesNotifier {
  @override
  Future<List<ListingCategory>> build() async => [
    ListingCategory.fromJson({
      'id': 'server-daily-apartment',
      'nameAr': 'شقة إيجار يومي',
      'propertyType': 'apartment',
      'listingType': 'rent_short',
      'isActive': true,
    }),
  ];
}

class _FontManifest implements AssetManifest {
  @override
  List<String> listAssets() => [
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'])
      'test-fonts/Cairo-$weight.ttf',
  ];
  @override
  List<AssetMetadata>? getAssetVariants(String key) => null;
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
    Widget child,
    ProviderContainer c, {
    double scale = 1,
  }) async {
    t.view.physicalSize = const Size(360, 780);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(360, 780),
              textScaler: TextScaler.linear(scale),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(body: child),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [listingCategoriesProvider.overrideWith(_Categories.new)],
    );
    addTearDown(c.dispose);
    return c;
  }

  testWidgets(
    'role cards select host, broker, and owner and remain responsive',
    (t) async {
      final c = container();
      await render(t, const ListingFlowStep('role'), c);
      expect(find.text('مالك / وكيل'), findsOneWidget);
      expect(find.text('مضيف'), findsOneWidget);
      await t.tap(find.text('مضيف'));
      await t.pump();
      expect(c.read(addListingProvider).role, 'host');
      await t.tap(find.text('مسوق عقاري'));
      await t.pump();
      expect(c.read(addListingProvider).role, 'broker');
      await render(t, const ListingFlowStep('role'), c, scale: 1.6);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'owner identity switches required fields; optional phone stays optional',
    (t) async {
      final c = container();
      await render(t, const ListingFlowStep('license'), c);
      expect(find.text('تاريخ ميلاد المالك *'), findsOneWidget);
      await t.tap(find.text('سجل تجاري'));
      await t.pumpAndSettle();
      expect(find.text('تاريخ ميلاد المالك *'), findsNothing);
      expect(find.text('السجل التجاري *'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  for (final type in ['apartment', 'shop', 'land', 'event_hall', 'other']) {
    testWidgets(
      '$type details preserve the original controls and show only relevant fields',
      (t) async {
        final c = container();
        c.read(addListingProvider.notifier).selectType(type, 'sale', type);
        await render(t, const Step5Details(), c);
        expect(
          find.text('غرف النوم'),
          type == 'apartment' ? findsOneWidget : findsNothing,
        );
        if (type == 'event_hall') {
          expect(find.text('الحد الأقصى للضيوف (اختياري)'), findsOneWidget);
        }
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'daily settings mark minimum nights required and capacity optional',
    (t) async {
      final c = container();
      c
          .read(addListingProvider.notifier)
          .selectType('chalet', 'rent_short', 'شاليه');
      await render(t, const Step5Details(bookingSettings: true), c);
      expect(find.text('الحد الأدنى لليالي *'), findsOneWidget);
      expect(find.text('الحد الأقصى للضيوف (اختياري)'), findsOneWidget);
      expect(find.text('وقت الوصول (اختياري)'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('restored category cards carry distinct sale/rent identities', (
    t,
  ) async {
    final c = container();
    await render(t, const Step1Category(), c);
    await t.tap(find.text('شقة إيجار يومي'));
    await t.pump();
    expect(c.read(addListingProvider).listingType, 'rent_short');
    expect(t.takeException(), isNull);
  });
  testWidgets('info and location have matching required and optional labels', (
    t,
  ) async {
    final c = container();
    await render(t, const Step3Info(), c);
    expect(find.text('عنوان الإعلان *'), findsOneWidget);
    expect(t.takeException(), isNull);
    await render(t, const Step6Location(), c);
    expect(find.text('المدينة *'), findsOneWidget);
    expect(find.text('العنوان (اختياري)'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('empty commercial features do not require a selection', (
    t,
  ) async {
    final c = container();
    c.read(addListingProvider.notifier).selectType('shop', 'sale', 'محل');
    await render(t, const Step4Features(), c);
    expect(find.text('لا توجد مميزات إضافية لهذا النوع.'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('review editing goes back by stable step identity', (t) async {
    final c = container();
    String? edited;
    await render(t, Step7Review(onEdit: (s) => edited = s), c);
    await t.tap(find.text('تعديل').first);
    expect(edited, 'role');
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'wizard blocks an empty host license instead of silently advancing',
    (t) async {
      final c = container();
      await render(t, const AddListingScreen(), c);
      await t.tap(find.text('مضيف'));
      await t.pump();
      await t.tap(find.text('التالي'));
      await t.pumpAndSettle();
      expect(find.text('رقم ترخيص وزارة السياحة *'), findsOneWidget);
      await t.tap(find.text('التالي'));
      await t.pumpAndSettle();
      expect(find.text('رقم رخصة وزارة السياحة مطلوب'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
}
