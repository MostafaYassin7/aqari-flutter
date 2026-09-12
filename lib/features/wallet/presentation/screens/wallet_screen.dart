import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/wallet_provider.dart';
import '../../../../core/preview/ui_preview.dart';
import 'payment_preview_sheet.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  bool _zeroPreview = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !uiPreview) {
      ref.read(walletProvider.notifier).refresh();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(walletProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final visible = wallet.transactions;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: RefreshIndicator(
        onRefresh: () => ref.read(walletProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _scrollController,
          slivers: [
            // ── App bar ────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: context.appColors.background,
              elevation: 0,
              scrolledUnderElevation: 0,
              pinned: true,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 20,
                  color: context.appColors.textPrimary,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Text(
                'المحفظة',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
              ),
              centerTitle: true,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: context.appColors.divider),
              ),
            ),

            // ── Balance card ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spaceM,
                  AppConstants.spaceM,
                  AppConstants.spaceM,
                  AppConstants.spaceS,
                ),
                child: _BalanceCard(
                  balance: wallet.balance,
                  onTopUp: () => _showTopUpSheet(context, ref),
                ),
              ),
            ),

            if (uiPreview) const SliverToBoxAdapter(child: PreviewNotice()),
            if (!_zeroPreview &&
                (wallet.heldBalance > 0 || wallet.pendingEarnings > 0))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PreviewSection(
                    title: 'ملخص الحجوزات',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (wallet.heldBalance > 0) ...[
                          Text('رصيد محجوز', style: AppTextStyles.bodyMedium),
                          Text(
                            '${wallet.heldBalance.toStringAsFixed(2)} ريال',
                            style: AppTextStyles.titleLarge,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (wallet.pendingEarnings > 0) ...[
                          Text(
                            'أرباح قيد الانتظار',
                            style: AppTextStyles.bodyMedium,
                          ),
                          Text(
                            '${wallet.pendingEarnings.toStringAsFixed(2)} ريال',
                            style: AppTextStyles.titleLarge,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            if (uiPreview)
              SliverToBoxAdapter(
                child: TextButton(
                  onPressed: () => setState(() => _zeroPreview = !_zeroPreview),
                  child: Text(
                    _zeroPreview
                        ? 'عرض الأرصدة التجريبية'
                        : 'معاينة أرصدة صفرية',
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: _DirectionChips(
                current: wallet.direction,
                onSelected: (value) =>
                    ref.read(walletProvider.notifier).setDirection(value),
              ),
            ),
            // ── Section title + filter chips ───────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spaceM,
                  AppConstants.spaceM,
                  AppConstants.spaceM,
                  AppConstants.spaceS,
                ),
                child: Text(
                  'سجل المعاملات',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(child: _FilterChips(current: wallet.filter)),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            if (wallet.error != null)
              SliverToBoxAdapter(
                child: TextButton(
                  onPressed: () => ref.read(walletProvider.notifier).refresh(),
                  child: Text('${wallet.error} · إعادة المحاولة'),
                ),
              ),
            // ── Transactions ───────────────────────────────────────
            if (wallet.isLoading && visible.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (visible.isEmpty)
              const SliverFillRemaining(child: _EmptyFilter())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spaceM,
                  0,
                  AppConstants.spaceM,
                  AppConstants.spaceXL,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final txList = visible;

                      // Loading indicator at the bottom
                      if (i == txList.length) {
                        return wallet.hasMore
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      }

                      // Show month header when month changes
                      final tx = txList[i];
                      final prev = i > 0 ? txList[i - 1] : null;
                      final showHeader =
                          prev == null ||
                          _monthKey(tx.dateTime) != _monthKey(prev.dateTime);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHeader) _MonthHeader(dateTime: tx.dateTime),
                          _TransactionRow(transaction: tx),
                          if (i < txList.length - 1)
                            Divider(
                              height: 1,
                              color: context.appColors.divider,
                              indent: 60,
                            ),
                        ],
                      );
                    },
                    childCount: visible.length + (wallet.isLoadingMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _monthKey(DateTime d) => '${d.year}-${d.month}';

  void _showTopUpSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      builder: (_) => const PaymentPreviewSheet(),
    );
  }
}

// ── Balance card ──────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final double balance;
  final VoidCallback onTopUp;

  const _BalanceCard({required this.balance, required this.onTopUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Label + wallet icon ──────────────────────────
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'رصيد المحفظة',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Balance amount ───────────────────────────────
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: _formatBalance(balance),
                  style: AppTextStyles.displayLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: '  ريال',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Divider ──────────────────────────────────────
          Divider(color: AppColors.white.withValues(alpha: 0.12), height: 1),

          const SizedBox(height: 20),

          // ── Top-up button ────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onTopUp,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'شحن المحفظة',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBalance(double v) {
    if (v >= 1000) {
      final parts = v.toStringAsFixed(0).split('');
      final buf = StringBuffer();
      for (int i = 0; i < parts.length; i++) {
        if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
        buf.write(parts[i]);
      }
      return buf.toString();
    }
    return v.toStringAsFixed(0);
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChips extends ConsumerWidget {
  final TransactionFilter current;
  const _FilterChips({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
        children: TransactionFilter.values.map((f) {
          final isActive = f == current;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: GestureDetector(
              onTap: () => ref.read(walletProvider.notifier).setFilter(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : context.appColors.background,
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusCircle,
                  ),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary
                        : context.appColors.divider,
                  ),
                ),
                child: Text(
                  f.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isActive
                        ? AppColors.onPrimary
                        : context.appColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DirectionChips extends StatelessWidget {
  final String current;
  final ValueChanged<String> onSelected;
  const _DirectionChips({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
        children: {'all': 'كل الحركات', 'credit': 'إيداع', 'debit': 'سحب'}
            .entries
            .map((f) {
              final isActive = f.key == current;
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: GestureDetector(
                  onTap: () => onSelected(f.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : context.appColors.background,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusCircle,
                      ),
                      border: Border.all(
                        color: isActive
                            ? AppColors.primary
                            : context.appColors.divider,
                      ),
                    ),
                    child: Text(
                      f.value,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isActive
                            ? AppColors.onPrimary
                            : context.appColors.textSecondary,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(),
      ),
    );
  }
}

// ── Month header ──────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  final DateTime dateTime;
  const _MonthHeader({required this.dateTime});

  @override
  Widget build(BuildContext context) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    final label = '${months[dateTime.month - 1]} ${dateTime.year}';

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: context.appColors.textHint,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Transaction row ───────────────────────────────────────────────────────────

class _TransactionRow extends StatelessWidget {
  final WalletTransaction transaction;
  const _TransactionRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final isCredit = tx.isCredit;

    return Container(
      color: context.appColors.background,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          // ── Icon ──────────────────────────────────────
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tx.type.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Icon(tx.type.icon, color: tx.type.color, size: 22),
          ),
          const SizedBox(width: 12),

          // ── Description + date ─────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDateTime(tx.dateTime),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.appColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Amount ────────────────────────────────────
          Text(
            '${isCredit
                ? '+'
                : tx.isDebit
                ? '−'
                : ''}${tx.amount.abs().toStringAsFixed(2)} ر.س',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: isCredit
                  ? AppColors.success
                  : tx.isDebit
                  ? AppColors.error
                  : context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final amPm = h < 12 ? 'ص' : 'م';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final time = '$h12:$m $amPm';

    if (diff.inDays == 0) return 'اليوم · $time';
    if (diff.inDays == 1) return 'أمس · $time';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام · $time';
    return '${dt.day}/${dt.month}/${dt.year} · $time';
  }
}

// ── Empty filter state ────────────────────────────────────────────────────────

class _EmptyFilter extends StatelessWidget {
  const _EmptyFilter();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 56,
            color: context.appColors.divider,
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد معاملات',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
