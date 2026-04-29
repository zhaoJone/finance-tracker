import 'package:equatable/equatable.dart';
import '../data/bills_models.dart';

abstract class BillsState extends Equatable {
  const BillsState();

  @override
  List<Object?> get props => [];
}

class BillsInitial extends BillsState {}

class BillsLoading extends BillsState {}

class BillsLoaded extends BillsState {
  final List<Transaction> transactions;
  final String? activeFilter;

  const BillsLoaded({required this.transactions, this.activeFilter});

  @override
  List<Object?> get props => [transactions, activeFilter];
}

class BillsError extends BillsState {
  final String message;

  const BillsError(this.message);

  @override
  List<Object?> get props => [message];
}
