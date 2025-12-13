import 'package:bloc/bloc.dart';
import 'package:hero/data/services/category_service.dart';

import 'categories_states.dart';


class CategoriesCubit extends Cubit<CategoriesState> {
  final CategoryService _categoryService;

  CategoriesCubit(this._categoryService) : super(CategoriesInitial());

  Future<void> fetchCategories() async {
    emit(CategoriesLoading());
    try {
      final categories = await _categoryService.getCategoriesWithProductCount();
      emit(CategoriesLoaded(categories: categories));
    } catch (e) {
      emit(CategoriesError(error: e.toString()));
    }
  }
}