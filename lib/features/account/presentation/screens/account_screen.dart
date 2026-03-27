import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../providers/account_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final isLoggedIn = user != null;
    final unreadNotifications = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.backgroundLight,
            elevation: 0,
            scrolledUnderElevation: 0,
            pinned: true,
            title: Text(
              'حسابي',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
            ),
            centerTitle: true,
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded,
                        color: AppColors.textPrimaryLight),
                    onPressed: () => context.push(AppRoutes.notifications),
                  ),
                  if (unreadNotifications > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.dividerLight),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top profile section ─────────────────────
                isLoggedIn
                    ? _ProfileSection(user: user)
                    : const _GuestSection(),

                const SizedBox(height: 8),

                // ── Wallet card (logged in only) ────────────
                if (isLoggedIn) ...[
                  _WalletCard(
                    balance: user.walletBalance,
                    onTopUp: () => context.push(AppRoutes.wallet),
                  ),
                  const SizedBox(height: 8),

                  // ── Quick actions ──────────────────────────
                  _QuickActionsGrid(),
                  const SizedBox(height: 8),
                ],

                // ── My Activity section ─────────────────────
                _MenuSection(
                  title: 'نشاطي',
                  items: [
                    _MenuItem(
                      icon: Icons.home_work_rounded,
                      label: 'إعلاناتي',
                      onTap: () => context.push(AppRoutes.myListings),
                    ),
                    _MenuItem(
                      icon: Icons.handshake_rounded,
                      label: 'صفقاتي',
                      onTap: () => _showComingSoon(context, 'صفقاتي'),
                    ),
                    _MenuItem(
                      icon: Icons.calendar_month_rounded,
                      label: 'حجوزاتي',
                      onTap: () => _showComingSoon(context, 'حجوزاتي'),
                    ),
                    _MenuItem(
                      icon: Icons.campaign_rounded,
                      label: 'طلباتي',
                      onTap: () => _showComingSoon(context, 'الطلبات'),
                    ),
                    _MenuItem(
                      icon: Icons.meeting_room_rounded,
                      label: 'طلبات حجز الوحدات',
                      onTap: () =>
                          _showComingSoon(context, 'طلبات حجز الوحدات'),
                    ),
                    _MenuItem(
                      icon: Icons.people_alt_rounded,
                      label: 'عملائي (CRM)',
                      onTap: () => _showComingSoon(context, 'عملائي'),
                    ),
                    _MenuItem(
                      icon: Icons.favorite_rounded,
                      label: 'المفضلة',
                      onTap: () => context.push(AppRoutes.favorites),
                      isLast: true,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Host tools section ──────────────────────
                _MenuSection(
                  title: 'أدوات المضيف',
                  items: [
                    _MenuItem(
                      icon: Icons.rocket_launch_rounded,
                      label: 'ترقية الإعلانات',
                      onTap: () =>
                          _showComingSoon(context, 'ترقية الإعلانات'),
                    ),
                    _MenuItem(
                      icon: Icons.workspace_premium_rounded,
                      label: 'اشتراك عقار+',
                      badge: 'مميز',
                      onTap: () =>
                          _showComingSoon(context, 'اشتراك عقار+'),
                      isLast: true,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Account section ─────────────────────────
                _MenuSection(
                  title: 'الحساب',
                  items: [
                    _MenuItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'المدفوعات والفواتير',
                      onTap: () =>
                          _showComingSoon(context, 'المدفوعات والفواتير'),
                    ),
                    _MenuItem(
                      icon: Icons.notifications_rounded,
                      label: 'الإشعارات',
                      onTap: () => context.push(AppRoutes.notifications),
                    ),
                    _MenuItem(
                      icon: Icons.edit_rounded,
                      label: 'تعديل الملف الشخصي',
                      onTap: () =>
                          _showComingSoon(context, 'تعديل الملف الشخصي'),
                    ),
                    _MenuItem(
                      icon: Icons.smartphone_rounded,
                      label: 'تغيير رقم الجوال',
                      onTap: () =>
                          _showComingSoon(context, 'تغيير رقم الجوال'),
                    ),
                    _MenuItem(
                      icon: Icons.business_rounded,
                      label: 'حساب المنشأة',
                      onTap: () =>
                          _showComingSoon(context, 'حساب المنشأة'),
                    ),
                    _MenuItem(
                      icon: Icons.settings_rounded,
                      label: 'الإعدادات',
                      onTap: () => context.push(AppRoutes.settings),
                      isLast: true,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Logout ──────────────────────────────────
                if (isLoggedIn)
                  _LogoutButton(
                    onLogout: () {
                      ref.read(authProvider.notifier).reset();
                    },
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }

  void _showComingSoon(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$name — قريباً'),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ── Guest (not logged in) section ─────────────────────────────────────────────

class _GuestSection extends StatelessWidget {
  const _GuestSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundLight,
      padding: const EdgeInsets.all(AppConstants.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'سجّل دخولك إلى عقار',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'سجّل دخولك للوصول إلى إعلاناتك وصفقاتك وحجوزاتك',
            style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.push(AppRoutes.login),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize:
                  const Size(double.infinity, AppConstants.buttonHeight),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusM)),
              elevation: 0,
            ),
            child: Text(
              'تسجيل الدخول',
              style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.push('${AppRoutes.login}/phone'),
            style: OutlinedButton.styleFrom(
              minimumSize:
                  const Size(double.infinity, AppConstants.buttonHeight),
              side: const BorderSide(color: AppColors.dividerLight),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusM)),
            ),
            child: Text(
              'إنشاء حساب جديد',
              style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logged-in profile section ─────────────────────────────────────────────────

class _ProfileSection extends StatelessWidget {
  final UserProfile user;
  const _ProfileSection({required this.user});

  static const double _iconSize = 56.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/profile/${user.id}'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: AppColors.backgroundLight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceM,
          vertical: AppConstants.spaceM,
        ),
        child: Column(
          children: [
            // ── Personal row ───────────────────────────────
            Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: user.photoUrl,
                        width: _iconSize,
                        height: _iconSize,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: _iconSize,
                          height: _iconSize,
                          color: AppColors.primaryLight,
                          child: const Icon(Icons.person_rounded,
                              color: AppColors.primary, size: 28),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: _iconSize,
                          height: _iconSize,
                          color: AppColors.primaryLight,
                          child: const Icon(Icons.person_rounded,
                              color: AppColors.primary, size: 28),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      bottom: 0,
                      end: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_rounded,
                            size: 11, color: AppColors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Name + number + rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'رقم المستخدم: ${user.userNumber}',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 13, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text(
                            user.rating.toStringAsFixed(1),
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            '  (${user.reviewCount} تقييم)',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.textHintLight),
              ],
            ),

            // ── Establishment row (broker only) ────────────
            if (user.isBroker && user.establishmentName != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.dividerLight),
              const SizedBox(height: 12),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: user.establishmentLogoUrl ?? '',
                      width: _iconSize,
                      height: _iconSize,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: _iconSize,
                        height: _iconSize,
                        color: AppColors.primaryLight,
                        child: const Icon(Icons.business_rounded,
                            size: 28, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.establishmentName!,
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'وسيط عقاري موثّق',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(25),
                      borderRadius: BorderRadius.circular(
                          AppConstants.radiusCircle),
                      border: Border.all(
                          color: AppColors.success.withAlpha(80)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded,
                            size: 13, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          'موثّق',
                          style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Wallet card ───────────────────────────────────────────────────────────────

class _WalletCard extends StatelessWidget {
  final double balance;
  final VoidCallback onTopUp;
  const _WalletCard({required this.balance, required this.onTopUp});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTopUp,
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spaceM),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withAlpha(50),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Wallet icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusM),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),

            // Balance
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'رصيد المحفظة',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.white.withAlpha(160)),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: balance.toStringAsFixed(0),
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: '  ريال',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.white.withAlpha(160)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Top-up button
            ElevatedButton(
              onPressed: onTopUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusCircle),
                ),
                elevation: 0,
              ),
              child: Text(
                'شحن',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

// ── Quick actions ─────────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
      child: Row(
        children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.add_home_work_rounded,
              label: 'إضافة عقار',
              onTap: () => context.push(AppRoutes.addListing),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickAction(
              icon: Icons.campaign_rounded,
              label: 'طلب تسويق',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('طلب التسويق — قريباً'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            border: Border.all(color: AppColors.dividerLight),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

// ── Menu section ──────────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppConstants.spaceM,
                AppConstants.spaceS, AppConstants.spaceM, 6),
            child: Text(
              title,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            color: AppColors.backgroundLight,
            child: Column(children: items),
          ),
        ],
      );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.badge,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spaceM, vertical: 14),
              child: Row(
                children: [
                  Icon(icon,
                      size: 20,
                      color: AppColors.textSecondaryLight),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimaryLight),
                    ),
                  ),
                  if (badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(
                            AppConstants.radiusCircle),
                      ),
                      child: Text(
                        badge!,
                        style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.textSecondaryLight),
                ],
              ),
            ),
          ),
          if (!isLast)
            const Padding(
              padding: EdgeInsetsDirectional.only(
                  start: AppConstants.spaceM + 34),
              child: Divider(height: 1, color: AppColors.dividerLight),
            ),
        ],
      );
}

// ── Logout button ─────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;
  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.backgroundLight,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusL)),
                title: Text('تسجيل الخروج',
                    style: AppTextStyles.titleLarge
                        .copyWith(fontWeight: FontWeight.w700)),
                content: Text('هل تريد تسجيل الخروج من حسابك؟',
                    style: AppTextStyles.bodyMedium),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('إلغاء',
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondaryLight)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onLogout();
                    },
                    child: Text('تسجيل الخروج',
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spaceM, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.logout_rounded,
                    size: 20, color: AppColors.error),
                const SizedBox(width: 14),
                Text(
                  'تسجيل الخروج',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
}
