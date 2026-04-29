import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

enum AppBadgeVariant { default_, success, warning, error, info }

class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.default_,
  });

  Color get _backgroundColor {
    switch (variant) {
      case AppBadgeVariant.default_:
        return AppColors.badgeDefaultBg;
      case AppBadgeVariant.success:
        return AppColors.badgeSuccessBg;
      case AppBadgeVariant.warning:
        return AppColors.badgeWarningBg;
      case AppBadgeVariant.error:
        return AppColors.badgeErrorBg;
      case AppBadgeVariant.info:
        return AppColors.badgeInfoBg;
    }
  }

  Color get _textColor {
    switch (variant) {
      case AppBadgeVariant.default_:
        return AppColors.badgeDefaultText;
      case AppBadgeVariant.success:
        return AppColors.badgeSuccessText;
      case AppBadgeVariant.warning:
        return AppColors.badgeWarningText;
      case AppBadgeVariant.error:
        return AppColors.badgeErrorText;
      case AppBadgeVariant.info:
        return AppColors.badgeInfoText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: AppRadius.fullRadius,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.025,
          color: _textColor,
          height: 1.3,
        ),
      ),
    );
  }
}
