import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../../core/widgets/app_button.dart';
import '../data/bills_models.dart';
import 'bills_bloc.dart';
import 'bills_event.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _type = 'expense';

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;
    final amountFen = (double.parse(amountText) * 100).round();

    context.read<BillsBloc>().add(BillsCreate(
          transaction: TransactionCreate(
            amount: amountFen,
            type: _type,
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          ),
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('添加交易', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _typeToggle('expense', '支出', AppColors.expenseRed500),
              const SizedBox(width: AppSpacing.sm),
              _typeToggle('income', '收入', AppColors.incomeGreen600),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppInput(
            label: '金额（元）',
            hintText: '例如: 100.00',
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.md),
          AppInput(
            label: '备注（可选）',
            hintText: '交易备注',
            controller: _noteController,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: AppButton(label: '添加', onTap: _submit),
          ),
        ],
      ),
    );
  }

  Widget _typeToggle(String value, String label, Color activeColor) {
    final isActive = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeColor : AppColors.gray100,
            borderRadius: AppRadius.smRadius,
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              color: isActive ? AppColors.surface : AppColors.gray700,
              fontWeight: FontWeight.w600,
            )),
          ),
        ),
      ),
    );
  }
}
