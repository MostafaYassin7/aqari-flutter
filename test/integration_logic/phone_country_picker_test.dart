import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqar_app/features/auth/presentation/screens/phone_input_screen.dart';
import 'test_fonts.dart';

void main() {
  setUpAll(configureTestFonts);
  for (final size in [const Size(390, 844), const Size(320, 568)]) {
    testWidgets('country picker scrolls to Egypt without overflow at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const PhoneInputScreen(),
            builder: (context, child) =>
                Directionality(textDirection: TextDirection.rtl, child: child!),
          ),
        ),
      );
      await tester.tap(find.text('+966'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final list = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(ListView),
      );
      await tester.scrollUntilVisible(
        find.text('مصر'),
        150,
        scrollable: find.descendant(
          of: list,
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.text('مصر'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('+20'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
