import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/app_theme.dart';

// Runs in a separate isolate — must be a top-level function.
// Firebase must be re-initialized here because isolates don't share state.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FcmService().initListeners();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: AqarApp(),
    ),
  );
}

class AqarApp extends StatelessWidget {
  const AqarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'عقار',
      debugShowCheckedModeBanner: false,

      // ── Theme ─────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // ── iOS-style bouncy scroll everywhere ────────────
      scrollBehavior: const ScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),

      // ── Navigation ────────────────────────────────────
      routerConfig: appRouter,

      // ── RTL (Arabic) ──────────────────────────────────────
      // On iOS the Navigator must see LTR so that CupertinoPage transitions
      // slide from the right edge and swipe-to-go-back fires from the left
      // edge. RTL is applied inside each page via the _page() helper in
      // app_router.dart instead of here.
      builder: (context, child) {
        if (Platform.isIOS) return child!;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
  }
}
