import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/socket_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class ChatContact {
  final String id;
  final String name;
  final String photoUrl;

  const ChatContact({
    required this.id,
    required this.name,
    required this.photoUrl,
  });

  factory ChatContact.fromJson(Map<String, dynamic> json) {
    return ChatContact(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      photoUrl: (json['profilePhoto'] ?? '').toString(),
    );
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final bool isSent; // true = sent by me
  final DateTime timestamp;
  final bool isRead;

  const ChatMessage({
    required this.id,
    this.chatId = '',
    this.senderId = '',
    required this.text,
    required this.isSent,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(
    Map<String, dynamic> json,
    String currentUserId,
  ) {
    final senderId = (json['senderId'] ?? '').toString();
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      chatId: (json['chatId'] ?? '').toString(),
      senderId: senderId,
      text: (json['content'] ?? '').toString(),
      isSent: senderId == currentUserId,
      timestamp:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      isRead: json['isRead'] == true,
    );
  }
}

class Chat {
  final String id;
  final ChatContact contact;
  final String? listingId;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final List<ChatMessage> messages;
  final int messagesPage;
  final bool hasMoreMessages;
  final bool isLoadingMessages;

  const Chat({
    required this.id,
    required this.contact,
    this.listingId,
    this.lastMessage = '',
    this.lastMessageAt,
    this.unreadCount = 0,
    this.messages = const [],
    this.messagesPage = 1,
    this.hasMoreMessages = true,
    this.isLoadingMessages = false,
  });

  String get lastMessageText =>
      messages.isNotEmpty ? messages.last.text : lastMessage;

  DateTime? get lastMessageTime =>
      messages.isNotEmpty ? messages.last.timestamp : lastMessageAt;

  Chat copyWith({
    ChatContact? contact,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    List<ChatMessage>? messages,
    int? messagesPage,
    bool? hasMoreMessages,
    bool? isLoadingMessages,
  }) => Chat(
    id: id,
    contact: contact ?? this.contact,
    listingId: listingId,
    lastMessage: lastMessage ?? this.lastMessage,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    unreadCount: unreadCount ?? this.unreadCount,
    messages: messages ?? this.messages,
    messagesPage: messagesPage ?? this.messagesPage,
    hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
    isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
  );

  factory Chat.fromJson(Map<String, dynamic> json, String currentUserId) {
    // Determine the other participant
    final participantA = (json['participantA'] ?? '').toString();
    final otherRaw =
        json['otherParticipant'] ??
        (participantA == currentUserId ? json['userB'] : json['userA']);
    final contact = otherRaw is Map
        ? ChatContact.fromJson(Map<String, dynamic>.from(otherRaw))
        : const ChatContact(id: '', name: 'مستخدم', photoUrl: '');

    return Chat(
      id: (json['id'] ?? '').toString(),
      contact: contact,
      listingId: json['listingId']?.toString(),
      lastMessage: (json['lastMessage'] ?? '').toString(),
      lastMessageAt: DateTime.tryParse(json['lastMessageAt']?.toString() ?? ''),
      unreadCount: (json['unreadCount'] as int?) ?? 0,
    );
  }
}

// ── State ─────────────────────────────────────────────────────────────────────

class ChatsState {
  final List<Chat> chats;
  final bool isLoading;
  final String? error;
  final String? typingChatId; // chatId where other user is typing
  final DateTime? typingExpiry;

  const ChatsState({
    this.chats = const [],
    this.isLoading = false,
    this.error,
    this.typingChatId,
    this.typingExpiry,
  });

  ChatsState copyWith({
    List<Chat>? chats,
    bool? isLoading,
    String? error,
    String? typingChatId,
    DateTime? typingExpiry,
  }) => ChatsState(
    chats: chats ?? this.chats,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    typingChatId: typingChatId ?? this.typingChatId,
    typingExpiry: typingExpiry ?? this.typingExpiry,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ChatsNotifier extends Notifier<ChatsState> {
  final _socket = SocketService();
  Timer? _typingTimer;
  String _currentUserId = '';

  @override
  ChatsState build() {
    final user = ref.watch(authProvider).user;
    _currentUserId = user?.id ?? '';

    // Set up socket listeners
    _setupSocketListeners();

    // Fetch chats on init
    Future.microtask(() => fetchChats());

    ref.onDispose(() {
      _typingTimer?.cancel();
    });

    return const ChatsState(isLoading: true);
  }

  void _setupSocketListeners() {
    _socket.onNewMessage((data) {
      final msgData = data['message'];
      if (msgData is! Map) return;
      final chatId = (data['chatId'] ?? msgData['chatId'] ?? '').toString();
      final msg = ChatMessage.fromJson(
        Map<String, dynamic>.from(msgData),
        _currentUserId,
      );

      final chats = [...state.chats];
      final idx = chats.indexWhere((c) => c.id == chatId);
      if (idx >= 0) {
        final chat = chats[idx];
        chats[idx] = chat.copyWith(
          messages: [...chat.messages, msg],
          lastMessage: msg.text,
          lastMessageAt: msg.timestamp,
          unreadCount: msg.isSent ? chat.unreadCount : chat.unreadCount + 1,
        );
        // Move to top
        final updated = chats.removeAt(idx);
        chats.insert(0, updated);
        state = state.copyWith(chats: chats);
      } else {
        // New chat from someone — refresh the list
        fetchChats();
      }
    });

    _socket.onUserTyping((chatId) {
      try {
        if (chatId.isEmpty) return;
        state = state.copyWith(
          typingChatId: chatId,
          typingExpiry: DateTime.now().add(const Duration(seconds: 3)),
        );
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 3), () {
          state = state.copyWith(typingChatId: null, typingExpiry: null);
        });
      } catch (_) {}
    });

    _socket.onMessagesRead(() {
      // Refresh to pick up read status
    });
  }

  // ── REST API methods ──────────────────────────────────────────────────────

  Future<void> fetchChats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.get(ApiEndpoints.chats);
      final raw = response.data;
      List<dynamic> items = [];
      if (raw is List) {
        items = raw;
      } else if (raw is Map) {
        items = (raw['data'] ?? raw['items'] ?? []) as List;
      }
      final chats = items
          .whereType<Map>()
          .map(
            (j) => Chat.fromJson(Map<String, dynamic>.from(j), _currentUserId),
          )
          .toList();
      state = state.copyWith(chats: chats, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Find or create a chat with a participant. Returns the chatId.
  Future<String?> findOrCreateChat({
    required String participantId,
    String? listingId,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.chats,
        data: {
          'participantId': participantId,
          if (listingId != null) 'listingId': listingId,
        },
      );
      final raw = response.data;
      if (raw is Map) {
        final chat = Chat.fromJson(
          Map<String, dynamic>.from(raw),
          _currentUserId,
        );
        // Add to list if not already there
        final chats = [...state.chats];
        final idx = chats.indexWhere((c) => c.id == chat.id);
        if (idx >= 0) {
          chats[idx] = chat.copyWith(messages: chats[idx].messages);
        } else {
          chats.insert(0, chat);
        }
        state = state.copyWith(chats: chats);
        return chat.id;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
    return null;
  }

  Future<void> loadMessages(String chatId, {bool loadMore = false}) async {
    // Wait for fetchChats to finish if it's still running
    if (state.isLoading) {
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!state.isLoading) break;
      }
    }

    final chats = [...state.chats];
    final idx = chats.indexWhere((c) => c.id == chatId);
    if (idx < 0) return;

    final chat = chats[idx];
    if (chat.isLoadingMessages) return;
    if (loadMore && !chat.hasMoreMessages) return;

    final page = loadMore ? chat.messagesPage + 1 : 1;

    chats[idx] = chat.copyWith(isLoadingMessages: true);
    state = state.copyWith(chats: chats);

    try {
      final response = await apiClient.get(
        '${ApiEndpoints.chats}/$chatId/messages',
        queryParameters: {'page': page, 'limit': 50},
      );

      final raw = response.data;
      print('[CHAT] loadMessages raw type: ${raw.runtimeType}');
      print('[CHAT] loadMessages raw: $raw');

      List<dynamic> items = [];
      int total = 0;
      if (raw is Map) {
        // Try multiple possible shapes
        final possibleList = raw['data'] ?? raw['messages'] ?? raw['items'];
        if (possibleList is List) {
          items = possibleList;
        }
        total = (raw['total'] ?? raw['count'] ?? items.length) as int;
      } else if (raw is List) {
        items = raw;
        total = items.length;
      }

      print('[CHAT] parsed ${items.length} messages, total=$total');

      final newMessages = items
          .whereType<Map>()
          .map(
            (j) => ChatMessage.fromJson(
              Map<String, dynamic>.from(j),
              _currentUserId,
            ),
          )
          .toList();

      final updatedChats = [...state.chats];
      final updatedIdx = updatedChats.indexWhere((c) => c.id == chatId);
      if (updatedIdx < 0) return;

      final current = updatedChats[updatedIdx];
      final allMessages = loadMore
          ? [...newMessages, ...current.messages]
          : newMessages;

      updatedChats[updatedIdx] = current.copyWith(
        messages: allMessages,
        messagesPage: page,
        hasMoreMessages: allMessages.length < total,
        isLoadingMessages: false,
      );
      state = state.copyWith(chats: updatedChats);
    } catch (e) {
      print('[CHAT] loadMessages error: $e');
      final updatedChats = [...state.chats];
      final updatedIdx = updatedChats.indexWhere((c) => c.id == chatId);
      if (updatedIdx >= 0) {
        updatedChats[updatedIdx] = updatedChats[updatedIdx].copyWith(
          isLoadingMessages: false,
        );
        state = state.copyWith(chats: updatedChats);
      }
    }
  }

  // ── Socket actions ────────────────────────────────────────────────────────

  void joinChat(String chatId) {
    _socket.joinChat(chatId);
    markAsRead(chatId);
  }

  void leaveChat(String chatId) {
    _socket.leaveChat(chatId);
  }

  void sendMessage(String chatId, String text) {
    // Send via socket
    _socket.sendMessage(chatId, text);

    // Optimistic local insert
    final msg = ChatMessage(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      senderId: _currentUserId,
      text: text,
      isSent: true,
      timestamp: DateTime.now(),
    );

    final chats = [...state.chats];
    final idx = chats.indexWhere((c) => c.id == chatId);
    if (idx >= 0) {
      final chat = chats[idx];
      chats[idx] = chat.copyWith(
        messages: [...chat.messages, msg],
        lastMessage: text,
        lastMessageAt: DateTime.now(),
      );
      state = state.copyWith(chats: chats);
    }
  }

  void emitTyping(String chatId) {
    _socket.emitTyping(chatId);
  }

  Future<void> markAsRead(String chatId) async {
    try {
      await apiClient.patch('${ApiEndpoints.chats}/$chatId/read');
      final chats = [...state.chats];
      final idx = chats.indexWhere((c) => c.id == chatId);
      if (idx >= 0) {
        chats[idx] = chats[idx].copyWith(unreadCount: 0);
        state = state.copyWith(chats: chats);
      }
    } catch (_) {}
  }

  Future<void> deleteChat(String chatId) async {
    // Optimistic remove
    final original = [...state.chats];
    state = state.copyWith(
      chats: state.chats.where((c) => c.id != chatId).toList(),
    );
    try {
      await apiClient.delete('${ApiEndpoints.chats}/$chatId');
    } catch (_) {
      // Revert on failure
      state = state.copyWith(chats: original);
    }
  }
}

final chatsProvider = NotifierProvider<ChatsNotifier, ChatsState>(
  ChatsNotifier.new,
);

// Helper: get a single chat by ID
final chatByIdProvider = Provider.family<Chat?, String>((ref, id) {
  final chatsState = ref.watch(chatsProvider);
  try {
    return chatsState.chats.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});
