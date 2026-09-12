import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as font_loader;

class _FontManifest implements AssetManifest {
  @override
  List<String> listAssets() => [
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'])
      'test-fonts/Cairo-$weight.ttf',
  ];
  @override
  List<AssetMetadata>? getAssetVariants(String key) => null;
}

Future<void> configureTestFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  {
    GoogleFonts.config.allowRuntimeFetching = false;
    font_loader.assetManifest = _FontManifest();
    final artifacts = File(Platform.resolvedExecutable).parent.parent.parent;
    final bytes = await File(
      '${artifacts.path}/material_fonts/Roboto-Regular.ttf',
    ).readAsBytes();
    if (Platform.environment['AQARI_TEST_FONT_DIR'] != null) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          File(
            '${artifacts.path}/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes().then(ByteData.sublistView),
        );
      await icons.load();
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final path = const StringCodec().decodeMessage(message);
          if (path?.startsWith('test-fonts/') ?? false) {
            final directory = Platform.environment['AQARI_TEST_FONT_DIR'];
            if (directory != null) {
              final file = File('$directory/${path!.split('/').last}');
              return ByteData.sublistView(await file.readAsBytes());
            }
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
  }
}
