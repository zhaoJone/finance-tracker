import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/bills_repository.dart';
import 'bills_event.dart';
import 'bills_state.dart';

class BillsBloc extends Bloc<BillsEvent, BillsState> {
  final BillsRepository _repository;

  BillsBloc(this._repository) : super(BillsInitial()) {
    on<BillsLoad>(_onLoad);
    on<BillsCreate>(_onCreate);
    on<BillsDelete>(_onDelete);
    on<BillsFilter>(_onFilter);
  }

  Future<void> _onLoad(BillsLoad event, Emitter<BillsState> emit) async {
    emit(BillsLoading());
    try {
      final txs = await _repository.listTransactions(
        type: event.type,
        year: event.year,
        month: event.month,
      );
      emit(BillsLoaded(transactions: txs, activeFilter: event.type));
    } catch (e) {
      emit(BillsError(e.toString()));
    }
  }

  Future<void> _onCreate(BillsCreate event, Emitter<BillsState> emit) async {
    try {
      await _repository.createTransaction(event.transaction);
      final txs = await _repository.listTransactions();
      emit(BillsLoaded(transactions: txs));
    } catch (e) {
      final lastState = state;
      final lastTxs = lastState is BillsLoaded ? lastState.transactions : null;
      emit(BillsError(e.toString(), lastTransactions: lastTxs));
    }
  }

  Future<void> _onDelete(BillsDelete event, Emitter<BillsState> emit) async {
    try {
      await _repository.deleteTransaction(event.id);
      final txs = await _repository.listTransactions();
      emit(BillsLoaded(transactions: txs));
    } catch (e) {
      final lastState = state;
      final lastTxs = lastState is BillsLoaded ? lastState.transactions : null;
      emit(BillsError(e.toString(), lastTransactions: lastTxs));
    }
  }

  void _onFilter(BillsFilter event, Emitter<BillsState> emit) {
    if (state is BillsLoaded) {
      final current = state as BillsLoaded;
      emit(BillsLoaded(
        transactions: current.transactions,
        activeFilter: event.type,
      ));
    }
  }
}
