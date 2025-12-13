
import '../../../../../data/models/category_model.dart';

sealed class CategoriesState {}

final class CategoriesInitial extends CategoriesState {}

final class CategoriesLoading extends CategoriesState {}

final class CategoriesLoaded extends CategoriesState {
  final List<Category> categories;

  CategoriesLoaded({required this.categories});
}

final class CategoriesError extends CategoriesState {
  final String error;

  CategoriesError({required this.error});
}