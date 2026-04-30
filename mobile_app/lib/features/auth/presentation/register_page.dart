import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_button.dart';
import '../presentation/auth_bloc.dart';
import '../presentation/auth_event.dart';
import '../presentation/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onRegister() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    // Client-side validation
    if (email.isEmpty) {
      setState(() => _localError = '请输入邮箱');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _localError = '邮箱格式不正确');
      return;
    }
    if (password.length < 6) {
      setState(() => _localError = '密码至少6位');
      return;
    }
    if (password != confirm) {
      setState(() => _localError = '两次密码输入不一致');
      return;
    }

    setState(() => _localError = null);
    context.read<AuthBloc>().add(
          AuthRegisterRequested(email: email, password: password),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.expenseRed500,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.person_add_rounded, size: 32, color: AppColors.gray900),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    '注册账号',
                    style: AppTypography.h1,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    '创建你的个人记账账号',
                    style: TextStyle(fontSize: 14, color: AppColors.gray500),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Error banner
                  if (_localError != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.expenseRed500.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _localError!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.expenseRed500,
                        ),
                      ),
                    ),

                  // Email input
                  AppInput(
                    label: '邮箱',
                    hintText: 'example@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Password input
                  AppInput(
                    label: '密码',
                    hintText: '至少6位',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !isLoading,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.gray400,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Confirm password input
                  AppInput(
                    label: '确认密码',
                    hintText: '再次输入密码',
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    enabled: !isLoading,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.gray400,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: '注册',
                      loading: isLoading,
                      onTap: isLoading ? null : _onRegister,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Link to login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '已有账号？',
                        style: TextStyle(fontSize: 14, color: AppColors.gray500),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text(
                          '登录',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
