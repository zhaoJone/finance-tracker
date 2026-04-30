import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/bills_models.dart';
import 'bills_bloc.dart';
import 'bills_event.dart';
import 'bills_state.dart';
import 'bills_sheets.dart';

class BillsPage extends StatelessWidget {
  const BillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return BlocProvider(
      create: (_) => context.read<BillsBloc>()..add(BillsLoad(year: now.year, month: now.month)),
      child: const _BillsBody(),
    );
  }
}

class _BillsBody extends StatelessWidget {
  const _BillsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BillsBloc, BillsState>(
      builder: (context, state) {
        if (state is BillsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is BillsError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.message, style: const TextStyle(color: AppColors.expenseRed500)),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.read<BillsBloc>().add(const BillsLoad()),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }
        if (state is BillsLoaded) {
          return _BillsContent(transactions: state.transactions, activeFilter: state.activeFilter);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _BillsContent extends StatefulWidget {
  final List<Transaction> transactions;
  final String? activeFilter;

  const _BillsContent({required this.transactions, this.activeFilter});

  @override
  State<_BillsContent> createState() => _BillsContentState();
}

class _BillsContentState extends State<_BillsContent> {
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.activeFilter;
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
      ),
      builder: (_) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final bloc = context.read<BillsBloc>();
          await bloc.stream.firstWhere((s) => s is BillsLoaded || s is BillsError);
          bloc.add(const BillsLoad());
        },
        child: CustomScrollView(
          slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: '全部',
                      selected: _selectedFilter == null,
                      onTap: () {
                        setState(() => _selectedFilter = null);
                        final now = DateTime.now();
                        context.read<BillsBloc>().add(BillsLoad(year: now.year, month: now.month));
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      label: '收入',
                      selected: _selectedFilter == 'income',
                      onTap: () {
                        setState(() => _selectedFilter = 'income');
                        final now = DateTime.now();
                        context.read<BillsBloc>().add(BillsLoad(type: 'income', year: now.year, month: now.month));
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      label: '支出',
                      selected: _selectedFilter == 'expense',
                      onTap: () {
                        setState(() => _selectedFilter = 'expense');
                        final now = DateTime.now();
                        context.read<BillsBloc>().add(BillsLoad(type: 'expense', year: now.year, month: now.month));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.transactions.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(icon: Icons.receipt_long_outlined, title: '暂无交易记录'),
            )
          else
            ..._groupTransactions(widget.transactions).entries.map(
                  (entry) => SliverToBoxAdapter(
                    child: _DateGroup(date: entry.key, transactions: entry.value),
                  ),
                ),
        ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gray900,
        foregroundColor: AppColors.surface,
        onPressed: _showAddSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  Map<String, List<Transaction>> _groupTransactions(List<Transaction> txs) {
    final grouped = <String, List<Transaction>>{};
    for (final tx in txs) {
      final key = '${tx.createdAt.year}-${tx.createdAt.month}-${tx.createdAt.day}';
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final k in sortedKeys) k: grouped[k]!};
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.gray900 : AppColors.gray100,
          borderRadius: AppRadius.fullRadius,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.surface : AppColors.gray700,
          ),
        ),
      ),
    );
  }
}

class _DateGroup extends StatelessWidget {
  final String date;
  final List<Transaction> transactions;

  const _DateGroup({required this.date, required this.transactions});

  String _formatDateKey(String key) {
    final parts = key.split('-');
    return '${parts[0]}年${parts[1]}月${parts[2]}日';
  }

  String _formatAmount(int cents, String type) {
    final yuan = cents / 100;
    final formatter = NumberFormat('#,##0.00', 'zh_CN');
    final prefix = type == 'income' ? '+' : '-';
    return '$prefix¥${formatter.format(yuan)}';
  }

  Color _amountColor(String type) {
    return type == 'income' ? AppColors.incomeGreen600 : AppColors.expenseRed500;
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(_formatDateKey(date), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray500)),
          ),
          ...transactions.map((tx) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Dismissible(
                  key: ValueKey(tx.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.expenseRed500,
                      borderRadius: AppRadius.mdRadius,
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
                  ),
                  onDismissed: (_) {
                    context.read<BillsBloc>().add(BillsDelete(id: tx.id));
                  },
                  child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(tx.categoryColor).withOpacity(0.15),
                          borderRadius: AppRadius.fullRadius,
                        ),
                        child: Center(child: Icon(Icons.circle, size: 14, color: _getCategoryColor(tx.categoryColor))),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.note ?? tx.categoryName ?? '未分类',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray900),
                            ),
                            if (tx.categoryName != null && tx.categoryName!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(tx.categoryName!, style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        _formatAmount(tx.amount, tx.type),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _amountColor(tx.type)),
                      ),
                    ],
                  ),
                ),
              ))),
        ],
      ),
    );
  }
}
