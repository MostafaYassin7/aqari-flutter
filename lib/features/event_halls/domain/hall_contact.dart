import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_failure.dart';
import '../../chat/presentation/providers/chat_provider.dart';

String? normalizeWhatsAppNumber(String? phone) {
  if (phone == null) return null;
  var value = phone.trim();
  for (var i = 0; i < 10; i++) {
    value = value
        .replaceAll(String.fromCharCode(0x660 + i), '$i')
        .replaceAll(String.fromCharCode(0x6f0 + i), '$i');
  }
  value = value.replaceAll(RegExp(r'[\s().-]'), '');
  if (!RegExp(r'^\+?\d+$').hasMatch(value)) return null;
  final international = value.startsWith('+') || value.startsWith('00');
  if (value.startsWith('+')) value = value.substring(1);
  if (value.startsWith('00')) value = value.substring(2);
  if (!international && RegExp(r'^05\d{8}$').hasMatch(value)) {
    value = '966${value.substring(1)}';
  }
  if (!international && RegExp(r'^5\d{8}$').hasMatch(value)) {
    value = '966$value';
  }
  if (!RegExp(r'^[1-9]\d{7,14}$').hasMatch(value)) return null;
  if (value.startsWith('966') && value.length != 12) return null;
  return value;
}

Uri? whatsAppUri(String? phone, {required String title}) {
  final number = normalizeWhatsAppNumber(phone);
  return number == null
      ? null
      : Uri.https('wa.me', '/$number', {
          'text': 'مرحباً، أود الاستفسار عن $title',
        });
}

typedef ExternalLinkLauncher = Future<bool> Function(Uri uri);
final externalLinkLauncherProvider = Provider<ExternalLinkLauncher>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);
typedef HallChatStarter =
    Future<String> Function(String ownerId, String listingId);
final hallChatStarterProvider = Provider<HallChatStarter>(
  (ref) => (ownerId, listingId) async {
    final id = await ref
        .read(chatsProvider.notifier)
        .findOrCreateChat(participantId: ownerId, listingId: listingId);
    if (id == null || id.isEmpty) {
      throw const ApiFailure('تعذر فتح المحادثة. حاول مجدداً.');
    }
    return id;
  },
);
