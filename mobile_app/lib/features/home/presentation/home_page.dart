import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/home_models.dart';
import 'home_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';
import 'home_widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return BlocProvider(
      create: (_) => context.read<HomeBloc>()..add(HomeLoad(year: now.year, month: now.month)),
      child: const _HomeBody(),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is HomeError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.message, style: const TextStyle(color: AppColors.expenseRed500)),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    final now = DateTime.now();
                    context.read<HomeBloc>().add(HomeLoad(year: now.year, month: now.month));
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }
        if (state is HomeLoaded) {
          return _DashboardContent(state: state);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _DashboardContent extends StatefulWidget {
  final HomeLoaded state;

  const _DashboardContent({required this.state});

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.state.summary.year;
    _month = widget.state.summary.month;
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _year--;
        _month = 12;
      } else {
        _month--;
      }
    });
    context.read<HomeBloc>().add(HomeMonthChanged(year: _year, month: _month));
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_year == now.year && _month == now.month) return;
    setState(() {
      if (_month == 12) {
        _year++;
        _month = 1;
      } else {
        _month++;
      }
    });
    context.read<HomeBloc>().add(HomeMonthChanged(year: _year, month: _month));
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final canGoNext = !(_year == DateTime.now().year && _month == DateTime.now().month);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonthNav(
            year: _year,
            month: _month,
            canGoNext: canGoNext,
            onPrev: _prevMonth,
            onNext: _nextMonth,
          ),
          const SizedBox(height: AppSpacing.lg),
          SummaryCards(summary: state.summary),
          const SizedBox(height: AppSpacing.xxl),
          CategoryBreakdownSection(breakdown: state.breakdown),
          const SizedBox(height: AppSpacing.xxl),
          RecentTransactionsSection(transactions: state.recentTxs),
        ],
      ),
    );
  }
}
