import 'dart:async';
import '../../../core/preview/ui_preview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/socket_service.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../wallet/presentation/providers/wallet_provider.dart';
import 'booking_providers.dart';

bool isFinancialNotification(Map<String, dynamic> data) =>
    data['referenceType'] == 'booking' ||
    data['referenceType'] == 'payment' ||
    data['type'] == 'booking_update' ||
    data['type'] == 'payment_confirmed';
final financialNotificationStreamProvider =
    Provider<Stream<Map<String, dynamic>>>(
      (ref) => SocketService().notificationEvents,
    );
final refreshFinancialStateProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    await Future.wait([
      ref.read(guestBookingsProvider.notifier).load(),
      ref.read(ownerBookingsProvider.notifier).load(),
      ref.read(walletProvider.notifier).refresh(),
    ]);
  },
);

/// Active at the app root so notifications work without visiting their screen.
final financialUpdatesProvider = Provider<void>((ref) {
  final authenticated = ref.watch(
    authProvider.select((s) => s.step == AuthStep.authenticated),
  );
  if (!authenticated || uiPreview) return;
  final subscription = ref.watch(financialNotificationStreamProvider).listen((
    data,
  ) {
    if (ref.mounted && isFinancialNotification(data)) {
      unawaited(ref.read(refreshFinancialStateProvider)());
    }
  });
  ref.onDispose(subscription.cancel);
});
