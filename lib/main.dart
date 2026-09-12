import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

import 'core/router/app_router.dart';
import 'features/bookings/presentation/financial_updates.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        initialThemeModeProvider.overrideWithValue(
          savedThemeMode(prefs.getString(themePreferenceKey)),
        ),
      ],
      child: const AqarApp(),
    ),
  );
}

class AqarApp extends ConsumerWidget {
  const AqarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(financialUpdatesProvider);
    return MaterialApp.router(
      title: 'عقار',
      debugShowCheckedModeBanner: false,

      // ── Theme ─────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (ref.watch(
        settingsProvider.select((s) => s.themeMode),
      )) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      },

      // ── Navigation ────────────────────────────────────
      routerConfig: appRouter,

      // ── RTL default (Arabic) — override per-screen for LTR ──
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
  }
}
