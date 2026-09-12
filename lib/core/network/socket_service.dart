import 'dart:async';
import 'api_client.dart' show kBaseUrl;
import '../preview/ui_preview.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

final String kSocketBaseUrl = Uri.parse(kBaseUrl).origin;

class SocketService {
  io.Socket? _chatSocket;
  io.Socket? _notifSocket;
  bool _chatConnected = false;
  final _notificationEvents =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get notificationEvents =>
      _notificationEvents.stream;

  // Queued listeners — applied when socket connects
  final Map<String, Function> _chatListeners = {};

  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  bool get isChatConnected => _chatConnected;

  void connectAll(String token) {
    if (uiPreview) return;

    _connectChat(token);
    _connectNotifications(token);
  }

  void _connectChat(String token) {
    // Dispose existing socket if reconnecting
    if (_chatSocket != null) {
      _chatSocket!.dispose();
      _chatSocket = null;
      _chatConnected = false;
    }

    _chatSocket = io.io(
      '$kSocketBaseUrl/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _chatSocket!.onConnect((_) {
      _chatConnected = true;

      // Re-apply any queued listeners
      _applyQueuedListeners();
    });

    _chatSocket!.onDisconnect((reason) {
      _chatConnected = false;
    });

    _chatSocket!.onConnectError((e) {});

    _chatSocket!.onError((e) {});

    _chatSocket!.onReconnect((_) {});

    _chatSocket!.connect();
  }

  void _applyQueuedListeners() {
    _chatListeners.forEach((event, cb) {
      _chatSocket?.off(event);
      _chatSocket?.on(event, (d) => cb(d));
    });
  }

  void _connectNotifications(String token) {
    if (_notifSocket != null) {
      _notifSocket!.dispose();
      _notifSocket = null;
    }
    _notifSocket = io.io(
      '$kSocketBaseUrl/notifications',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );
    _notifSocket!.on('new_notification', (data) {
      if (data is Map) _notificationEvents.add(Map<String, dynamic>.from(data));
    });
    _notifSocket!.connect();
    _notifSocket!.onConnect((_) {});
    _notifSocket!.onDisconnect((_) {});
  }

  // ── Chat events ─────────────────────────────────────────────────────────

  void joinChat(String chatId) {
    _chatSocket?.emit('join_chat', chatId);
  }

  void leaveChat(String chatId) {
    _chatSocket?.emit('leave_chat', chatId);
  }

  void sendMessage(String chatId, String content) {
    if (_chatSocket == null || !_chatConnected) {
      return;
    }
    _chatSocket!.emit('send_message', {'chatId': chatId, 'content': content});
  }

  void emitTyping(String chatId) => _chatSocket?.emit('typing', chatId);

  // ── Chat listeners (queued + immediate if connected) ────────────────────

  void onNewMessage(void Function(Map<String, dynamic>) cb) {
    _chatListeners['new_message'] = (d) {
      cb(Map<String, dynamic>.from(d as Map));
    };
    // Also register immediately if already connected
    if (_chatSocket != null) {
      _chatSocket!.off('new_message');
      _chatSocket!.on('new_message', (d) {
        cb(Map<String, dynamic>.from(d as Map));
      });
    }
  }

  void onUserTyping(void Function(String) cb) {
    _chatListeners['user_typing'] = (d) {
      cb(d.toString());
    };
    if (_chatSocket != null) {
      _chatSocket!.off('user_typing');
      _chatSocket!.on('user_typing', (d) {
        cb(d.toString());
      });
    }
  }

  void onMessagesRead(void Function() cb) {
    _chatListeners['messages_read'] = (_) {
      cb();
    };
    if (_chatSocket != null) {
      _chatSocket!.off('messages_read');
      _chatSocket!.on('messages_read', (_) {
        cb();
      });
    }
  }

  // ── Notification listeners ──────────────────────────────────────────────

  void onNewNotification(void Function(Map<String, dynamic>) cb) {
    _notifSocket?.on('new_notification', (d) {
      cb(Map<String, dynamic>.from(d as Map));
    });
  }

  void disconnectAll() {
    _chatSocket?.dispose();
    _notifSocket?.dispose();
    _chatSocket = null;
    _notifSocket = null;
    _chatConnected = false;

    _chatListeners.clear();
  }
}
