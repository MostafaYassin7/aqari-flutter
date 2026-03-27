import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Notification type ─────────────────────────────────────────────────────────

enum NotificationType {
  message,
  booking,
  listingApproved,
  listingRejected,
  searchAlert,
  payment,
  system,
}

extension NotificationTypeX on NotificationType {
  IconData get icon {
    switch (this) {
      case NotificationType.message:
        return Icons.chat_rounded;
      case NotificationType.booking:
        return Icons.calendar_month_rounded;
      case NotificationType.listingApproved:
        return Icons.check_circle_rounded;
      case NotificationType.listingRejected:
        return Icons.cancel_rounded;
      case NotificationType.searchAlert:
        return Icons.search_rounded;
      case NotificationType.payment:
        return Icons.account_balance_wallet_rounded;
      case NotificationType.system:
        return Icons.notifications_rounded;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.message:
        return const Color(0xFFF5A623);
      case NotificationType.booking:
        return const Color(0xFF2196F3);
      case NotificationType.listingApproved:
        return const Color(0xFF00A699);
      case NotificationType.listingRejected:
        return const Color(0xFFFF5A5F);
      case NotificationType.searchAlert:
        return const Color(0xFFF5A623);
      case NotificationType.payment:
        return const Color(0xFF00A699);
      case NotificationType.system:
        return const Color(0xFF717171);
    }
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String? actionRoute;
  final String? photoUrl;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.actionRoute,
    this.photoUrl,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        timestamp: timestamp,
        isRead: isRead ?? this.isRead,
        actionRoute: actionRoute,
        photoUrl: photoUrl,
      );
}

// ── Mock data ─────────────────────────────────────────────────────────────────

final _now = DateTime.now();

final _mockNotifications = <AppNotification>[
  AppNotification(
    id: 'n1',
    type: NotificationType.message,
    title: 'رسالة جديدة من أحمد المطيري',
    body: 'العاشرة صباحاً إن كان مناسباً',
    timestamp: _now.subtract(const Duration(minutes: 15)),
    isRead: false,
    actionRoute: '/chat/chat_01',
    photoUrl: 'https://picsum.photos/seed/chat_c1/200/200',
  ),
  AppNotification(
    id: 'n2',
    type: NotificationType.booking,
    title: 'طلب حجز جديد',
    body: 'فيصل العتيبي يطلب حجز شقتك في حي العليا ليلتين',
    timestamp: _now.subtract(const Duration(hours: 1, minutes: 30)),
    isRead: false,
    actionRoute: '/my-listings',
    photoUrl: 'https://picsum.photos/seed/chat_c3/200/200',
  ),
  AppNotification(
    id: 'n3',
    type: NotificationType.listingApproved,
    title: 'تمت الموافقة على إعلانك',
    body: 'إعلان "شقة فاخرة في حي العليا" قيد النشر الآن',
    timestamp: _now.subtract(const Duration(hours: 3)),
    isRead: false,
    actionRoute: '/my-listings',
  ),
  AppNotification(
    id: 'n4',
    type: NotificationType.searchAlert,
    title: 'تنبيه بحث مطابق',
    body: 'تم إضافة 3 عقارات جديدة تطابق بحثك عن "فيلا الرياض"',
    timestamp: _now.subtract(const Duration(hours: 5)),
    isRead: false,
    actionRoute: '/search',
  ),
  AppNotification(
    id: 'n5',
    type: NotificationType.payment,
    title: 'تم تأكيد الدفع',
    body: 'تم استلام دفعة ١٢٥٠ ريال في محفظتك بنجاح',
    timestamp: _now.subtract(const Duration(hours: 8)),
    isRead: true,
    actionRoute: '/account',
  ),
  AppNotification(
    id: 'n6',
    type: NotificationType.message,
    title: 'رسالة جديدة من منيرة الزهراني',
    body: 'شكراً سأتشاور مع العائلة وأرد عليك',
    timestamp: _now.subtract(const Duration(days: 1, hours: 2)),
    isRead: true,
    actionRoute: '/chat/chat_02',
    photoUrl: 'https://picsum.photos/seed/chat_c2/200/200',
  ),
  AppNotification(
    id: 'n7',
    type: NotificationType.listingRejected,
    title: 'إعلانك بحاجة إلى مراجعة',
    body: 'إعلان "محل تجاري - طريق الملك فهد" يحتاج إلى تحديث الصور',
    timestamp: _now.subtract(const Duration(days: 2)),
    isRead: true,
    actionRoute: '/my-listings',
  ),
  AppNotification(
    id: 'n8',
    type: NotificationType.system,
    title: 'تحديث جديد متاح',
    body: 'تم إضافة ميزة البحث بالخريطة وتحسينات عديدة في الإصدار 2.0',
    timestamp: _now.subtract(const Duration(days: 3)),
    isRead: true,
  ),
  AppNotification(
    id: 'n9',
    type: NotificationType.booking,
    title: 'تذكير: موعد معاينة غداً',
    body: 'لديك معاينة مع هيفاء الشمري الساعة العاشرة صباحاً',
    timestamp: _now.subtract(const Duration(days: 4)),
    isRead: true,
    actionRoute: '/my-listings',
    photoUrl: 'https://picsum.photos/seed/chat_c4/200/200',
  ),
  AppNotification(
    id: 'n10',
    type: NotificationType.system,
    title: 'مرحباً بك في عقار!',
    body: 'أكمل ملفك الشخصي للحصول على تجربة أفضل وظهور أكثر',
    timestamp: _now.subtract(const Duration(days: 7)),
    isRead: true,
    actionRoute: '/account',
  ),
];

// ── Notifier ──────────────────────────────────────────────────────────────────

class NotificationsNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() => List.from(_mockNotifications);

  void markAsRead(String id) {
    state = state
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
  }

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<AppNotification>>(
        NotificationsNotifier.new);

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.isRead).length;
});
