import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

const uiPreview = bool.fromEnvironment('UI_PREVIEW');

/// Presentation-only notice: no operational success is implied.
class PreviewNotice extends StatelessWidget {
  const PreviewNotice({super.key});
  @override
  Widget build(BuildContext context) => !uiPreview
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'معاينة تفاعلية · بيانات تجريبية',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
        );
}

Future<void> previewResult(
  BuildContext context,
  String title,
  String message,
) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    icon: const Icon(
      Icons.check_circle_outline_rounded,
      color: AppColors.success,
      size: 44,
    ),
    title: Text(title, style: AppTextStyles.titleLarge),
    content: Text(message, style: AppTextStyles.bodyMedium),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('حسناً'),
      ),
    ],
  ),
);

/// Shares the spacing, filled inputs, and rounded selection cards of the existing wizard.
class PreviewField extends StatelessWidget {
  final String label, value;
  final ValueChanged<String> onChanged;
  final bool numeric;
  final int lines;
  final int? maxLength;
  const PreviewField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.numeric = false,
    this.lines = 1,
    this.maxLength,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: key,
      initialValue: value,
      onChanged: onChanged,
      maxLines: lines,
      maxLength: maxLength,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : lines > 1
          ? TextInputType.multiline
          : TextInputType.text,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: context.appColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.appColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.appColors.divider),
        ),
      ),
    ),
  );
}

class PreviewSection extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onEdit;
  const PreviewSection({
    super.key,
    required this.title,
    required this.child,
    this.onEdit,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.appColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.appColors.divider),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: AppTextStyles.titleMedium)),
            if (onEdit != null)
              TextButton(onPressed: onEdit, child: const Text('تعديل')),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class PreviewChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const PreviewChoice(
    this.label, {
    super.key,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(
      label,
      style: AppTextStyles.bodySmall.copyWith(
        color: selected
            ? context.appColors.accentText
            : context.appColors.textPrimary,
      ),
    ),
    checkmarkColor: AppColors.primary,
    selected: selected,
    onSelected: (_) => onTap(),
    selectedColor: context.appColors.primaryTint,
    backgroundColor: context.appColors.surface,
    side: BorderSide(
      color: selected ? AppColors.primary : context.appColors.divider,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}
