import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../router/app_router.dart';
import 'payment_event_service.dart';

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final _messaging = FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenRefreshSub;
  bool _listenersRegistered = false;

  // Called once from main() after Firebase.initializeApp().
  // Registers app-lifetime handlers (tap-from-background, tap-from-killed).
  Future<void> initListeners() async {
    if (_listenersRegistered) return;
    _listenersRegistered = true;

    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Foreground messages — notify wallet to refresh on PAYMENT_CONFIRMED
    FirebaseMessaging.onMessage.listen((message) {
      final type = message.data['referenceType'] as String?
                ?? message.data['type'] as String?;
      if (type == 'payment') PaymentEventService.notifyPaymentConfirmed();
    });

    // App was backgrounded — user tapped notification to resume
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // App was killed — user tapped notification to launch
    // Delay until after the first frame so the router is ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _handleTap(initial);
    });
  }

  // Called after successful login (fire-and-forget).
  // Requests permission, registers current token, keeps it fresh.
  void registerToken() => _registerTokenAsync();

  Future<void> _registerTokenAsync() async {
    await _messaging.requestPermission();

    final token = await _messaging.getToken();
    if (token != null) await _sendTokenToBackend(token);

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen(_sendTokenToBackend);
  }

  // Called on logout — deregisters the token from the backend and resets state.
  Future<void> deregisterToken() async {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;

    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await apiClient.delete(
        ApiEndpoints.pushToken,
        data: {'token': token},
      );
      await _messaging.deleteToken();
    } catch (_) {}
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      await apiClient.post(
        ApiEndpoints.pushToken,
        data: {
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );
    } catch (_) {}
  }

  void _handleTap(RemoteMessage message) {
    final route = _resolveRoute(
      message.data['referenceType'] as String?,
      message.data['referenceId'] as String?,
    );
    if (route != null) appRouter.go(route);
  }

  String? _resolveRoute(String? type, String? id) {
    switch (type) {
      case 'listing':
        return id != null ? '/property/$id' : null;
      case 'rental':
        return id != null ? '/rental/$id' : null;
      case 'project':
        return id != null ? '/project/$id' : null;
      case 'chat':
        return id != null ? '/chat/$id' : null;
      case 'payment':
        return '/wallet';
      default:
        return '/notifications';
    }
  }
}
