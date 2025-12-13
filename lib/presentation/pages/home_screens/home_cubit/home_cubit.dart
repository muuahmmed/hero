import 'package:bloc/bloc.dart';
import 'package:hero/data/services/product_service.dart';
import 'home_states.dart';

class HomeCubit extends Cubit<HomeState> {
  final ProductService _productService;

  HomeCubit(this._productService) : super(HomeInitial());

  Future<void> fetchProducts() async {
    emit(HomeLoading());
    try {
      final products = await _productService.getProducts();
      emit(HomeLoaded(products: products));
    } catch (e) {
      emit(HomeError(error: e.toString()));
    }
  }

  Future<void> fetchFeaturedProducts() async {
    try {
      final featuredProducts = await _productService.getFeaturedProducts();
      final state = this.state;
      if (state is HomeLoaded) {
        emit(state.copyWith(featuredProducts: featuredProducts));
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      await fetchProducts();
      return;
    }

    emit(HomeLoading());
    try {
      final filteredProducts = await _productService.searchProducts(query);
      emit(HomeLoaded(products: filteredProducts));
    } catch (e) {
      emit(HomeError(error: e.toString()));
    }
  }

  void toggleProductFavorite(int productId) {
    final state = this.state;
    if (state is HomeLoaded) {
      final updatedProducts = state.products.map((product) {
        if (product.id == productId) {
          return product.copyWith(isFavorite: !(product.isFavorite ?? false));
        }
        return product;
      }).toList();

      emit(state.copyWith(products: updatedProducts));
    }
  }
}
