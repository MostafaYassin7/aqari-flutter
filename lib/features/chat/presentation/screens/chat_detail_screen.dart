import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/chat_provider.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;
  const ChatDetailScreen({required this.chatId, super.key});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _canSend = false;
  bool _disposed = false;
  late final ChatsNotifier _notifier;

  @override
  void initState() {
    super.initState();
    // Cache notifier once — never call ref.read() after this
    _notifier = ref.read(chatsProvider.notifier);

    _textCtrl.addListener(() {
      if (_disposed) return;
      final canSend = _textCtrl.text.trim().isNotEmpty;
      if (canSend != _canSend) setState(() => _canSend = canSend);
    });
    _scrollCtrl.addListener(_onScroll);
    // Join socket room, load messages, mark as read
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      _notifier.joinChat(widget.chatId);
      _notifier.loadMessages(widget.chatId);
    });
  }

  void _onScroll() {
    if (_disposed) return;
    if (_scrollCtrl.position.pixels <= 50) {
      _notifier.loadMessages(widget.chatId, loadMore: true);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _scrollCtrl.removeListener(_onScroll);
    _notifier.leaveChat(widget.chatId);
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    if (_disposed || !_scrollCtrl.hasClients) return;
    if (animate) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    }
  }

  void _sendMessage() {
    if (_disposed) return;
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _notifier.sendMessage(widget.chatId, text);
    _textCtrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatByIdProvider(widget.chatId));
    if (chat == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              size: 20,
              color: AppColors.textPrimaryLight,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final chatsState = ref.watch(chatsProvider);
    final isTyping =
        chatsState.typingChatId == widget.chatId &&
        (chatsState.typingExpiry?.isAfter(DateTime.now()) ?? false);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(context, chat),
      body: Column(
        children: [
          // ── Messages list ─────────────────────────────────
          Expanded(
            child: _MessagesList(
              messages: chat.messages,
              scrollController: _scrollCtrl,
              isLoadingMore: chat.isLoadingMessages,
            ),
          ),

          // ── Typing indicator ──────────────────────────────
          if (isTyping)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppConstants.spaceM,
                bottom: 4,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'يكتب...',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ),

          // ── Input bar ─────────────────────────────────────
          _InputBar(
            controller: _textCtrl,
            canSend: _canSend,
            onSend: _sendMessage,
            onChanged: () => _notifier.emitTyping(widget.chatId),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, Chat chat) {
    return AppBar(
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_rounded,
          size: 20,
          color: AppColors.textPrimaryLight,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Row(
        children: [
          // Avatar
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: chat.contact.photoUrl,
              width: 38,
              height: 38,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 38,
                height: 38,
                color: AppColors.primaryLight,
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 38,
                height: 38,
                color: AppColors.primaryLight,
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name
          Expanded(
            child: Text(
              chat.contact.name,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (chat.listingId != null && chat.listingId!.isNotEmpty)
          IconButton(
            icon: const Icon(
              Icons.home_rounded,
              color: AppColors.textSecondaryLight,
              size: 22,
            ),
            onPressed: () => context.push('/property/${chat.listingId}'),
          ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.dividerLight),
      ),
    );
  }
}

// ── Messages list ─────────────────────────────────────────────────────────────

class _MessagesList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final bool isLoadingMore;
  const _MessagesList({
    required this.messages,
    required this.scrollController,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'ابدأ المحادثة',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceM,
        vertical: AppConstants.spaceM,
      ),
      itemCount: messages.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (isLoadingMore && i == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final msgIndex = isLoadingMore ? i - 1 : i;
        final msg = messages[msgIndex];
        final prev = msgIndex > 0 ? messages[msgIndex - 1] : null;
        final next = msgIndex < messages.length - 1
            ? messages[msgIndex + 1]
            : null;

        // Show time separator if > 30 min gap from previous
        final showTimeSep =
            prev == null ||
            msg.timestamp.difference(prev.timestamp).inMinutes > 30;

        // Show timestamp below bubble if it's the last in a group
        final isLastInGroup =
            next == null ||
            next.isSent != msg.isSent ||
            next.timestamp.difference(msg.timestamp).inMinutes > 30;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTimeSep) _TimeSeparator(msg.timestamp),
            _Bubble(message: msg, showTime: isLastInGroup),
          ],
        );
      },
    );
  }
}

class _TimeSeparator extends StatelessWidget {
  final DateTime time;
  const _TimeSeparator(this.time);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(time);
    String label;
    if (diff.inDays == 0) {
      label = 'اليوم';
    } else if (diff.inDays == 1) {
      label = 'أمس';
    } else if (diff.inDays < 7) {
      const days = [
        'الأحد',
        'الاثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
      ];
      label = days[time.weekday % 7];
    } else {
      label = '${time.day}/${time.month}/${time.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.dividerLight)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.dividerLight)),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool showTime;
  const _Bubble({required this.message, required this.showTime});

  @override
  Widget build(BuildContext context) {
    final isSent = message.isSent;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: isSent ? 60 : 0,
        end: isSent ? 0 : 60,
        bottom: showTime ? 4 : 3,
      ),
      child: Column(
        crossAxisAlignment: isSent
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSent ? AppColors.primary : AppColors.surfaceLight,
              borderRadius: BorderRadiusDirectional.only(
                topStart: const Radius.circular(18),
                topEnd: const Radius.circular(18),
                bottomStart: Radius.circular(isSent ? 18 : 4),
                bottomEnd: Radius.circular(isSent ? 4 : 18),
              ),
            ),
            child: Text(
              message.text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSent ? AppColors.white : AppColors.textPrimaryLight,
                height: 1.4,
              ),
            ),
          ),

          // Timestamp below bubble group
          if (showTime) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textHintLight,
                  ),
                ),
                if (isSent) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 14,
                    color: message.isRead
                        ? AppColors.primary
                        : AppColors.textHintLight,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final amPm = h < 12 ? 'ص' : 'م';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $amPm';
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback? onChanged;
  const _InputBar({
    required this.controller,
    required this.canSend,
    required this.onSend,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spaceM,
        AppConstants.spaceS,
        AppConstants.spaceM,
        AppConstants.spaceS + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(top: BorderSide(color: AppColors.dividerLight)),
      ),
      child: Row(
        children: [
          // Text field
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              onChanged: (_) => onChanged?.call(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimaryLight,
              ),
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'اكتب رسالة...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHintLight,
                ),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusCircle,
                  ),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: canSend ? AppColors.primary : AppColors.dividerLight,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: canSend ? onSend : null,
              icon: const Icon(
                Icons.send_rounded,
                color: AppColors.white,
                size: 20,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
