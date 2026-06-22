import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myfatoorah_flutter/myfatoorah_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/payment_event_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../data/payment_service.dart';
import 'payment_webview_screen.dart';

class PaymentCardScreen extends StatefulWidget {
  final String sessionId;
  final String countryCode;
  final double invoiceValue;

  const PaymentCardScreen({
    super.key,
    required this.sessionId,
    required this.countryCode,
    required this.invoiceValue,
  });

  @override
  State<PaymentCardScreen> createState() => _PaymentCardScreenState();
}

class _PaymentCardScreenState extends State<PaymentCardScreen> {
  StreamSubscription<void>? _paymentSub;

  bool _isExecuting = false;
  bool _isWaiting = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    // When the backend confirms the top-up via FCM, return to the wallet.
    _paymentSub = PaymentEventService.onPaymentConfirmed.listen((_) {
      if (mounted) appRouter.go(AppRoutes.wallet);
    });

    // Load the card form into the native MFCardPaymentView after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MFSDK.load(
        MFInitiateSessionResponse(
          sessionId: widget.sessionId,
          countryCode: widget.countryCode,
        ),
        false,
        null,
      );
    });
  }

  @override
  void dispose() {
    _paymentSub?.cancel();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_isExecuting) return;
    setState(() {
      _isExecuting = true;
      _error = null;
    });

    try {
      final result = await PaymentService.executePayment(
        sessionId: widget.sessionId,
        invoiceValue: widget.invoiceValue,
      );
      if (!mounted) return;

      if (result.paymentURL != null) {
        // 3DS / KNET redirect — show in-app WebView, then wait for FCM.
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaymentWebViewScreen(url: result.paymentURL!),
          ),
        );
        if (mounted) setState(() => _isWaiting = true);
      } else {
        // Direct processing — FCM PAYMENT_CONFIRMED will trigger navigation.
        setState(() => _isWaiting = true);
      }
    } catch (e, st) {
      dev.log('Payment execute error: $e', stackTrace: st, name: 'PaymentCardScreen');
      if (mounted) {
        setState(() {
          _isExecuting = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        backgroundColor: context.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'الدفع بالبطاقة',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        leading: Platform.isIOS
            ? null
            : IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 20,
                  color: context.textPrimary,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        actions: Platform.isIOS
            ? [
                CupertinoButton(
                  padding: const EdgeInsets.only(right: 4),
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Icon(
                    CupertinoIcons.chevron_back,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ]
            : [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.divider),
        ),
      ),
      body: _isWaiting ? const _WaitingView() : _buildCardPayView(context),
    );
  }

  Widget _buildCardPayView(BuildContext context) {
    return Column(
      children: [
        // ── Amount banner ───────────────────────────────────────────────
        _AmountBanner(amount: widget.invoiceValue),

        // ── MyFatoorah native card form ─────────────────────────────────
        Expanded(child: MFCardPaymentView()),

        // ── Validation error ────────────────────────────────────────────
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceM,
              vertical: 8,
            ),
            child: Text(
              _error!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),

        // ── Pay button ──────────────────────────────────────────────────
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spaceM),
            child: SizedBox(
              width: double.infinity,
              height: AppConstants.buttonHeight,
              child: ElevatedButton(
                onPressed: _isExecuting ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: context.divider,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                ),
                child: _isExecuting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.white,
                          ),
                        ),
                      )
                    : Text(
                        'ادفع ${widget.invoiceValue.toInt()} ر.س',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: context.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Amount banner ─────────────────────────────────────────────────────────────

class _AmountBanner extends StatelessWidget {
  final double amount;
  const _AmountBanner({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.background,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceM,
        vertical: AppConstants.spaceM,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'شحن المحفظة',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
              Text(
                '${amount.toInt()} ر.س',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Waiting for PAYMENT_CONFIRMED push notification ───────────────────────────

class _WaitingView extends StatelessWidget {
  const _WaitingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoadingIndicator(color: AppColors.primary, size: 48),
            const SizedBox(height: 24),
            Text(
              'جاري معالجة الدفع…',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم تحديث رصيدك تلقائياً عند اكتمال العملية',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
