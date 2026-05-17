import 'package:socket_io_client/socket_io_client.dart' as io;

const String kSocketBaseUrl = 'https://api.aqora.sa';

class SocketService {
  io.Socket? _chatSocket;
  io.Socket? _notifSocket;
  bool _chatConnected = false;
  bool _notifConnected = false;

  // Queued listeners — applied when socket connects
  final Map<String, Function> _chatListeners = {};

  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  bool get isChatConnected => _chatConnected;

  void connectAll(String token) {
    _connectChat(token);
    _connectNotifications(token);
  }

  void _connectChat(String token) {
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
      _applyQueuedListeners();
    });

    _chatSocket!.onDisconnect((_) {
      _chatConnected = false;
    });

    _chatSocket!.connect();
  }

  void _applyQueuedListeners() {
    _chatListeners.forEach((event, cb) {
      _chatSocket?.on(event, (d) => cb(d));
    });
  }

  void _connectNotifications(String token) {
    if (_notifSocket != null) {
      _notifSocket!.dispose();
      _notifSocket = null;
      _notifConnected = false;
    }
    _notifSocket = io.io(
      '$kSocketBaseUrl/notifications',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );
    _notifSocket!.connect();
    _notifSocket!.onConnect((_) => _notifConnected = true);
    _notifSocket!.onDisconnect((_) => _notifConnected = false);
  }

  // ── Chat events ─────────────────────────────────────────────────────────

  void joinChat(String chatId) => _chatSocket?.emit('join_chat', chatId);

  void leaveChat(String chatId) => _chatSocket?.emit('leave_chat', chatId);

  void sendMessage(String chatId, String content) {
    if (_chatSocket == null || !_chatConnected) return;
    _chatSocket!.emit('send_message', {'chatId': chatId, 'content': content});
  }

  void emitTyping(String chatId) => _chatSocket?.emit('typing', chatId);

  // ── Chat listeners (queued + immediate if connected) ────────────────────

  void onNewMessage(void Function(Map<String, dynamic>) cb) {
    _chatListeners['new_message'] = (d) => cb(Map<String, dynamic>.from(d as Map));
    if (_chatSocket != null) {
      _chatSocket!.on('new_message', (d) => cb(Map<String, dynamic>.from(d as Map)));
    }
  }

  void onUserTyping(void Function(String) cb) {
    _chatListeners['user_typing'] = (d) => cb(d.toString());
    if (_chatSocket != null) {
      _chatSocket!.on('user_typing', (d) => cb(d.toString()));
    }
  }

  void onMessagesRead(void Function() cb) {
    _chatListeners['messages_read'] = (_) => cb();
    if (_chatSocket != null) {
      _chatSocket!.on('messages_read', (_) => cb());
    }
  }

  void onNewNotification(void Function(Map<String, dynamic>) cb) {
    _notifSocket?.on('new_notification', (d) => cb(Map<String, dynamic>.from(d as Map)));
  }

  void disconnectAll() {
    _chatSocket?.dispose();
    _notifSocket?.dispose();
    _chatSocket = null;
    _notifSocket = null;
    _chatConnected = false;
    _notifConnected = false;
    _chatListeners.clear();
  }
}
