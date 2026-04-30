import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger }

enum AppButtonSize { sm, md, lg }

class AppButton extends StatefulWidget {
  final String label;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final VoidCallback? onTap;
  final bool loading;
  final bool disabled;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.onTap,
    this.loading = false,
    this.disabled = false,
    this.icon,
    this.width,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _isDisabled => widget.disabled || widget.loading;

  Color get _backgroundColor {
    if (_isDisabled && widget.variant != AppButtonVariant.outline &&
        widget.variant != AppButtonVariant.ghost) {
      return _primaryColor.withValues(alpha: 0.5);
    }
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.gray900;
      case AppButtonVariant.secondary:
        return AppColors.gray100;
      case AppButtonVariant.outline:
        return Colors.transparent;
      case AppButtonVariant.ghost:
        return Colors.transparent;
      case AppButtonVariant.danger:
        return AppColors.expenseRed500;
    }
  }

  Color get _foregroundColor {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.surface;
      case AppButtonVariant.secondary:
        return AppColors.gray900;
      case AppButtonVariant.outline:
        return AppColors.gray900;
      case AppButtonVariant.ghost:
        return AppColors.gray900;
      case AppButtonVariant.danger:
        return AppColors.surface;
    }
  }

  Color get _borderColor {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return Colors.transparent;
      case AppButtonVariant.secondary:
        return Colors.transparent;
      case AppButtonVariant.outline:
        return AppColors.gray300;
      case AppButtonVariant.ghost:
        return Colors.transparent;
      case AppButtonVariant.danger:
        return Colors.transparent;
    }
  }

  double get _horizontalPadding {
    switch (widget.size) {
      case AppButtonSize.sm:
        return AppSpacing.buttonHSm;
      case AppButtonSize.md:
        return AppSpacing.buttonHMd;
      case AppButtonSize.lg:
        return AppSpacing.buttonHLg;
    }
  }

  double get _verticalPadding {
    switch (widget.size) {
      case AppButtonSize.sm:
        return AppSpacing.buttonVSm;
      case AppButtonSize.md:
        return AppSpacing.buttonVMd;
      case AppButtonSize.lg:
        return AppSpacing.buttonVLg;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case AppButtonSize.sm:
        return 12;
      case AppButtonSize.md:
        return 14;
      case AppButtonSize.lg:
        return 16;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case AppButtonSize.sm:
        return 14;
      case AppButtonSize.md:
        return 16;
      case AppButtonSize.lg:
        return 18;
    }
  }

  Color get _primaryColor {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.gray900;
      case AppButtonVariant.secondary:
        return AppColors.gray100;
      case AppButtonVariant.outline:
        return Colors.transparent;
      case AppButtonVariant.ghost:
        return Colors.transparent;
      case AppButtonVariant.danger:
        return AppColors.expenseRed500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final opacity = _isDisabled ? 0.5 : 1.0;

    final scale = _pressed ? 0.98 : 1.0;

    final buttonContent = Opacity(
      opacity: opacity,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.width,
          padding: EdgeInsets.symmetric(
            horizontal: _horizontalPadding,
            vertical: _verticalPadding,
          ),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: AppRadius.smRadius,
            border: Border.all(color: _borderColor),
          ),
          child: widget.loading
              ? SizedBox(
                  width: _fontSize + 4,
                  height: _fontSize + 4,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_foregroundColor),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: _iconSize, color: _foregroundColor),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: _fontSize,
                        fontWeight: FontWeight.w600,
                        color: _foregroundColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    return GestureDetector(
      onTapDown: _isDisabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: _isDisabled ? null : (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: buttonContent,
    );
  }
}
