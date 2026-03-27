import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/onboarding_provider.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _SlideData {
  final String title;
  final String subtitle;
  final Widget illustration;

  const _SlideData({
    required this.title,
    required this.subtitle,
    required this.illustration,
  });
}

// ── Main screen ───────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  static const List<_SlideData> _slides = [
    _SlideData(
      title: 'ابحث عن منزل أحلامك',
      subtitle: 'تصفح آلاف العقارات في جميع\nأنحاء المملكة العربية السعودية',
      illustration: _Slide1Illustration(),
    ),
    _SlideData(
      title: 'تواصل مع الملاك مباشرة',
      subtitle: 'تحدث مع المالك أو الوسيق بشكل مباشر\nبدون أي وسيط إضافي',
      illustration: _Slide2Illustration(),
    ),
    _SlideData(
      title: 'احجز أو اشتري بسهولة',
      subtitle: 'منصة آمنة وسريعة وموثوقة\nلجميع معاملاتك العقارية',
      illustration: _Slide3Illustration(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage == _slides.length - 1;

  void _onNext() {
    if (_isLastPage) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    await markOnboardingSeen();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(isLastPage: _isLastPage, onSkip: _finish),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _SlidePage(data: _slides[i]),
              ),
            ),
            _BottomSection(
              total: _slides.length,
              current: _currentPage,
              isLastPage: _isLastPage,
              onNext: _onNext,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool isLastPage;
  final VoidCallback onSkip;

  const _TopBar({required this.isLastPage, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          // In RTL: first child = visual RIGHT, second child = visual LEFT
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedOpacity(
              opacity: isLastPage ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: TextButton(
                onPressed: isLastPage ? null : onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondaryLight,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  'تخطي',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 80),
          ],
        ),
      ),
    );
  }
}

// ── Slide page ────────────────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  final _SlideData data;

  const _SlidePage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Illustration — 58% height
        Expanded(
          flex: 58,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: data.illustration,
          ),
        ),
        // Text — 42% height
        Expanded(
          flex: 42,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
            child: Column(
              children: [
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data.subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondaryLight,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bottom section ────────────────────────────────────────────────────────────

class _BottomSection extends StatelessWidget {
  final int total;
  final int current;
  final bool isLastPage;
  final VoidCallback onNext;

  const _BottomSection({
    required this.total,
    required this.current,
    required this.isLastPage,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PageDots(total: total, current: current),
          const SizedBox(height: 28),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: ElevatedButton(
              key: ValueKey(isLastPage),
              onPressed: onNext,
              child: Text(isLastPage ? 'ابدأ الآن' : 'التالي'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page dots ─────────────────────────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  final int total;
  final int current;

  const _PageDots({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.dividerLight,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ILLUSTRATIONS
// ─────────────────────────────────────────────────────────────────────────────

// ── Slide 1: Find Your Dream Property ────────────────────────────────────────

class _Slide1Illustration extends StatelessWidget {
  const _Slide1Illustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Background circle (top-start)
        Positioned(
          top: 0,
          right: -10,
          child: Container(
            width: 210,
            height: 210,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Small accent circle (bottom-end)
        Positioned(
          bottom: 50,
          left: -10,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Main content column
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // House icon card
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.home_rounded,
                size: 72,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 28),

            // Mini property cards
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _MiniCard(price: '٥٠٠ ألف', type: 'شقة'),
                  SizedBox(width: 10),
                  _MiniCard(price: '١.٢ مليون', type: 'فيلا', highlighted: true),
                  SizedBox(width: 10),
                  _MiniCard(price: '٣٠٠ ألف', type: 'أرض'),
                ],
              ),
            ),
          ],
        ),

        // Floating location badge
        Positioned(
          top: 20,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: AppColors.white, size: 13),
                const SizedBox(width: 4),
                Text(
                  'الرياض',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String price;
  final String type;
  final bool highlighted;

  const _MiniCard({
    required this.price,
    required this.type,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            type,
            style: AppTextStyles.labelSmall.copyWith(
              color: highlighted
                  ? AppColors.white.withValues(alpha: 0.8)
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            price,
            style: AppTextStyles.labelMedium.copyWith(
              color: highlighted
                  ? AppColors.white
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slide 2: Connect With Owners ──────────────────────────────────────────────

class _Slide2Illustration extends StatelessWidget {
  const _Slide2Illustration();

  @override
  Widget build(BuildContext context) {
    // Force LTR for the chat layout so bubbles look natural
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Background circles
          Positioned(
            top: 0,
            left: -20,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            right: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Chat content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Message 1: from owner (left)
                _ChatRow(
                  message: 'هل العقار متاح للمعاينة؟',
                  initials: 'م',
                  avatarColor: AppColors.primary,
                  isMe: false,
                ),
                const SizedBox(height: 10),

                // Message 2: from me (right)
                _ChatRow(
                  message: 'نعم، يمكننا ترتيب موعد!',
                  initials: 'أ',
                  avatarColor: AppColors.success,
                  isMe: true,
                ),
                const SizedBox(height: 10),

                // Message 3: from owner (left)
                _ChatRow(
                  message: 'ممتاز! متى يناسبك؟ 🎉',
                  initials: 'م',
                  avatarColor: AppColors.primary,
                  isMe: false,
                ),

                const SizedBox(height: 22),

                // Online status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '+٢٤,٠٠٠ مالك متاح الآن',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textPrimaryLight,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  final String message;
  final String initials;
  final Color avatarColor;
  final bool isMe;

  const _ChatRow({
    required this.message,
    required this.initials,
    required this.avatarColor,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft:
              isMe ? const Radius.circular(16) : const Radius.circular(4),
          bottomRight:
              isMe ? const Radius.circular(4) : const Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message,
        textDirection: TextDirection.rtl,
        style: AppTextStyles.bodySmall.copyWith(
          color: isMe ? AppColors.white : AppColors.textPrimaryLight,
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment:
          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: isMe
          ? [Flexible(child: bubble), const SizedBox(width: 8), avatar]
          : [avatar, const SizedBox(width: 8), Flexible(child: bubble)],
    );
  }
}

// ── Slide 3: Book or Buy with Ease ────────────────────────────────────────────

class _Slide3Illustration extends StatelessWidget {
  const _Slide3Illustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Background circles
        Positioned(
          top: 0,
          child: Container(
            width: 230,
            height: 230,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: -20,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Main content
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Verified icon card
            Container(
              width: 114,
              height: 114,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified_rounded,
                size: 62,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 20),

            // Feature badges
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _FeatureBadge(label: 'آمن', icon: Icons.lock_rounded),
                  SizedBox(width: 8),
                  _FeatureBadge(
                      label: 'سريع',
                      icon: Icons.bolt_rounded,
                      highlighted: true),
                  SizedBox(width: 8),
                  _FeatureBadge(
                      label: 'موثوق', icon: Icons.verified_user_rounded),
                ],
              ),
            ),
          ],
        ),

        // Stars decoration
        Positioned(
          top: 18,
          right: 12,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: List.generate(
                5,
                (_) => const Icon(Icons.star_rounded,
                    color: AppColors.primary, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool highlighted;

  const _FeatureBadge({
    required this.label,
    required this.icon,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlighted ? AppColors.white : AppColors.primary,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: highlighted
                  ? AppColors.white
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

