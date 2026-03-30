import 'package:socket_io_client/socket_io_client.dart' as io;

const String kSocketBaseUrl = 'http://136.111.230.89:3000';

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
    print('[SOCKET] connectAll called');
    _connectChat(token);
    _connectNotifications(token);
  }

  void _connectChat(String token) {
    // Dispose existing socket if reconnecting
    if (_chatSocket != null) {
      print('[SOCKET] Disposing old chat socket');
      _chatSocket!.dispose();
      _chatSocket = null;
      _chatConnected = false;
    }

    print('[SOCKET] Creating chat socket to $kSocketBaseUrl/chat');
    print('[SOCKET] Token: ${token.substring(0, 20)}...');
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
      print('[SOCKET] ✅ Chat CONNECTED (id: ${_chatSocket?.id})');
      // Re-apply any queued listeners
      _applyQueuedListeners();
    });

    _chatSocket!.onDisconnect((reason) {
      _chatConnected = false;
      print('[SOCKET] ❌ Chat DISCONNECTED reason=$reason');
    });

    _chatSocket!.onConnectError((e) {
      print('[SOCKET] ❌ Chat CONNECT ERROR: $e');
    });

    _chatSocket!.onError((e) {
      print('[SOCKET] ❌ Chat ERROR: $e');
    });

    _chatSocket!.onReconnect((_) {
      print('[SOCKET] 🔄 Chat RECONNECTING');
    });

    _chatSocket!.connect();
    print('[SOCKET] Chat socket.connect() called, waiting for connection...');
  }

  void _applyQueuedListeners() {
    print('[SOCKET] Applying ${_chatListeners.length} queued listeners');
    _chatListeners.forEach((event, cb) {
      _chatSocket?.on(event, (d) => cb(d));
      print('[SOCKET] Listener registered: $event');
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
    _notifSocket!.onConnect((_) {
      _notifConnected = true;
      print('[SOCKET] ✅ Notifications CONNECTED');
    });
    _notifSocket!.onDisconnect((_) {
      _notifConnected = false;
      print('[SOCKET] ❌ Notifications DISCONNECTED');
    });
  }

  // ── Chat events ─────────────────────────────────────────────────────────

  void joinChat(String chatId) {
    print(
      '[SOCKET] joinChat($chatId) connected=$_chatConnected socketExists=${_chatSocket != null}',
    );
    _chatSocket?.emit('join_chat', chatId);
  }

  void leaveChat(String chatId) {
    print('[SOCKET] leaveChat($chatId)');
    _chatSocket?.emit('leave_chat', chatId);
  }

  void sendMessage(String chatId, String content) {
    print('[SOCKET] sendMessage chatId=$chatId connected=$_chatConnected');
    if (_chatSocket == null || !_chatConnected) {
      print('[SOCKET] ⚠️ Cannot send — socket not connected!');
      return;
    }
    _chatSocket!.emit('send_message', {'chatId': chatId, 'content': content});
    print('[SOCKET] ✅ send_message emitted');
  }

  void emitTyping(String chatId) => _chatSocket?.emit('typing', chatId);

  // ── Chat listeners (queued + immediate if connected) ────────────────────

  void onNewMessage(void Function(Map<String, dynamic>) cb) {
    print(
      '[SOCKET] Registering onNewMessage listener, connected=$_chatConnected',
    );
    _chatListeners['new_message'] = (d) {
      print('[SOCKET] 📩 new_message received: $d');
      cb(Map<String, dynamic>.from(d as Map));
    };
    // Also register immediately if already connected
    if (_chatSocket != null) {
      _chatSocket!.on('new_message', (d) {
        print('[SOCKET] 📩 new_message received: $d');
        cb(Map<String, dynamic>.from(d as Map));
      });
    }
  }

  void onUserTyping(void Function(String) cb) {
    _chatListeners['user_typing'] = (d) {
      print('[SOCKET] ⌨️ user_typing received: $d');
      cb(d.toString());
    };
    if (_chatSocket != null) {
      _chatSocket!.on('user_typing', (d) {
        print('[SOCKET] ⌨️ user_typing received: $d');
        cb(d.toString());
      });
    }
  }

  void onMessagesRead(void Function() cb) {
    _chatListeners['messages_read'] = (_) {
      print('[SOCKET] ✓ messages_read received');
      cb();
    };
    if (_chatSocket != null) {
      _chatSocket!.on('messages_read', (_) {
        print('[SOCKET] ✓ messages_read received');
        cb();
      });
    }
  }

  // ── Notification listeners ──────────────────────────────────────────────

  void onNewNotification(void Function(Map<String, dynamic>) cb) => _notifSocket
      ?.on('new_notification', (d) => cb(Map<String, dynamic>.from(d as Map)));

  void disconnectAll() {
    print('[SOCKET] disconnectAll');
    _chatSocket?.dispose();
    _notifSocket?.dispose();
    _chatSocket = null;
    _notifSocket = null;
    _chatConnected = false;
    _notifConnected = false;
    _chatListeners.clear();
  }
}
