import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/services/category_service.dart';
import '../Product_Card/Product_Card_widget.dart';
import '../Product_Card/Product_detail_screen.dart';
import '../cart_screen/cart_cubit/cart_cubit.dart';
import '../cart_screen/cart_cubit/cart_states.dart';
import '../categories/categories_cubit/categories_cubit.dart';
import '../categories/categories_cubit/categories_states.dart';
import '../categories/categories_screen.dart';
import '../home_cubit/home_cubit.dart';
import '../home_cubit/home_states.dart';
import '../section_header/section_header_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final CategoriesCubit _categoriesCubit;

  int? _selectedCategoryId;
  String? _selectedCategoryName;

  @override
  void initState() {
    super.initState();
    _categoriesCubit = CategoriesCubit(CategoryService());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeCubit>().fetchProducts();
      context.read<HomeCubit>().fetchFeaturedProducts();
      _categoriesCubit.fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _categoriesCubit.close();
    super.dispose();
  }

  void _clearCategoryFilter() {
    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryName = null;
    });
  }

  // Safe helper — returns null if CartCubit is not in the tree
  CartCubit? get _cartCubit {
    try {
      return context.read<CartCubit>();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) => _buildContent(context, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Brand icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Tagline
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Hero Fitness',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Premium supplements for your journey',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Cart button — safe: works even without CartCubit in tree
              _buildCartButton(context),
            ],
          ),

          const SizedBox(height: 14),

          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {});
                context.read<HomeCubit>().searchProducts(value);
              },
              decoration: InputDecoration(
                hintText: 'Search supplements, protein...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                border: InputBorder.none,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        color: Colors.grey[400],
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          context.read<HomeCubit>().fetchProducts();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cart button that degrades gracefully when CartCubit is absent.
  Widget _buildCartButton(BuildContext context) {
    // If CartCubit is not provided above, render a simple icon without a badge
    final hasCubit =
        context.findAncestorWidgetOfExactType<BlocProvider<CartCubit>>() !=
        null;

    if (!hasCubit) {
      return GestureDetector(
        onTap: () => context.go('/cart'),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.shopping_cart_outlined,
            color: Colors.black87,
            size: 22,
          ),
        ),
      );
    }

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        final itemCount = cartState is CartLoaded
            ? cartState.items.fold<int>(0, (sum, item) => sum + item.quantity)
            : 0;
        return GestureDetector(
          onTap: () => context.go('/cart'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.black87,
                  size: 22,
                ),
              ),
              if (itemCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        itemCount > 9 ? '9+' : '$itemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONTENT ROUTER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, HomeState state) {
    if (state is HomeLoading) return _buildLoading();
    if (state is HomeError) return _buildError(context, state);
    if (state is HomeLoaded) return _buildLoadedContent(context, state);
    return _buildEmpty();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOADING
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading products...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ERROR
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildError(BuildContext context, HomeError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              state.error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<HomeCubit>().fetchProducts(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOADED CONTENT
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildLoadedContent(BuildContext context, HomeLoaded state) {
    if (state.products.isEmpty) return _buildEmpty();

    final List<Product> displayedProducts = _selectedCategoryId != null
        ? state.products
              .where((p) => p.categoryId == _selectedCategoryId)
              .toList()
        : state.products;

    final bool isSearching = _searchController.text.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () async {
        _clearCategoryFilter();
        final homeCubit = context.read<HomeCubit>();
        await homeCubit.fetchProducts();
        await homeCubit.fetchFeaturedProducts();
        await _categoriesCubit.fetchCategories();
      },
      color: const Color(0xFF3B82F6),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // ── Featured Products ────────────────────────────────────────
          if (state.featuredProducts?.isNotEmpty == true &&
              _selectedCategoryId == null &&
              !isSearching) ...[
            SectionHeader(
              title: '⭐ Featured Products',
              onSeeAll: () =>
                  _showAllFeatured(context, state.featuredProducts!),
            ),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.featuredProducts!.length,
                itemBuilder: (context, index) {
                  final product = state.featuredProducts![index];
                  return Container(
                    width: 180,
                    margin: EdgeInsets.only(
                      right: index == state.featuredProducts!.length - 1
                          ? 0
                          : 12,
                    ),
                    child: ProductCard(
                      product: product,
                      isFeatured: true,
                      onTap: () => _navigateToProduct(context, product),
                      onFavoriteToggle: () => context
                          .read<HomeCubit>()
                          .toggleProductFavorite(product.id),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Categories Row ───────────────────────────────────────────
          if (!isSearching) _buildCategoriesSection(context),

          // ── Active Filter Chip ───────────────────────────────────────
          if (_selectedCategoryId != null && _selectedCategoryName != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list,
                    size: 18,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(_selectedCategoryName!),
                    backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                    labelStyle: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w600,
                    ),
                    deleteIcon: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFF3B82F6),
                    ),
                    onDeleted: _clearCategoryFilter,
                    side: BorderSide.none,
                  ),
                ],
              ),
            ),

          // ── Products Grid Header ─────────────────────────────────────
          SectionHeader(
            title: _selectedCategoryName != null
                ? '🛍️ $_selectedCategoryName'
                : '🛍️ All Products',
            onSeeAll: null,
          ),

          // ── Products Grid or Empty ───────────────────────────────────
          if (displayedProducts.isEmpty)
            _buildCategoryEmpty()
          else
            _buildProductsGrid(context, displayedProducts),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CATEGORIES SECTION
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCategoriesSection(BuildContext context) {
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      bloc: _categoriesCubit,
      builder: (context, state) {
        return Column(
          children: [
            SectionHeader(
              title: '📂 Categories',
              onSeeAll: () {
                // Pass CartCubit down only if it exists
                final cart = _cartCubit;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      final providers = <BlocProvider>[
                        BlocProvider.value(value: _categoriesCubit),
                      ];
                      if (cart != null) {
                        providers.add(BlocProvider.value(value: cart));
                      }
                      return MultiBlocProvider(
                        providers: providers,
                        child: const CategoriesScreen(),
                      );
                    },
                  ),
                );
              },
            ),
            _buildCategoriesList(context, state),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildCategoriesList(BuildContext context, CategoriesState state) {
    if (state is CategoriesLoading) {
      return SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey[300],
          ),
        ),
      );
    }

    if (state is CategoriesError) {
      return SizedBox(
        height: 80,
        child: Center(
          child: TextButton.icon(
            onPressed: () => _categoriesCubit.fetchCategories(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry loading categories'),
          ),
        ),
      );
    }

    if (state is CategoriesLoaded) {
      final categories = state.categories.take(8).toList();
      return SizedBox(
        height: 110,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final categoryColor = _getCategoryColor(category.name);
            final isSelected = _selectedCategoryId == category.id;

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedCategoryId = null;
                    _selectedCategoryName = null;
                  } else {
                    _selectedCategoryId = category.id;
                    _selectedCategoryName = category.name;
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                margin: EdgeInsets.only(
                  right: index == categories.length - 1 ? 0 : 12,
                ),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isSelected
                              ? [categoryColor, categoryColor.withOpacity(0.7)]
                              : [
                                  categoryColor.withOpacity(0.15),
                                  categoryColor.withOpacity(0.08),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: categoryColor.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                        border: Border.all(
                          color: isSelected
                              ? categoryColor
                              : categoryColor.withOpacity(0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _getCategoryIcon(category.name),
                          color: isSelected ? Colors.white : categoryColor,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected ? categoryColor : Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRODUCTS GRID
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildProductsGrid(BuildContext context, List<Product> products) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.62,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              product: product,
              onTap: () => _navigateToProduct(context, product),
              onFavoriteToggle: () =>
                  context.read<HomeCubit>().toggleProductFavorite(product.id),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EMPTY STATES
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for something else',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryEmpty() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No products in this category',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _clearCategoryFilter,
            child: const Text('Show all products'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NAVIGATION HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  void _navigateToProduct(BuildContext context, Product product) {
    final cart = _cartCubit;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (cart != null) {
            return BlocProvider.value(
              value: cart,
              child: ProductDetailScreen(product: product),
            );
          }
          return ProductDetailScreen(product: product);
        },
      ),
    );
  }

  void _showAllFeatured(BuildContext context, List<Product> products) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Showing all featured products'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CATEGORY COLOR & ICON HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Color _getCategoryColor(String categoryName) {
    final n = categoryName.toLowerCase();
    if (n.contains('mass') || n.contains('gain')) {
      return const Color(0xFFFF9800);
    }
    if (n.contains('protein') || n.contains('whey')) {
      return const Color(0xFF2196F3);
    }
    if (n.contains('creatine')) return const Color(0xFF9C27B0);
    if (n.contains('fat') || n.contains('burn')) return const Color(0xFFF44336);
    if (n.contains('vitamin')) return const Color(0xFF4CAF50);
    if (n.contains('accessory') || n.contains('equipment')) {
      return const Color(0xFF795548);
    }
    if (n.contains('pre-workout')) return const Color(0xFFFF5722);
    if (n.contains('amino') || n.contains('eaa')) {
      return const Color(0xFF00BCD4);
    }
    return const Color(0xFF3B82F6);
  }

  IconData _getCategoryIcon(String categoryName) {
    final n = categoryName.toLowerCase();
    if (n.contains('mass') || n.contains('gain')) return Icons.monitor_weight;
    if (n.contains('protein') || n.contains('whey')) {
      return Icons.fitness_center;
    }
    if (n.contains('creatine')) return Icons.bolt;
    if (n.contains('fat') || n.contains('burn')) {
      return Icons.local_fire_department;
    }
    if (n.contains('vitamin')) return Icons.health_and_safety;
    if (n.contains('accessory') || n.contains('equipment')) return Icons.sports;
    if (n.contains('pre-workout')) return Icons.energy_savings_leaf;
    if (n.contains('amino') || n.contains('eaa')) return Icons.science;
    return Icons.category;
  }
}
