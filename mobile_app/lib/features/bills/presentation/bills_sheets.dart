import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
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
  final String type;

  _CategoryOption({required this.id, required this.name, this.color, required this.type});
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
  DateTime _selectedDate = DateTime.now();

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
            type: m['type'] as String? ?? 'expense',
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
      _categories.where((c) => c.type == _type).toList();

  void _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: now,
      locale: const Locale('zh'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;
    if (_selectedCategoryId == null) return;
    final amountFen = (double.parse(amountText) * 100).round();

    context.read<BillsBloc>().add(BillsCreate(
          transaction: TransactionCreate(
            amount: amountFen,
            type: _type,
            date: DateFormat('yyyy-MM-dd').format(_selectedDate),
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
    final filtered = _filteredCategories;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Center(
              child: Container(
                width: 32, height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Center(child: Text('添加交易', style: AppTypography.h2)),
            const SizedBox(height: AppSpacing.lg),

            // Large amount input
            Center(
              child: Container(
                width: 220,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: TextField(
                  controller: _amountController,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: false,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                  decoration: InputDecoration(
                    prefixText: '¥ ',
                    prefixStyle: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray400,
                    ),
                    hintText: '0.00',
                    hintStyle: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray300,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.mdRadius,
                      borderSide: const BorderSide(color: AppColors.gray200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.mdRadius,
                      borderSide: const BorderSide(color: AppColors.gray200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.mdRadius,
                      borderSide: const BorderSide(color: AppColors.gray900, width: 1.5),
                    ),
                    filled: true,
                    fillColor: AppColors.gray50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Type toggle
            const Text('类型', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _typeToggle('expense', '支出 🔴', AppColors.expenseRed500),
                const SizedBox(width: AppSpacing.sm),
                _typeToggle('income', '收入 🟢', AppColors.incomeGreen600),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Category grid
            const Text('分类', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
            const SizedBox(height: AppSpacing.sm),
            if (_loadingCategories)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              )
            else if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text('暂无分类，请先在分类页面添加', style: TextStyle(fontSize: 13, color: AppColors.gray400)),
              )
            else
              _buildCategoryGrid(filtered),
            const SizedBox(height: AppSpacing.lg),

            // Date picker
            const Text('日期', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: AppRadius.smRadius,
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.gray500),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      DateFormat('yyyy年MM月dd日', 'zh_CN').format(_selectedDate),
                      style: const TextStyle(fontSize: 14, color: AppColors.gray900),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.gray400),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Note input
            const Text('备注（可选）', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _noteController,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                hintText: '例如：午餐、交通费...',
                hintStyle: const TextStyle(fontSize: 14, color: AppColors.gray400),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.smRadius,
                  borderSide: const BorderSide(color: AppColors.gray300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.smRadius,
                  borderSide: const BorderSide(color: AppColors.gray300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.smRadius,
                  borderSide: const BorderSide(color: AppColors.gray900, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                isDense: true,
                filled: true,
                fillColor: AppColors.gray50,
              ),
              style: const TextStyle(fontSize: 14, color: AppColors.gray900),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: '添加',
                onTap: _submit,
                disabled: _selectedCategoryId == null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(List<_CategoryOption> categories) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: categories.map((cat) {
        final isSelected = _selectedCategoryId == cat.id;
        final color = _parseColor(cat.color);
        return GestureDetector(
          onTap: () => setState(() => _selectedCategoryId = cat.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: (MediaQuery.of(context).size.width - 2 * AppSpacing.lg - 3 * AppSpacing.sm) / 4,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.12) : AppColors.gray50,
              borderRadius: AppRadius.smRadius,
              border: Border.all(
                color: isSelected ? color : AppColors.gray200,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.gray900 : AppColors.gray600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _typeToggle(String value, String label, Color activeColor) {
    final isActive = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _type = value;
            _selectedCategoryId = null;
          });
        },
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
              fontSize: 14,
            )),
          ),
        ),
      ),
    );
  }
}
