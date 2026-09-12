import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_failure.dart';
import '../../data/payment_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import 'payment_card_frame.dart';
import 'package:flutter/material.dart';
import '../../../../core/preview/ui_preview.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PaymentPreviewSheet extends ConsumerStatefulWidget {
  const PaymentPreviewSheet({super.key});
  @override
  ConsumerState<PaymentPreviewSheet> createState() =>
      _PaymentPreviewSheetState();
}

class _PaymentPreviewSheetState extends ConsumerState<PaymentPreviewSheet> {
  final amount = TextEditingController(text: '100');
  int step = 0;
  bool busy = false;
  String? error;
  bool fail = false;
  PaymentSession? _session;
  WebViewController? _card;
  bool _ready = false, _executing = false, _uncertain = false;
  double? _invoiceAmount;
  String? _sessionUserId;
  Timer? _tokenizationTimer;
  bool _tokenizationExpired = false;
  Future<void> _preparePayment() async {
    if (busy) return;
    _invoiceAmount = double.parse(amount.text.trim());
    _sessionUserId = ref.read(authProvider).user?.id;
    setState(() => busy = true);
    try {
      if (_sessionUserId == null) {
        throw const ApiFailure('سجل الدخول قبل بدء الدفع.');
      }
      final session = await ref
          .read(paymentRepositoryProvider)
          .initiate(_invoiceAmount!);
      if (mounted) {
        setState(() {
          _session = session;
          _tokenizationExpired = false;
          step = 1;
          _ready = false;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = ApiFailure.fromError(e).message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _execute(String sessionId) async {
    if (_executing || !busy || _uncertain || _tokenizationExpired) return;
    _tokenizationTimer?.cancel();
    _executing = true;
    try {
      if (_sessionUserId != ref.read(authProvider).user?.id) {
        throw const ApiFailure('تغير الحساب. أعد فتح جلسة الدفع.');
      }
      final url = await ref
          .read(paymentRepositoryProvider)
          .execute(sessionId, _invoiceAmount!);
      if (url != null &&
          !await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw const ApiFailure(
          'تعذر فتح صفحة التحقق. تحقق من المحفظة قبل إعادة الدفع.',
          {},
          null,
          true,
        );
      }
      await ref.read(walletProvider.notifier).refresh();
      if (mounted) setState(() => step = 2);
    } catch (e) {
      final failure = ApiFailure.fromError(e);
      _uncertain = failure.mayHaveCommitted;
      if (mounted) setState(() => error = failure.message);
    } finally {
      if (!_uncertain) _executing = false;
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    _tokenizationTimer?.cancel();
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.appColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (step == 1 && !busy && !_uncertain && !_executing)
                IconButton(
                  onPressed: () => setState(() {
                    step = 0;
                    error = null;
                  }),
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                ),
              Expanded(
                child: Text(
                  step == 0
                      ? 'شحن المحفظة'
                      : step == 1
                      ? 'طريقة الدفع'
                      : uiPreview
                      ? 'نتيجة المعاينة'
                      : 'متابعة الدفع',
                  style: AppTextStyles.headlineSmall,
                ),
              ),
            ],
          ),
          const PreviewNotice(),
          if (step == 0) ...[
            Text('كم تريد أن تشحن؟', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [100, 500, 1000, 5000].map((v) {
                  final selected = amount.text == '$v';
                  return SizedBox(
                    width: (constraints.maxWidth - 8) / 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: busy
                          ? null
                          : () => setState(() => amount.text = '$v'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : context.appColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : context.appColors.divider,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$v ريال',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.appColors.textPrimary,
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
            TextField(
              controller: amount,
              enabled: !busy,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'مبلغ مخصص (ريال)',
                filled: true,
                fillColor: context.appColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('الحد الأدنى 100 ريال'),
            const SizedBox(height: 20),
          ],
          if (step == 1) ...[
            PreviewSection(
              title: 'مبلغ الشحن',
              child: Text(
                '${amount.text} ريال',
                style: AppTextStyles.titleLarge,
              ),
            ),
            if (!uiPreview && _session != null)
              PaymentCardFrame(
                key: ValueKey(_session!.id),
                session: _session!,
                onController: (c) => _card = c,
                onSession: _execute,
                onReady: () {
                  if (mounted) setState(() => _ready = true);
                },
                onError: () {
                  if (_executing) return;
                  _tokenizationTimer?.cancel();
                  if (mounted) {
                    setState(() {
                      busy = false;
                      error =
                          'تعذر التحقق من البطاقة. راجع البيانات أو أعد فتح جلسة الدفع.';
                    });
                  }
                },
              ),
            if (uiPreview)
              const PreviewSection(
                title: 'بطاقة تجريبية',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.credit_card_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '••••  ••••  ••••  4242',
                      textDirection: TextDirection.ltr,
                    ),
                    SizedBox(height: 8),
                    Text('12/30     •••', textDirection: TextDirection.ltr),
                    SizedBox(height: 8),
                    Text('بيانات ثابتة للمعاينة؛ لا تدخل بيانات بطاقة حقيقية.'),
                  ],
                ),
              ),
            if (uiPreview)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('معاينة تعذر الدفع'),
                value: fail,
                onChanged: busy ? null : (v) => setState(() => fail = v),
              ),
          ],
          if (step == 2) ...[
            Center(
              child: Icon(
                uiPreview
                    ? Icons.check_circle_outline
                    : Icons.hourglass_top_rounded,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              uiPreview
                  ? 'اكتملت معاينة الدفع. لم يتم خصم أموال أو شحن المحفظة.'
                  : 'جاري التحقق من نتيجة الدفع. سيتم تحديث رصيد المحفظة بعد تأكيد العملية من بوابة الدفع.',
            ),
            const SizedBox(height: 20),
          ],
          if (_uncertain)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('العودة للمحفظة للتحقق'),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                error!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  busy ||
                      (!uiPreview &&
                          step == 1 &&
                          (!_ready ||
                              _executing ||
                              _uncertain ||
                              _tokenizationExpired))
                  ? null
                  : () async {
                      if (step == 2) {
                        Navigator.pop(context);
                        return;
                      }
                      if (step == 0) {
                        final value = double.tryParse(amount.text.trim());
                        if (value == null || !value.isFinite || value < 100) {
                          setState(
                            () => error = 'أدخل مبلغاً لا يقل عن 100 ريال',
                          );
                          return;
                        }
                        FocusScope.of(context).unfocus();
                        if (!uiPreview) {
                          await _preparePayment();
                          return;
                        }
                        setState(() {
                          step = 1;
                          error = null;
                        });
                        return;
                      }
                      setState(() {
                        busy = true;
                        error = null;
                      });
                      if (!uiPreview) {
                        try {
                          _tokenizationTimer = Timer(
                            const Duration(seconds: 45),
                            () {
                              if (!mounted || _executing) return;
                              setState(() {
                                busy = false;
                                _tokenizationExpired = true;
                                error =
                                    'انتهت مهلة التحقق من البطاقة. ارجع لخطوة المبلغ لبدء جلسة جديدة.';
                              });
                            },
                          );
                          await _card!.runJavaScript('pay()');
                        } catch (_) {
                          _tokenizationTimer?.cancel();
                          if (mounted) {
                            setState(() {
                              busy = false;
                              error = 'تعذر بدء الدفع. حاول مجدداً.';
                            });
                          }
                        }
                        return;
                      }
                      await Future<void>.delayed(
                        const Duration(milliseconds: 600),
                      );
                      if (!mounted) return;
                      setState(() {
                        busy = false;
                        if (fail) {
                          error =
                              'تعذر إكمال معاينة الدفع. يمكنك المحاولة مجدداً.';
                        } else {
                          step = 2;
                        }
                      });
                    },
              child: Text(
                busy
                    ? uiPreview
                          ? 'جارٍ عرض المعاينة…'
                          : 'جارٍ المعالجة…'
                    : step == 0
                    ? 'التالي'
                    : step == 1
                    ? uiPreview
                          ? 'معاينة الدفع'
                          : 'دفع ${amount.text} ريال'
                    : 'العودة للمحفظة',
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}
