import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class ChatContact {
  final String id;
  final String name;
  final String photoUrl;
  final bool isOnline;
  final String adNumber;
  final String propertyTitle;
  final String propertyImageUrl;
  final String propertyId;

  const ChatContact({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.isOnline,
    required this.adNumber,
    required this.propertyTitle,
    required this.propertyImageUrl,
    required this.propertyId,
  });
}

class ChatMessage {
  final String id;
  final String text;
  final bool isSent; // true = sent by me
  final DateTime timestamp;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isSent,
    required this.timestamp,
    this.isRead = true,
  });
}

class Chat {
  final String id;
  final ChatContact contact;
  final List<ChatMessage> messages;
  final int unreadCount;

  const Chat({
    required this.id,
    required this.contact,
    required this.messages,
    this.unreadCount = 0,
  });

  String get lastMessageText =>
      messages.isNotEmpty ? messages.last.text : '';

  DateTime? get lastMessageTime =>
      messages.isNotEmpty ? messages.last.timestamp : null;

  Chat copyWith({
    List<ChatMessage>? messages,
    int? unreadCount,
  }) =>
      Chat(
        id: id,
        contact: contact,
        messages: messages ?? this.messages,
        unreadCount: unreadCount ?? this.unreadCount,
      );
}

// ── Mock data ─────────────────────────────────────────────────────────────────

final _now = DateTime.now();

