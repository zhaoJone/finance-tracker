import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/presentation/auth_bloc.dart';
import '../../auth/presentation/auth_event.dart';
import '../../auth/data/auth_models.dart';
import '../../notifications/presentation/notification_import_bloc.dart';
import '../../notifications/presentation/notification_import_page.dart';
import 'profile_bloc.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => context.read<ProfileBloc>()..add(ProfileLoad()),
      child: const _ProfileBody(),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ProfileError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: AppColors.gray300),
                const SizedBox(height: 12),
                Text(state.message, style: const TextStyle(color: AppColors.expenseRed500)),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.read<ProfileBloc>().add(ProfileLoad()),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }
        if (state is ProfileLoaded) {
          return _ProfileContent(user: state.user);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final User user;

  const _ProfileContent({required this.user});

  String get _initials {
    final email = user.email;
    final atIndex = email.indexOf('@');
    if (atIndex > 0) {
      return email.substring(0, 2).toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  String get _joinDateDisplay {
    // From the user data if available, otherwise show a default
    return '已加入 Finance Tracker';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxxl),
          // Avatar section
          _buildAvatarSection(context),
          const SizedBox(height: AppSpacing.xxxl),

          // Menu items
          _buildMenuSection(context),
          const SizedBox(height: AppSpacing.xxxl),

          // Logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: AppButton(
                label: '退出登录',
                variant: AppButtonVariant.danger,
                onTap: () => _showLogoutConfirm(context),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.gray800, AppColors.gray900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppRadius.fullRadius,
            boxShadow: [
              BoxShadow(
                color: AppColors.gray900.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _initials,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.surface,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          user.email,
          style: AppTypography.h2,
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: AppRadius.fullRadius,
          ),
          child: Text(
            _joinDateDisplay,
            style: const TextStyle(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _MenuItem(
            icon: Icons.notifications_outlined,
            title: '通知导入',
            subtitle: '自动捕获支付宝/微信支付通知',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.incomeGreen600.withOpacity(0.1),
                borderRadius: AppRadius.fullRadius,
              ),
              child: const Text('新功能', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.incomeGreen600)),
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: getIt<NotificationImportBloc>(),
                  child: const NotificationImportPage(),
                ),
              ),
            ),
          ),
          const Divider(height: 1, indent: 56),
          _MenuItem(
            icon: Icons.info_outline,
            title: '关于',
            subtitle: 'Finance Tracker v1.0.0',
            onTap: () => _showAbout(context),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            child: const Text('退出', style: TextStyle(color: AppColors.expenseRed500)),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
        title: const Text('关于'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Finance Tracker'),
            SizedBox(height: 8),
            Text('版本: v1.0.0', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
            SizedBox(height: 4),
            Text('个人财务追踪助手', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: AppRadius.smRadius,
              ),
              child: Icon(icon, size: 20, color: AppColors.gray600),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.gray300),
          ],
        ),
      ),
    );
  }
}
