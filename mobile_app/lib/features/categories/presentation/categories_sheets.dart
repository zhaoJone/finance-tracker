import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../../core/widgets/app_button.dart';
import '../data/categories_models.dart';
import 'categories_bloc.dart';
import 'categories_event.dart';

class CategoryFormSheet extends StatefulWidget {
  final Category? existing;

  const CategoryFormSheet({super.key, this.existing});

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _nameController = TextEditingController();
  late String _type;
  String? _selectedColor;
  int _charCount = 0;
  static const int _maxChars = 10;

  final List<String> _presetColors = [
    '#FF6B6B', '#FF8E53', '#FFCD56', '#4ECDC4',
    '#45B7D1', '#6C5CE7', '#A29BFE', '#FD79A8',
    '#F8B500', '#00B894', '#E17055', '#74B9FF',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _type = widget.existing!.type;
      _selectedColor = widget.existing!.color;
    } else {
      _type = 'expense';
    }
    _charCount = _nameController.text.length;
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final text = _nameController.text;
    if (text.length > _maxChars) {
      _nameController.text = text.substring(0, _maxChars);
      _nameController.selection = TextSelection.fromPosition(
        const TextPosition(offset: _maxChars),
      );
    }
    setState(() => _charCount = _nameController.text.length);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final category = Category(
      id: widget.existing?.id ?? '',
      name: name,
      type: _type,
      color: _selectedColor,
    );

    if (widget.existing != null) {
      context.read<CategoriesBloc>().add(CategoriesUpdate(id: widget.existing!.id, category: category));
    } else {
      context.read<CategoriesBloc>().add(CategoriesCreate(category: category));
    }
    Navigator.of(context).pop();
  }

  Color _parseHex(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
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
          // Drag handle
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
          Center(child: Text(isEditing ? '编辑分类' : '添加分类', style: AppTypography.h2)),
          const SizedBox(height: AppSpacing.lg),

          // Type toggle (only for new categories)
          if (!isEditing) ...[
            const Text('类型', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _typeToggle('expense', '支出', AppColors.expenseRed500),
                const SizedBox(width: AppSpacing.sm),
                _typeToggle('income', '收入', AppColors.incomeGreen600),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Name input with character counter
          AppInput(label: '分类名称', hintText: '例如: 餐饮', controller: _nameController),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$_charCount / $_maxChars',
              style: TextStyle(
                fontSize: 12,
                color: _charCount >= _maxChars ? AppColors.expenseRed500 : AppColors.gray400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Color selection
          const Text('颜色', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _presetColors.map((colorHex) {
              final color = _parseHex(colorHex);
              final isSelected = _selectedColor == colorHex;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = colorHex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: AppColors.gray900, width: 2.5) : null,
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: AppButton(label: isEditing ? '保存' : '添加', onTap: _submit),
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
              fontSize: 14,
            )),
          ),
        ),
      ),
    );
  }
}
