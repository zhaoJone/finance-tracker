import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeLoad extends HomeEvent {
  final int? year;
  final int? month;

  const HomeLoad({this.year, this.month});

  @override
  List<Object?> get props => [year, month];
}

class HomeMonthChanged extends HomeEvent {
  final int year;
  final int month;

  const HomeMonthChanged({required this.year, required this.month});

  @override
  List<Object?> get props => [year, month];
}
