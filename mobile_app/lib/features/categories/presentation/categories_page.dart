import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/categories_models.dart';
import 'categories_bloc.dart';
import 'categories_event.dart';
import 'categories_state.dart';
import 'categories_sheets.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => context.read<CategoriesBloc>()..add(CategoriesLoad()),
      child: const _CategoriesBody(),
    );
  }
}

class _CategoriesBody extends StatelessWidget {
  const _CategoriesBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoriesBloc, CategoriesState>(
      builder: (context, state) {
        if (state is CategoriesLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is CategoriesError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.message, style: const TextStyle(color: AppColors.expenseRed500)),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.read<CategoriesBloc>().add(CategoriesLoad()),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }
        if (state is CategoriesLoaded) {
          return _CategoriesContent(categories: state.categories);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _CategoriesContent extends StatefulWidget {
  final List<Category> categories;

  const _CategoriesContent({required this.categories});

  @override
  State<_CategoriesContent> createState() => _CategoriesContentState();
}

class _CategoriesContentState extends State<_CategoriesContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCategorySheet({Category? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.md),
      ),
      builder: (_) => CategoryFormSheet(existing: existing),
    );
  }

  void _confirmDelete(Category category) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除分类'),
        content: Text('确定要删除「${category.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<CategoriesBloc>().add(CategoriesDelete(id: category.id));
            },
            child: const Text('删除', style: TextStyle(color: AppColors.expenseRed500)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incomeCategories =
        widget.categories.where((c) => c.type == 'income').toList();
    final expenseCategories =
        widget.categories.where((c) => c.type == 'expense').toList();

    return Scaffold(
      body: Column(
        children: [
          Material(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.gray900,
              unselectedLabelColor: AppColors.gray400,
              indicatorColor: AppColors.gray900,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(text: '支出'),
                Tab(text: '收入'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CategoryGrid(
                  categories: expenseCategories,
                  onTap: (c) => _showCategorySheet(existing: c),
                  onLongPress: _confirmDelete,
                ),
                _CategoryGrid(
                  categories: incomeCategories,
                  onTap: (c) => _showCategorySheet(existing: c),
                  onLongPress: _confirmDelete,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gray900,
        foregroundColor: AppColors.surface,
        onPressed: () => _showCategorySheet(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final ValueChanged<Category> onTap;
  final ValueChanged<Category> onLongPress;

  const _CategoryGrid({
    required this.categories,
    required this.onTap,
    required this.onLongPress,
  });

  Color _parseColor(String? color) {
    if (color != null) {
      final hex = color.replaceAll('#', '');
      if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    }
    return AppColors.gray400;
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const EmptyState(icon: Icons.category_outlined, title: '暂无分类', subtitle: '点击右下角 + 添加');
    }
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.9,
      ),
      itemCount: categories.length,
      itemBuilder: (_, index) {
        final cat = categories[index];
        return GestureDetector(
          onTap: () => onTap(cat),
          onLongPress: () => onLongPress(cat),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _parseColor(cat.color).withValues(alpha: 0.15),
                    borderRadius: AppRadius.fullRadius,
                  ),
                  child: Center(child: Icon(Icons.circle, size: 18, color: _parseColor(cat.color))),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  cat.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray700),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
