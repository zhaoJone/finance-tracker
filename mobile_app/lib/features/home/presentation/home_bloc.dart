import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/home_models.dart';
import '../data/home_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _repository;

  HomeBloc(this._repository) : super(HomeInitial()) {
    on<HomeLoad>(_onLoad);
    on<HomeMonthChanged>(_onMonthChanged);
  }

  Future<void> _onLoad(HomeLoad event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      final now = DateTime.now();
      final year = event.year ?? now.year;
      final month = event.month ?? now.month;

      final results = await Future.wait([
        _repository.getMonthlySummary(year: year, month: month),
        _repository.getCategoryBreakdown(year: year, month: month),
        _repository.getRecentTransactions(year: year, month: month),
      ]);

      emit(HomeLoaded(
        summary: results[0] as MonthlySummary,
        breakdown: results[1] as CategoryBreakdownResponse,
        recentTxs: (results[2] as List).cast<Transaction>(),
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onMonthChanged(HomeMonthChanged event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      final results = await Future.wait([
        _repository.getMonthlySummary(year: event.year, month: event.month),
        _repository.getCategoryBreakdown(year: event.year, month: event.month),
        _repository.getRecentTransactions(year: event.year, month: event.month),
      ]);

      emit(HomeLoaded(
        summary: results[0] as MonthlySummary,
        breakdown: results[1] as CategoryBreakdownResponse,
        recentTxs: (results[2] as List).cast<Transaction>(),
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
