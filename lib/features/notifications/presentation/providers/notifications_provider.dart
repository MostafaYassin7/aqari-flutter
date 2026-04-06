import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/socket_service.dart';

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

  static NotificationType fromString(String type) {
    switch (type) {
      case 'new_message':
        return NotificationType.message;
      case 'payment_confirmed':
        return NotificationType.payment;
      case 'booking':
        return NotificationType.booking;
      case 'listing_approved':
        return NotificationType.listingApproved;
      case 'listing_rejected':
        return NotificationType.listingRejected;
      case 'search_alert':
        return NotificationType.searchAlert;
      default:
        return NotificationType.system;
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
  final String? referenceType;
  final String? referenceId;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.actionRoute,
    this.photoUrl,
    this.referenceType,
    this.referenceId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final type = NotificationTypeX.fromString(json['type'] ?? '');
    final refType = json['referenceType'] as String?;
    final refId = json['referenceId'] as String?;

    String? actionRoute;
    if (refType == 'chat' && refId != null) {
      actionRoute = '/chat/$refId';
    } else if (refType == 'payment') {
      actionRoute = '/account';
    }

    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: type,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      timestamp: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isRead: json['isRead'] == true,
      actionRoute: actionRoute,
      referenceType: refType,
      referenceId: refId,
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    timestamp: timestamp,
    isRead: isRead ?? this.isRead,
    actionRoute: actionRoute,
    photoUrl: photoUrl,
    referenceType: referenceType,
    referenceId: referenceId,
  );
}

// ── State ─────────────────────────────────────────────────────────────────────

class NotificationsState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;
  final int page;
  final int total;
  final bool hasMore;
  final int unreadCount;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.total = 0,
    this.hasMore = true,
    this.unreadCount = 0,
  });

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
    int? page,
    int? total,
    bool? hasMore,
    int? unreadCount,
  }) => NotificationsState(
    notifications: notifications ?? this.notifications,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    page: page ?? this.page,
    total: total ?? this.total,
    hasMore: hasMore ?? this.hasMore,
    unreadCount: unreadCount ?? this.unreadCount,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class NotificationsNotifier extends Notifier<NotificationsState> {
  static const _limit = 20;
  bool _socketRegistered = false;

  @override
  NotificationsState build() {
    // Schedule fetch after build() returns initial state
    Future.microtask(() {
      fetchNotifications();
      fetchUnreadCount();
    });
    _registerSocket();
    return const NotificationsState();
  }

  void _registerSocket() {
    if (_socketRegistered) return;
    _socketRegistered = true;
    SocketService().onNewNotification((data) {
      final n = AppNotification.fromJson(data);
      state = state.copyWith(
        notifications: [n, ...state.notifications],
        unreadCount: state.unreadCount + 1,
        total: state.total + 1,
      );
    });
  }

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.page;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final res = await apiClient.get(
        ApiEndpoints.notifications,
        queryParameters: {'page': page, 'limit': _limit},
      );
      print(
        '[NOTIF] fetchNotifications raw res.data type=${res.data.runtimeType}',
      );
      print('[NOTIF] fetchNotifications raw res.data=${res.data}');

      // After interceptor unwrap: could be {data: [...], total, page}
      // or the list directly depending on shape
      List<dynamic> rawList;
      int total;

      if (res.data is List) {
        rawList = res.data as List;
        total = rawList.length;
      } else {
        final body = res.data as Map<String, dynamic>;
        rawList = (body['data'] as List?) ?? [];
        total = body['total'] as int? ?? rawList.length;
      }

      final list = rawList
          .map((j) => AppNotification.fromJson(j as Map<String, dynamic>))
          .toList();
      print('[NOTIF] Parsed ${list.length} notifications, total=$total');

      state = state.copyWith(
        notifications: refresh ? list : [...state.notifications, ...list],
        isLoading: false,
        page: page + 1,
        total: total,
        hasMore:
            (refresh ? list.length : state.notifications.length + list.length) <
            total,
      );
    } catch (e, st) {
      print('[NOTIF] fetchNotifications ERROR: $e');
      print('[NOTIF] Stack: $st');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final res = await apiClient.get(ApiEndpoints.notificationsUnreadCount);
      print('[NOTIF] unread-count raw res.data=${res.data}');
      // After interceptor unwrap: {count: 7} or just a number
      if (res.data is Map) {
        final body = res.data as Map<String, dynamic>;
        state = state.copyWith(unreadCount: body['count'] as int? ?? 0);
      } else if (res.data is int) {
        state = state.copyWith(unreadCount: res.data as int);
      }
    } catch (e) {
      print('[NOTIF] fetchUnreadCount ERROR: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    // Optimistic update
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == id && !n.isRead ? n.copyWith(isRead: true) : n)
          .toList(),
      unreadCount: (state.unreadCount - 1).clamp(0, state.total),
    );
    try {
      await apiClient.patch('${ApiEndpoints.notifications}/$id/read');
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList(),
      unreadCount: 0,
    );
    try {
      await apiClient.patch('${ApiEndpoints.notifications}/read-all');
    } catch (_) {}
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await fetchNotifications();
  }

  Future<void> refresh() async {
    await fetchNotifications(refresh: true);
    await fetchUnreadCount();
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
      NotificationsNotifier.new,
    );

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});
