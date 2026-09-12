import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqar_app/main.dart';
import 'package:aqar_app/core/router/app_router.dart';
import 'package:aqar_app/core/theme/app_theme.dart';
import 'package:aqar_app/core/theme/app_colors.dart';
import 'package:aqar_app/core/preview/ui_preview.dart';
import 'package:aqar_app/features/add_listing/presentation/widgets/listing_flow_steps.dart';
import 'package:aqar_app/features/settings/presentation/providers/settings_provider.dart';
import 'test_fonts.dart';

void main() {
  setUpAll(configureTestFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('theme choice persists and restores on next launch', () async {
    final container = ProviderContainer();
    await container
        .read(settingsProvider.notifier)
        .setThemeMode(AppThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    final restored = ProviderContainer(
      overrides: [
        initialThemeModeProvider.overrideWithValue(
          savedThemeMode(prefs.getString(themePreferenceKey)),
        ),
      ],
    );
    expect(restored.read(settingsProvider).themeMode, AppThemeMode.dark);
    expect(savedThemeMode('unknown'), AppThemeMode.system);
    container.dispose();
    restored.dispose();
  });
  testWidgets(
    'actual app obeys explicit light/dark preference independently of device',
    (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final container = ProviderContainer(
        overrides: [
          initialThemeModeProvider.overrideWithValue(AppThemeMode.light),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const AqarApp()),
      );
      appRouter.go('/login/phone');
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.light,
      );
      expect(
        Theme.of(tester.element(find.byType(TextField).first)).brightness,
        Brightness.light,
      );
      await container
          .read(settingsProvider.notifier)
          .setThemeMode(AppThemeMode.dark);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(TextField).first)).brightness,
        Brightness.dark,
      );
      await container
          .read(settingsProvider.notifier)
          .setThemeMode(AppThemeMode.system);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(TextField).first)).brightness,
        Brightness.light,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets(
      'licensing cards and input labels remain readable in $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: brightness == Brightness.dark
                  ? AppTheme.dark
                  : AppTheme.light,
              home: const Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(body: ListingFlowStep('ownerInfo')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('يقوم عقار بإصدار ترخيص إعلان للملاك والوكلاء'),
          findsOneWidget,
        );
        expect(find.text('الخطوات'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('المتطلبات'), 160);
        expect(find.text('المتطلبات'), findsOneWidget);
        expect(find.textContaining('ببيانات تجريبية'), findsNothing);
        final context = tester.element(find.text('المتطلبات'));
        final palette = context.appColors;
        final luminances = [
          palette.card.computeLuminance(),
          palette.textPrimary.computeLuminance(),
        ]..sort();
        expect(
          (luminances.last + .05) / (luminances.first + .05),
          greaterThan(4.5),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          MaterialApp(
            theme: brightness == Brightness.dark
                ? AppTheme.dark
                : AppTheme.light,
            home: Scaffold(
              body: PreviewField(
                label: 'السعة (اختياري)',
                value: '',
                onChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final fieldContext = tester.element(find.byType(TextFormField));
        expect(
          Theme.of(fieldContext).inputDecorationTheme.floatingLabelBehavior,
          FloatingLabelBehavior.always,
        );
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.decoration!.fillColor, fieldContext.appColors.surface);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
