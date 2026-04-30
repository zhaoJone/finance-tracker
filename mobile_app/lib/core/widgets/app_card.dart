import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class AppCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool _flat;
  final bool _interactive;

  const AppCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
  })  : _flat = false,
        _interactive = false,
        onTap = null;

  const AppCard.flat({
    super.key,
    this.child,
    this.padding,
    this.margin,
  })  : _flat = true,
        _interactive = false,
        onTap = null;

  const AppCard.interactive({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.onTap,
  })  : _flat = false,
        _interactive = true;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.gray100),
        boxShadow: _flat
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: child,
    );

    if (_interactive && onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
