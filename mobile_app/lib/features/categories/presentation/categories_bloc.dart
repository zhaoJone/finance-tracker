import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/categories_repository.dart';
import 'categories_event.dart';
import 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoriesRepository _repository;

  CategoriesBloc(this._repository) : super(CategoriesInitial()) {
    on<CategoriesLoad>(_onLoad);
    on<CategoriesCreate>(_onCreate);
    on<CategoriesUpdate>(_onUpdate);
    on<CategoriesDelete>(_onDelete);
  }

  Future<void> _onLoad(CategoriesLoad event, Emitter<CategoriesState> emit) async {
    emit(CategoriesLoading());
    try {
      final categories = await _repository.listCategories();
      emit(CategoriesLoaded(categories: categories));
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }

  Future<void> _onCreate(CategoriesCreate event, Emitter<CategoriesState> emit) async {
    try {
      await _repository.createCategory(event.category);
      final categories = await _repository.listCategories();
      emit(CategoriesLoaded(categories: categories));
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }

  Future<void> _onUpdate(CategoriesUpdate event, Emitter<CategoriesState> emit) async {
    try {
      await _repository.updateCategory(event.id, event.category);
      final categories = await _repository.listCategories();
      emit(CategoriesLoaded(categories: categories));
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }

  Future<void> _onDelete(CategoriesDelete event, Emitter<CategoriesState> emit) async {
    try {
      await _repository.deleteCategory(event.id);
      final categories = await _repository.listCategories();
      emit(CategoriesLoaded(categories: categories));
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }
}
