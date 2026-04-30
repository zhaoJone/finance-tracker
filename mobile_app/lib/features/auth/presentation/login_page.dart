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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController(text: 'test@test.com');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    context.read<AuthBloc>().add(
          AuthLoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
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
                  // Logo / App Title
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.account_balance_wallet_rounded, size: 32, color: AppColors.gray900),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'Finance Tracker',
                    style: AppTypography.h1,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    '简洁高效的个人记账',
                    style: TextStyle(fontSize: 14, color: AppColors.gray500),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

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
                    hintText: '请输入密码',
                    controller: _passwordController,
                    obscureText: _obscure,
                    enabled: !isLoading,
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20, color: AppColors.gray400),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: '登录',
                      loading: isLoading,
                      onTap: isLoading ? null : _onLogin,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '没有账号？',
                        style: TextStyle(fontSize: 14, color: AppColors.gray500),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigate to register — for now show snackbar placeholder
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('注册功能开发中，请使用默认账号登录'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text(
                          '注册',
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
