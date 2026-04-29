import 'package:equatable/equatable.dart';
import '../data/home_models.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final MonthlySummary summary;
  final CategoryBreakdown breakdown;
  final List<Transaction> recentTxs;

  const HomeLoaded({
    required this.summary,
    required this.breakdown,
    required this.recentTxs,
  });

  @override
  List<Object?> get props => [summary, breakdown, recentTxs];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
