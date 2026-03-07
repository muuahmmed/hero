import 'package:bloc/bloc.dart';
import 'package:hero/data/models/product_model.dart';
import 'package:hero/data/services/product_service.dart';
import 'package:hero/data/services/profile_service.dart';
import 'home_states.dart';

class HomeCubit extends Cubit<HomeState> {
  final ProductService _productService;
  final ProfileService _profileService = ProfileService();

  HomeCubit(this._productService) : super(HomeInitial());

  // ── Fetch all products + mark which ones are in wishlist ──────────────────
  Future<void> fetchProducts() async {
    emit(HomeLoading());
    try {
      final List<Product> products = await _productService.getProducts();
      final Set<int> wishlistIds = await _profileService.getWishlistIds();

      final marked = products
          .map((p) => p.copyWith(isFavorite: wishlistIds.contains(p.id)))
          .toList();

      final currentState = this.state;
      emit(
        HomeLoaded(
          products: marked,
          featuredProducts: currentState is HomeLoaded
              ? currentState.featuredProducts
              : null,
        ),
      );
    } catch (e) {
      emit(HomeError(error: e.toString()));
    }
  }

  Future<void> fetchFeaturedProducts() async {
    try {
      final List<Product> featured = await _productService
          .getFeaturedProducts();
      final Set<int> wishlistIds = await _profileService.getWishlistIds();

      final marked = featured
          .map((p) => p.copyWith(isFavorite: wishlistIds.contains(p.id)))
          .toList();

      final state = this.state;
      if (state is HomeLoaded) {
        emit(state.copyWith(featuredProducts: marked));
      }
    } catch (e) {
      // silently fail — featured is non-critical
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      await fetchProducts();
      return;
    }
    emit(HomeLoading());
    try {
      final List<Product> products = await _productService.searchProducts(
        query,
      );
      final Set<int> wishlistIds = await _profileService.getWishlistIds();

      final marked = products
          .map((p) => p.copyWith(isFavorite: wishlistIds.contains(p.id)))
          .toList();

      emit(HomeLoaded(products: marked));
    } catch (e) {
      emit(HomeError(error: e.toString()));
    }
  }

  // ── Toggle wishlist — saves to Supabase + updates local state ─────────────
  Future<void> toggleProductFavorite(int productId) async {
    final state = this.state;
    if (state is! HomeLoaded) return;

    // 1. Optimistic local update
    final newFav =
        !(state.products
                .firstWhere(
                  (p) => p.id == productId,
                  orElse: () => state.products.first,
                )
                .isFavorite ??
            false);

    final List<Product> updatedProducts = state.products.map((p) {
      return p.id == productId ? p.copyWith(isFavorite: newFav) : p;
    }).toList();

    final List<Product>? updatedFeatured = state.featuredProducts?.map((p) {
      return p.id == productId ? p.copyWith(isFavorite: newFav) : p;
    }).toList();

    emit(
      state.copyWith(
        products: updatedProducts,
        featuredProducts: updatedFeatured,
      ),
    );

    // 2. Persist to Supabase — rethrow so UI can catch and show error
    await _profileService.toggleWishlist(productId);
  }
}
