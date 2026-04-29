import 'package:equatable/equatable.dart';
import '../data/categories_models.dart';

abstract class CategoriesEvent extends Equatable {
  const CategoriesEvent();

  @override
  List<Object?> get props => [];
}

class CategoriesLoad extends CategoriesEvent {}

class CategoriesCreate extends CategoriesEvent {
  final Category category;

  const CategoriesCreate({required this.category});

  @override
  List<Object?> get props => [category];
}

class CategoriesUpdate extends CategoriesEvent {
  final String id;
  final Category category;

  const CategoriesUpdate({required this.id, required this.category});

  @override
  List<Object?> get props => [id, category];
}

class CategoriesDelete extends CategoriesEvent {
  final String id;

  const CategoriesDelete({required this.id});

  @override
  List<Object?> get props => [id];
}
