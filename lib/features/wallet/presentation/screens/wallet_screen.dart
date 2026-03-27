import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/wallet_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.backgroundLight,
            elevation: 0,
            scrolledUnderElevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  size: 20, color: AppColors.textPrimaryLight),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Text(
              'المحفظة',
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
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _FilterChips(current: wallet.filter),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Transactions ───────────────────────────────────────
          wallet.filtered.isEmpty
              ? const SliverFillRemaining(child: _EmptyFilter())
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.spaceM,
                    0,
                    AppConstants.spaceM,
                    AppConstants.spaceXL,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final txList = wallet.filtered;
                        // Show month header when month changes
                        final tx = txList[i];
                        final prev = i > 0 ? txList[i - 1] : null;
                        final showHeader = prev == null ||
                            _monthKey(tx.dateTime) !=
                                _monthKey(prev.dateTime);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showHeader)
                              _MonthHeader(dateTime: tx.dateTime),
                            _TransactionRow(transaction: tx),
                            if (i < txList.length - 1)
                              const Divider(
                                  height: 1,
                                  color: AppColors.dividerLight,
                                  indent: 60),
                          ],
                        );
                      },
                      childCount: wallet.filtered.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  String _monthKey(DateTime d) => '${d.year}-${d.month}';

  void _showTopUpSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      builder: (_) => _TopUpSheet(
        onConfirm: (amount) {
          ref.read(walletProvider.notifier).topUp(amount);
        },
      ),
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
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusM),
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
          Divider(
            color: AppColors.white.withValues(alpha: 0.12),
            height: 1,
          ),

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
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimaryLight,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusM),
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
        padding:
            const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
        children: TransactionFilter.values.map((f) {
          final isActive = f == current;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: GestureDetector(
              onTap: () =>
                  ref.read(walletProvider.notifier).setFilter(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(
                      AppConstants.radiusCircle),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.dividerLight,
                  ),
                ),
                child: Text(
                  f.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isActive
                        ? AppColors.textPrimaryLight
                        : AppColors.textSecondaryLight,
                    fontWeight: isActive
                        ? FontWeight.w700
                        : FontWeight.w400,
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

// ── Month header ──────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  final DateTime dateTime;
  const _MonthHeader({required this.dateTime});

  @override
  Widget build(BuildContext context) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    final label = '${months[dateTime.month - 1]} ${dateTime.year}';

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textHintLight,
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
      color: AppColors.backgroundLight,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          // ── Icon ──────────────────────────────────────
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tx.type.color.withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusM),
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
                    color: AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDateTime(tx.dateTime),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textHintLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Amount ────────────────────────────────────
          Text(
            '${isCredit ? '+' : ''}${tx.amount.toStringAsFixed(0)} ر.س',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: isCredit
                  ? AppColors.success
                  : AppColors.error,
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
          const Icon(Icons.receipt_long_rounded,
              size: 56, color: AppColors.dividerLight),
          const SizedBox(height: 12),
          Text(
            'لا توجد معاملات',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top-up bottom sheet ───────────────────────────────────────────────────────

class _TopUpSheet extends StatefulWidget {
  final ValueChanged<double> onConfirm;
  const _TopUpSheet({required this.onConfirm});

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  static const _quickAmounts = [50.0, 100.0, 200.0, 500.0];
  static const _paymentMethods = ['بطاقة ائتمان', 'Apple Pay', 'مدى'];
  static const _paymentIcons = [
    Icons.credit_card_rounded,
    Icons.apple_rounded,
    Icons.payment_rounded,
  ];

  double? _selectedQuick;
  final _customCtrl = TextEditingController();
  int _selectedPaymentIdx = 0;
  bool _isCustomActive = false;

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  double? get _effectiveAmount {
    if (_isCustomActive) {
      final v = double.tryParse(_customCtrl.text.trim());
      return (v != null && v > 0) ? v : null;
    }
    return _selectedQuick;
  }

  void _confirm() {
    final amount = _effectiveAmount;
    if (amount == null) return;
    widget.onConfirm(amount);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم شحن ${amount.toStringAsFixed(0)} ريال بنجاح ✓',
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final canConfirm = _effectiveAmount != null;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPad),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ──────────────────────────────────────
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.dividerLight,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusCircle),
                  ),
                ),
              ),
            ),

            // ── Title ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppConstants.spaceM, 16, AppConstants.spaceM, 4),
              child: Text(
                'شحن المحفظة',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spaceM),
              child: Text(
                'كم تريد أن تشحن؟',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Quick amounts ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spaceM),
              child: Row(
                children: _quickAmounts.map((amt) {
                  final isSelected =
                      !_isCustomActive && _selectedQuick == amt;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedQuick = amt;
                          _isCustomActive = false;
                          _customCtrl.clear();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(
                                AppConstants.radiusM),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.dividerLight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${amt.toInt()}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.textPrimaryLight
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // ── Custom amount ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spaceM),
              child: TextField(
                controller: _customCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {
                  _isCustomActive = _customCtrl.text.isNotEmpty;
                  if (_isCustomActive) _selectedQuick = null;
                }),
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimaryLight),
                decoration: InputDecoration(
                  hintText: 'مبلغ مخصص (ريال)',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textHintLight),
                  suffixText: 'ر.س',
                  suffixStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight),
                  filled: true,
                  fillColor: _isCustomActive
                      ? AppColors.primaryLight
                      : AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusM),
                    borderSide: BorderSide(
                      color: _isCustomActive
                          ? AppColors.primary
                          : AppColors.dividerLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusM),
                    borderSide: BorderSide(
                      color: _isCustomActive
                          ? AppColors.primary
                          : AppColors.dividerLight,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusM),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Payment method ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spaceM),
              child: Text(
                'طريقة الدفع',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spaceM),
              child: Column(
                children: List.generate(_paymentMethods.length, (i) {
                  final isSelected = _selectedPaymentIdx == i;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedPaymentIdx = i),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryLight
                            : AppColors.backgroundLight,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusM),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.dividerLight,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _paymentIcons[i],
                            size: 22,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _paymentMethods[i],
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? AppColors.textPrimaryLight
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const Spacer(),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.dividerLight,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded,
                                    size: 12,
                                    color: AppColors.textPrimaryLight)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),

            // ── Confirm button ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spaceM,
                0,
                AppConstants.spaceM,
                AppConstants.spaceM,
              ),
              child: SizedBox(
                width: double.infinity,
                height: AppConstants.buttonHeight,
                child: ElevatedButton(
                  onPressed: canConfirm ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.dividerLight,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusM),
                    ),
                  ),
                  child: Text(
                    canConfirm
                        ? 'شحن ${_effectiveAmount!.toInt()} ريال'
                        : 'اختر مبلغاً',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: canConfirm
                          ? AppColors.textPrimaryLight
                          : AppColors.textHintLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
