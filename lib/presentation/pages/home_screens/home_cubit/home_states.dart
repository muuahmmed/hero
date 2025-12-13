import '../../../../data/models/product_model.dart';

sealed class HomeState {}

final class HomeInitial extends HomeState {}

final class HomeLoading extends HomeState {}

final class HomeLoaded extends HomeState {
  final List<Product> products;
  final List<Product>? featuredProducts;
  final List<Product>? recommendedProducts;

  HomeLoaded({
    required this.products,
    this.featuredProducts,
    this.recommendedProducts,
  });

  HomeLoaded copyWith({
    List<Product>? products,
    List<Product>? featuredProducts,
    List<Product>? recommendedProducts,
  }) {
    return HomeLoaded(
      products: products ?? this.products,
      featuredProducts: featuredProducts ?? this.featuredProducts,
      recommendedProducts: recommendedProducts ?? this.recommendedProducts,
    );
  }
}

final class HomeError extends HomeState {
  final String error;

  HomeError({required this.error});
}
