import 'package:equatable/equatable.dart';
import '../data/bills_models.dart';

abstract class BillsEvent extends Equatable {
  const BillsEvent();

  @override
  List<Object?> get props => [];
}

class BillsLoad extends BillsEvent {
  final String? type;
  final int? year;
  final int? month;

  const BillsLoad({this.type, this.year, this.month});

  @override
  List<Object?> get props => [type, year, month];
}

class BillsCreate extends BillsEvent {
  final TransactionCreate transaction;

  const BillsCreate({required this.transaction});

  @override
  List<Object?> get props => [transaction];
}

class BillsDelete extends BillsEvent {
  final String id;

  const BillsDelete({required this.id});

  @override
  List<Object?> get props => [id];
}

class BillsUpdate extends BillsEvent {
  final String id;
  final TransactionUpdate update;

  const BillsUpdate({required this.id, required this.update});

  @override
  List<Object?> get props => [id, update];
}

class BillsFilter extends BillsEvent {
  final String? type;

  const BillsFilter({this.type});

  @override
  List<Object?> get props => [type];
}
