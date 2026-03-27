import 'package:socket_io_client/socket_io_client.dart' as io;

const String kSocketBaseUrl = 'http://136.111.230.89:3000';

class SocketService {
  io.Socket? _chatSocket;
  io.Socket? _notifSocket;
  bool _chatConnected = false;
  bool _notifConnected = false;

  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  void connectAll(String token) {
    _connectChat(token);
    _connectNotifications(token);
  }

  void _connectChat(String token) {
    if (_chatConnected) return;
    _chatSocket = io.io(
      '$kSocketBaseUrl/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );
    _chatSocket!.connect();
    _chatSocket!.onConnect((_) => _chatConnected = true);
    _chatSocket!.onDisconnect((_) => _chatConnected = false);
    _chatSocket!.onConnectError((e) => print('Chat socket error: $e')); // ignore: avoid_print
  }

  void _connectNotifications(String token) {
    if (_notifConnected) return;
    _notifSocket = io.io(
      '$kSocketBaseUrl/notifications',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );
    _notifSocket!.connect();
    _notifSocket!.onConnect((_) => _notifConnected = true);
    _notifSocket!.onDisconnect((_) => _notifConnected = false);
  }

  // Chat events
  void joinChat(String chatId) =>
      _chatSocket?.emit('join_chat', chatId);

  void leaveChat(String chatId) =>
      _chatSocket?.emit('leave_chat', chatId);

  void sendMessage(String chatId, String content) =>
      _chatSocket?.emit('send_message', {'chatId': chatId, 'content': content});

  void emitTyping(String chatId) =>
      _chatSocket?.emit('typing', chatId);

  void onNewMessage(void Function(Map<String, dynamic>) cb) =>
      _chatSocket?.on('new_message', (d) => cb(Map<String, dynamic>.from(d as Map)));

  void onUserTyping(void Function(String) cb) =>
      _chatSocket?.on('user_typing', (d) => cb(d.toString()));

  void onMessagesRead(void Function() cb) =>
      _chatSocket?.on('messages_read', (_) => cb());

  // Notification events
  void onNewNotification(void Function(Map<String, dynamic>) cb) =>
      _notifSocket?.on('new_notification',
          (d) => cb(Map<String, dynamic>.from(d as Map)));

  void disconnectAll() {
    _chatSocket?.disconnect();
    _notifSocket?.disconnect();
    _chatConnected = false;
    _notifConnected = false;
  }
}
