import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/api_client.dart';
import '../../../../core/api_config.dart';
import '../../../../injection.dart';
import '../data/bills_models.dart';
import 'bills_bloc.dart';
import 'bills_event.dart';

class _CategoryOption {
  final String id;
  final String name;
  final String? color;

  _CategoryOption({required this.id, required this.name, this.color});
}

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _type = 'expense';
  String? _selectedCategoryId;
  List<_CategoryOption> _categories = [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final dio = getIt<ApiClient>().dio;
      final response = await dio.get(ApiConfig.categoriesEndpoint);
      final data = response.data as Map<String, dynamic>;
      final categoriesData = data['data'] as Map<String, dynamic>;
      final expenseList = (categoriesData['expense'] as List?) ?? [];
      final incomeList = (categoriesData['income'] as List?) ?? [];
      final all = [...expenseList, ...incomeList];
      if (!mounted) return;
      setState(() {
        _categories = all.map((e) {
          final m = e as Map<String, dynamic>;
          return _CategoryOption(
            id: m['id'] as String,
            name: m['name'] as String,
            color: m['color'] as String?,
          );
        }).toList();
        _loadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<_CategoryOption> get _filteredCategories =>
      _categories.where((c) => c.name.isNotEmpty).toList();

  void _submit() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;
    final amountFen = (double.parse(amountText) * 100).round();

    context.read<BillsBloc>().add(BillsCreate(
          transaction: TransactionCreate(
            amount: amountFen,
            type: _type,
            categoryId: _selectedCategoryId,
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          ),
        ));
    Navigator.of(context).pop();
  }

  Color _parseColor(String? hex) {
    if (hex != null && hex.length >= 6) {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
    }
    return AppColors.gray400;
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
          // Type toggle
          Row(
            children: [
              _typeToggle('expense', '支出', AppColors.expenseRed500),
              const SizedBox(width: AppSpacing.sm),
              _typeToggle('income', '收入', AppColors.incomeGreen600),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Amount input
          AppInput(
            label: '金额（元）',
            hintText: '例如: 100.00',
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.md),
          // Category grid
          const Text('分类', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
          const SizedBox(height: AppSpacing.sm),
          if (_loadingCategories)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else if (_filteredCategories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text('暂无分类', style: TextStyle(fontSize: 13, color: AppColors.gray400)),
            )
          else
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filteredCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, index) {
                  final cat = _filteredCategories[index];
                  final isSelected = _selectedCategoryId == cat.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryId = cat.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isSelected ? _parseColor(cat.color).withValues(alpha: 0.15) : AppColors.gray100,
                        borderRadius: AppRadius.fullRadius,
                        border: isSelected ? Border.all(color: _parseColor(cat.color), width: 1.5) : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              color: _parseColor(cat.color),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? AppColors.gray900 : AppColors.gray700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          // Note input
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
