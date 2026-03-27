import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 20, color: AppColors.textPrimaryLight),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'الإعدادات',
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
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceM,
          vertical: AppConstants.spaceM,
        ),
        children: [
          // ── Section: Preferences ───────────────────────────
          _SectionLabel('التفضيلات'),
          _SettingsCard(
            children: [
              // Language
              _TappableRow(
                icon: Icons.language_rounded,
                label: 'اللغة',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.language.label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: AppColors.textHintLight),
                  ],
                ),
                onTap: () => _showLanguageSheet(context, ref, s.language),
              ),
              const _ItemDivider(),
              // Theme
              _ThemeRow(current: s.themeMode, onChanged: notifier.setThemeMode),
            ],
          ),

          const SizedBox(height: AppConstants.spaceM),

          // ── Section: Notifications ─────────────────────────
          _SectionLabel('الإشعارات'),
          _SettingsCard(
            children: [
              // Master toggle
              _ToggleRow(
                icon: Icons.notifications_rounded,
                label: 'الإشعارات الفورية',
                value: s.pushNotifications,
                onChanged: notifier.setPushNotifications,
              ),
              const _ItemDivider(),
              // Sub-toggles — greyed when master is off
              _ToggleRow(
                icon: Icons.chat_bubble_rounded,
                label: 'الرسائل الجديدة',
                value: s.newMessages,
                enabled: s.pushNotifications,
                onChanged: notifier.setNewMessages,
                indent: true,
              ),
              const _ItemDivider(),
              _ToggleRow(
                icon: Icons.calendar_month_rounded,
                label: 'تحديثات الحجوزات',
                value: s.bookingUpdates,
                enabled: s.pushNotifications,
                onChanged: notifier.setBookingUpdates,
                indent: true,
              ),
              const _ItemDivider(),
              _ToggleRow(
                icon: Icons.search_rounded,
                label: 'تنبيهات البحث',
                value: s.searchAlerts,
                enabled: s.pushNotifications,
                onChanged: notifier.setSearchAlerts,
                indent: true,
              ),
              const _ItemDivider(),
              _ToggleRow(
                icon: Icons.local_offer_rounded,
                label: 'العروض والترقيات',
                value: s.promotions,
                enabled: s.pushNotifications,
                onChanged: notifier.setPromotions,
                indent: true,
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spaceM),

          // ── Section: Danger Zone ───────────────────────────
          _SectionLabel('منطقة الخطر'),
          _SettingsCard(
            children: [
              _TappableRow(
                icon: Icons.delete_forever_rounded,
                label: 'حذف الحساب',
                iconColor: AppColors.error,
                labelColor: AppColors.error,
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 13, color: AppColors.error),
                onTap: () => _showDeleteDialog(context),
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 40),

          // ── Version ────────────────────────────────────────
          Center(
            child: Text(
              'عقار — الإصدار ${AppConstants.appVersion}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHintLight,
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spaceL),
        ],
      ),
    );
  }

  // ── Language bottom sheet ─────────────────────────────────────────────────

  void _showLanguageSheet(
      BuildContext context, WidgetRef ref, AppLanguage current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceM,
            vertical: AppConstants.spaceM,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.dividerLight,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusCircle),
                  ),
                ),
              ),
              Text(
                'اختر اللغة',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              ...AppLanguage.values.map((lang) {
                final isSelected = lang == current;
                return GestureDetector(
                  onTap: () {
                    ref
                        .read(settingsProvider.notifier)
                        .setLanguage(lang);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryLight
                          : AppColors.surfaceLight,
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
                        Text(
                          lang.label,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.textPrimaryLight
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded,
                                size: 14,
                                color: AppColors.textPrimaryLight),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              SizedBox(
                  height: MediaQuery.of(context).padding.bottom +
                      AppConstants.spaceM),
            ],
          ),
        );
      },
    );
  }

  // ── Delete account dialog ─────────────────────────────────────────────────

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded,
                  color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'حذف الحساب',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'هل أنت متأكد من حذف حسابك؟ سيتم حذف جميع بياناتك وإعلاناتك بشكل نهائي ولا يمكن التراجع عن هذا الإجراء.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side:
                        const BorderSide(color: AppColors.dividerLight),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusM),
                    ),
                  ),
                  child: Text(
                    'تراجع',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    minimumSize: const Size(0, 48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusM),
                    ),
                  ),
                  child: Text(
                    'حذف',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          right: 4, left: 4, bottom: 8, top: 4),
      child: Text(
        text,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textSecondaryLight,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Settings card container ───────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

// ── Item divider ──────────────────────────────────────────────────────────────

class _ItemDivider extends StatelessWidget {
  const _ItemDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      color: AppColors.dividerLight,
      indent: 52,
    );
  }
}

// ── Tappable row (language, danger zone) ─────────────────────────────────────

class _TappableRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;
  final bool isLast;

  const _TappableRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.iconColor,
    this.labelColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceM, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary)
                    .withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Icon(icon,
                  size: 18,
                  color: iconColor ?? AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? AppColors.textPrimaryLight,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// ── Theme segmented control row ───────────────────────────────────────────────

class _ThemeRow extends StatelessWidget {
  final AppThemeMode current;
  final ValueChanged<AppThemeMode> onChanged;
  const _ThemeRow({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceM, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusS),
            ),
            child: const Icon(Icons.palette_rounded,
                size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'المظهر',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
          _SegmentedControl(
            options: AppThemeMode.values,
            selected: current,
            labelOf: (m) => m.label,
            onSelect: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SegmentedControl<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelect;

  const _SegmentedControl({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isActive = opt == selected;
          return GestureDetector(
            onTap: () => onSelect(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : AppColors.transparent,
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusS - 2),
              ),
              child: Text(
                labelOf(opt),
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? AppColors.textPrimaryLight
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Toggle row (notifications) ────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final bool indent;
  final bool isLast;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.indent = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled
        ? AppColors.textPrimaryLight
        : AppColors.textHintLight;
    final effectiveIconColor =
        enabled ? AppColors.primary : AppColors.textHintLight;

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: indent ? AppConstants.spaceL : AppConstants.spaceM,
          end: AppConstants.spaceM,
          top: 4,
          bottom: 4,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color:
                    effectiveIconColor.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Icon(icon, size: 18, color: effectiveIconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: effectiveColor,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: AppColors.primary,
              activeTrackColor:
                  AppColors.primary.withValues(alpha: 0.3),
              inactiveThumbColor: AppColors.textHintLight,
              inactiveTrackColor: AppColors.dividerLight,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
