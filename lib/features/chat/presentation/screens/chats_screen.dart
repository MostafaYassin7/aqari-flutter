import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../providers/chat_provider.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(chatsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'الرسائل',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.dividerLight),
        ),
      ),
      body: chats.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              itemCount: chats.length,
              separatorBuilder: (_, __) => const Padding(
                padding: EdgeInsetsDirectional.only(
                    start: AppConstants.spaceM + 60),
                child: Divider(height: 1, color: AppColors.dividerLight),
              ),
              itemBuilder: (_, i) => _SwipeableChatRow(
                chat: chats[i],
                onDelete: () =>
                    ref.read(chatsProvider.notifier).deleteChat(chats[i].id),
                onTap: () {
                  ref.read(chatsProvider.notifier).markAsRead(chats[i].id);
                  context.push('/chat/${chats[i].id}');
                },
              ),
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}

// ── Swipeable chat row ────────────────────────────────────────────────────────

class _SwipeableChatRow extends StatefulWidget {
  final Chat chat;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  const _SwipeableChatRow({
    required this.chat,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<_SwipeableChatRow> createState() => _SwipeableChatRowState();
}

class _SwipeableChatRowState extends State<_SwipeableChatRow>
    with SingleTickerProviderStateMixin {
  static const double _actionWidth = 80.0;
  late final AnimationController _ctrl;
  late final Animation<double> _offsetAnim;
  double _dragStart = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _offsetAnim = Tween<double>(begin: 0, end: -_actionWidth).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails d) => _dragStart = d.localPosition.dx;

  void _onDragUpdate(DragUpdateDetails d) {
    final delta = d.localPosition.dx - _dragStart;
    _dragStart = d.localPosition.dx;
    _ctrl.value = (_ctrl.value + delta / -_actionWidth).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails d) {
    if (d.velocity.pixelsPerSecond.dx < -300 || _ctrl.value > 0.5) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  void _close() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Stack(
        children: [
          // Delete action
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    _close();
                    widget.onDelete();
                  },
                  child: Container(
                    width: _actionWidth,
                    color: AppColors.error,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete_rounded,
                            color: AppColors.white, size: 22),
                        const SizedBox(height: 4),
                        Text(
                          'حذف',
                          style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Row content
          AnimatedBuilder(
            animation: _offsetAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(_offsetAnim.value, 0),
              child: child,
            ),
            child: GestureDetector(
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              onTap: () {
                if (_ctrl.value > 0) {
                  _close();
                } else {
                  widget.onTap();
                }
              },
              child: Container(
                color: AppColors.backgroundLight,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spaceM, vertical: 12),
                child: _ChatRowContent(chat: widget.chat),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatRowContent extends StatelessWidget {
  final Chat chat;
  const _ChatRowContent({required this.chat});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Avatar with online dot ────────────────────────
        Stack(
          children: [
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: chat.contact.photoUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 52,
                  height: 52,
                  color: AppColors.primaryLight,
                  child: const Icon(Icons.person_rounded,
                      color: AppColors.primary, size: 26),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 52,
                  height: 52,
                  color: AppColors.primaryLight,
                  child: const Icon(Icons.person_rounded,
                      color: AppColors.primary, size: 26),
                ),
              ),
            ),
            if (chat.contact.isOnline)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.backgroundLight, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),

        // ── Name + preview ────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      chat.contact.name,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: chat.unreadCount > 0
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  Text(
                    _formatTime(chat.lastMessageTime),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: chat.unreadCount > 0
                          ? AppColors.primary
                          : AppColors.textSecondaryLight,
                      fontWeight: chat.unreadCount > 0
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                chat.contact.adNumber,
                style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textHintLight),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      chat.lastMessageText,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: chat.unreadCount > 0
                            ? AppColors.textPrimaryLight
                            : AppColors.textSecondaryLight,
                        fontWeight: chat.unreadCount > 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (chat.unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${chat.unreadCount}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes}د';
    if (diff.inDays < 1) {
      final h = time.hour;
      final m = time.minute.toString().padLeft(2, '0');
      final amPm = h < 12 ? 'ص' : 'م';
      final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$h12:$m $amPm';
    }
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays}أيام';
    return '${time.day}/${time.month}';
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spaceXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 80, color: AppColors.dividerLight),
              const SizedBox(height: 16),
              Text(
                'لا توجد رسائل بعد',
                style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'تفضّل بتصفح الإعلانات للتواصل مع المُعلنين',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(200, AppConstants.buttonHeight),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusM)),
                  elevation: 0,
                ),
                child: Text('تصفّح الإعلانات',
                    style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
}