List<Chat> _buildMockChats() {
  return [
    Chat(
      id: 'chat_01',
      contact: const ChatContact(
        id: 'c1',
        name: 'أحمد المطيري',
        photoUrl: 'https://picsum.photos/seed/chat_c1/200/200',
        isOnline: true,
        adNumber: 'AD-100234',
        propertyTitle: 'شقة فاخرة في حي العليا',
        propertyImageUrl: 'https://picsum.photos/seed/apt1riyadh/300/200',
        propertyId: 'apt_01',
      ),
      messages: [
        ChatMessage(
          id: 'm1_1',
          text: 'السلام عليكم، هل الشقة لا تزال متاحة؟',
          isSent: false,
          timestamp: _now.subtract(const Duration(hours: 2, minutes: 30)),
        ),
        ChatMessage(
          id: 'm1_2',
          text: 'وعليكم السلام، نعم الشقة متاحة',
          isSent: true,
          timestamp: _now.subtract(const Duration(hours: 2, minutes: 25)),
        ),
        ChatMessage(
          id: 'm1_3',
          text: 'هل يمكن تحديد موعد للمعاينة غداً؟',
          isSent: false,
          timestamp: _now.subtract(const Duration(hours: 2, minutes: 10)),
        ),
        ChatMessage(
          id: 'm1_4',
          text: 'بالتأكيد، ما هو الوقت المناسب لك؟',
          isSent: true,
          timestamp: _now.subtract(const Duration(hours: 2)),
        ),
        ChatMessage(
          id: 'm1_5',
          text: 'العاشرة صباحاً إن كان مناسباً',
          isSent: false,
          timestamp: _now.subtract(const Duration(minutes: 15)),
          isRead: false,
        ),
      ],
      unreadCount: 1,
    ),
    Chat(
      id: 'chat_02',
      contact: const ChatContact(
        id: 'c2',
        name: 'منيرة الزهراني',
        photoUrl: 'https://picsum.photos/seed/chat_c2/200/200',
        isOnline: false,
        adNumber: 'AD-100891',
        propertyTitle: 'فيلا مع مسبح - حي الياسمين',
        propertyImageUrl: 'https://picsum.photos/seed/ml02/300/200',
        propertyId: 'apt_02',
      ),
      messages: [
        ChatMessage(
          id: 'm2_1',
          text: 'هل السعر قابل للتفاوض؟',
          isSent: false,
          timestamp: _now.subtract(const Duration(days: 1, hours: 3)),
        ),
        ChatMessage(
          id: 'm2_2',
          text: 'السعر نهائي، لكن يمكن التقسيط على سنتين',
          isSent: true,
          timestamp: _now.subtract(const Duration(days: 1, hours: 2)),
        ),
        ChatMessage(
          id: 'm2_3',
          text: 'شكراً سأتشاور مع العائلة وأرد عليك',
          isSent: false,
          timestamp: _now.subtract(const Duration(days: 1, hours: 1)),
        ),
      ],
      unreadCount: 0,
    ),
    Chat(
      id: 'chat_03',
      contact: const ChatContact(
        id: 'c3',
        name: 'فيصل العتيبي',
        photoUrl: 'https://picsum.photos/seed/chat_c3/200/200',
        isOnline: true,
        adNumber: 'AD-100456',
        propertyTitle: 'أرض سكنية في حي الملقا',
        propertyImageUrl: 'https://picsum.photos/seed/ml03/300/200',
        propertyId: 'apt_03',
      ),
      messages: [
        ChatMessage(
          id: 'm3_1',
          text: 'ما هي مساحة الأرض تحديداً؟',
          isSent: false,
          timestamp: _now.subtract(const Duration(days: 2)),
        ),
        ChatMessage(
          id: 'm3_2',
          text: '٦٠٠ متر مربع، شارع ١٥ متر شمالي',
          isSent: true,
          timestamp: _now.subtract(const Duration(days: 2)).add(
              const Duration(minutes: 10)),
        ),
        ChatMessage(
          id: 'm3_3',
          text: 'جزاك الله خير',
          isSent: false,
          timestamp: _now.subtract(const Duration(days: 2)).add(
              const Duration(minutes: 20)),
          isRead: false,
        ),
        ChatMessage(
          id: 'm3_4',
          text: 'هل المخطط معتمد؟',
          isSent: false,
          timestamp: _now.subtract(const Duration(days: 1, hours: 18)),
          isRead: false,
        ),
      ],
      unreadCount: 2,
    ),
    Chat(
      id: 'chat_04',
      contact: const ChatContact(
        id: 'c4',
        name: 'هيفاء الشمري',
        photoUrl: 'https://picsum.photos/seed/chat_c4/200/200',
        isOnline: false,
        adNumber: 'AD-100312',
        propertyTitle: 'شقة للإيجار - النزهة',
        propertyImageUrl: 'https://picsum.photos/seed/ml04/300/200',
        propertyId: 'apt_04',
      ),
      messages: [
        ChatMessage(
          id: 'm4_1',
          text: 'هل الشقة مفروشة؟',
          isSent: false,
          timestamp: _now.subtract(const Duration(days: 3)),
        ),
        ChatMessage(
          id: 'm4_2',
          text: 'نعم مفروشة بالكامل مع جميع الأجهزة',
          isSent: true,
          timestamp: _now.subtract(const Duration(days: 3)).add(
              const Duration(minutes: 5)),
        ),
      ],
      unreadCount: 0,
    ),
    Chat(
      id: 'chat_05',
      contact: const ChatContact(
        id: 'c5',
        name: 'سلطان الدوسري',
        photoUrl: 'https://picsum.photos/seed/chat_c5/200/200',
        isOnline: false,
        adNumber: 'AD-100788',
        propertyTitle: 'دوبلكس حديث - حي الربيع',
        propertyImageUrl: 'https://picsum.photos/seed/ml06/300/200',
        propertyId: 'apt_05',
      ),
      messages: [
        ChatMessage(
          id: 'm5_1',
          text: 'هل يوجد موقف خاص للسيارة؟',
          isSent: false,
          timestamp: _now.subtract(const Duration(days: 5)),
        ),
        ChatMessage(
          id: 'm5_2',
          text: 'نعم يوجد موقفين خاصين',
          isSent: true,
          timestamp: _now.subtract(const Duration(days: 5)).add(
              const Duration(hours: 1)),
        ),
        ChatMessage(
          id: 'm5_3',
          text: 'ممتاز، سأتواصل معك قريباً',
          isSent: false,
          timestamp: _now.subtract(const Duration(days: 4, hours: 20)),
        ),
      ],
      unreadCount: 0,
    ),
  ];
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ChatsNotifier extends Notifier<List<Chat>> {
  @override
  List<Chat> build() => _buildMockChats();

  void deleteChat(String chatId) {
    state = state.where((c) => c.id != chatId).toList();
  }

  void sendMessage(String chatId, String text) {
    final msg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isSent: true,
      timestamp: DateTime.now(),
    );
    state = state.map((c) {
      if (c.id != chatId) return c;
      return c.copyWith(messages: [...c.messages, msg]);
    }).toList();
  }

  void markAsRead(String chatId) {
    state = state.map((c) {
      if (c.id != chatId) return c;
      return c.copyWith(unreadCount: 0);
    }).toList();
  }
}

final chatsProvider =
    NotifierProvider<ChatsNotifier, List<Chat>>(ChatsNotifier.new);

// Helper: get a single chat by ID
final chatByIdProvider = Provider.family<Chat?, String>((ref, id) {
  return ref.watch(chatsProvider).firstWhere(
        (c) => c.id == id,
        orElse: () => throw Exception('Chat not found'),
      );
});
