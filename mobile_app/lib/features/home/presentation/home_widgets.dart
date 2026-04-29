import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/home_models.dart';

class MonthNav extends StatelessWidget {
  final int year;
  final int month;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const MonthNav({
    super.key,
    required this.year,
    required this.month,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final label = '$year年${month.toString().padLeft(2, '0')}月';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Text(label, style: AppTypography.h2),
        IconButton(
          onPressed: canGoNext ? onNext : null,
          icon: Icon(Icons.chevron_right, color: canGoNext ? null : AppColors.gray300),
        ),
      ],
    );
  }
}

class SummaryCards extends StatelessWidget {
  final MonthlySummary summary;

  const SummaryCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _SummaryCard(label: '收入', amount: summary.totalIncome, color: AppColors.incomeGreen600)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _SummaryCard(label: '支出', amount: summary.totalExpense, color: AppColors.expenseRed500)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _BalanceCard(amount: summary.balance),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;

  const _SummaryCard({required this.label, required this.amount, required this.color});

  String _formatAmount(int cents) {
    final yuan = cents / 100;
    final formatter = NumberFormat('#,##0.00', 'zh_CN');
    return '¥${formatter.format(yuan)}';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
          const SizedBox(height: AppSpacing.sm),
          Text(_formatAmount(amount), style: AppTypography.amountLarge.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final int amount;

  const _BalanceCard({required this.amount});

  String _formatAmount(int cents) {
    final yuan = cents / 100;
    final formatter = NumberFormat('#,##0.00', 'zh_CN');
    return '¥${formatter.format(yuan)}';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('结余', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
          Text(
            _formatAmount(amount),
            style: AppTypography.amountLarge.copyWith(color: AppColors.balanceBlue600),
          ),
        ],
      ),
    );
  }
}

class CategoryBreakdownSection extends StatelessWidget {
  final CategoryBreakdown breakdown;

  const CategoryBreakdownSection({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('分类统计', style: AppTypography.h2),
        const SizedBox(height: AppSpacing.md),
        if (breakdown.items.isEmpty)
          const EmptyState(icon: Icons.pie_chart_outline, title: '暂无分类数据')
        else
          ...breakdown.items.map((item) => _CategoryBar(item: item)),
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final CategorySummary item;

  const _CategoryBar({required this.item});

  String _formatAmount(int cents) {
    final yuan = cents / 100;
    final formatter = NumberFormat('#,##0.00', 'zh_CN');
    return '¥${formatter.format(yuan)}';
  }

  Color _getCategoryColor() {
    if (item.categoryColor != null) {
      final hex = item.categoryColor!.replaceAll('#', '');
      if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    }
    return AppColors.gray400;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 10,
                    decoration: BoxDecoration(color: _getCategoryColor(), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(item.categoryName, style: const TextStyle(fontSize: 14, color: AppColors.gray700)),
                ],
              ),
              Text(
                '${item.percentage.toStringAsFixed(1)}%  ${_formatAmount(item.totalAmount)}',
                style: const TextStyle(fontSize: 13, color: AppColors.gray500),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadius.smRadius,
            child: LinearProgressIndicator(
              value: item.percentage / 100,
              backgroundColor: AppColors.gray100,
              valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor()),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class RecentTransactionsSection extends StatelessWidget {
  final List<Transaction> transactions;

  const RecentTransactionsSection({super.key, required this.transactions});

  String _formatAmount(int cents, String type) {
    final yuan = cents / 100;
    final formatter = NumberFormat('#,##0.00', 'zh_CN');
    final prefix = type == 'income' ? '+' : '-';
    return '$prefix¥${formatter.format(yuan)}';
  }

  Color _amountColor(String type) {
    return type == 'income' ? AppColors.incomeGreen600 : AppColors.expenseRed500;
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}年${dt.month.toString().padLeft(2, '0')}月${dt.day.toString().padLeft(2, '0')}日';
  }

  Color _getCategoryColor(String? color) {
    if (color != null) {
      final hex = color.replaceAll('#', '');
      if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    }
    return AppColors.gray400;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('最近交易', style: AppTypography.h2),
        const SizedBox(height: AppSpacing.md),
        if (transactions.isEmpty)
          const EmptyState(icon: Icons.receipt_long_outlined, title: '暂无交易记录')
        else
          ...transactions.map((tx) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(tx.categoryColor).withValues(alpha: 0.15),
                          borderRadius: AppRadius.fullRadius,
                        ),
                        child: Center(
                          child: Icon(Icons.circle, size: 14, color: _getCategoryColor(tx.categoryColor)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.categoryName ?? tx.note ?? '未分类',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray900),
                            ),
                            const SizedBox(height: 2),
                            Text(_formatDate(tx.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
                          ],
                        ),
                      ),
                      Text(
                        _formatAmount(tx.amount, tx.type),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _amountColor(tx.type)),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}
