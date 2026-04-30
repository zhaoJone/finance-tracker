import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/presentation/auth_bloc.dart';
import '../../auth/presentation/auth_event.dart';
import '../../auth/data/auth_models.dart';
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxxl),
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: AppRadius.fullRadius,
            ),
            child: const Center(
              child: Icon(Icons.person, size: 40, color: AppColors.gray400),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // User email
          Text(
            user.email,
            style: AppTypography.h2,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '用户 ID: ${user.id}',
            style: const TextStyle(fontSize: 13, color: AppColors.gray400),
          ),
          const SizedBox(height: AppSpacing.xxxl),

          // Info cards
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _InfoRow(label: '邮箱', value: user.email),
                const Divider(height: 24),
                _InfoRow(label: '用户 ID', value: user.id),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: '退出登录',
              variant: AppButtonVariant.danger,
              onTap: () {
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.gray500)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray900)),
      ],
    );
  }
}
