import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/product_model.dart';
import '../Product_Card/Product_Card_widget.dart';
import '../categories/categories_cubit/categories_cubit.dart';
import '../categories/categories_cubit/categories_states.dart';
import '../categories/categories_screen.dart';
import '../home_cubit/home_cubit.dart';
import '../home_cubit/home_states.dart';
import '../section_header/section_header_screen.dart';
import '../../../../data/services/category_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final CategoriesCubit _categoriesCubit;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Header with Search
            _buildHeader(context),

            // 🔹 Main Content
            Expanded(
              child: BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) {
                  return _buildContent(context, state);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Text
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                context.read<HomeCubit>().searchProducts(value);
              },
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    context.read<HomeCubit>().fetchProducts();
                  },
                )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, HomeState state) {
    if (state is HomeLoading) {
      return _buildLoading();
    }

    if (state is HomeError) {
      return _buildError(context, state);
    }

    if (state is HomeLoaded) {
      return _buildLoadedContent(context, state);
    }

    return _buildEmpty();
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading products...',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, HomeError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              state.error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.read<HomeCubit>().fetchProducts(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, HomeLoaded state) {
    final hasProducts = state.products.isNotEmpty;
    final hasFeatured = state.featuredProducts?.isNotEmpty ?? false;

    if (!hasProducts) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<HomeCubit>().fetchProducts();
        await context.read<HomeCubit>().fetchFeaturedProducts();
        await _categoriesCubit.fetchCategories();
      },
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          // 🔹 Featured Products Section
          if (hasFeatured) ...[
            SectionHeader(
              title: '⭐ Featured Products',
              onSeeAll: () {
                // Navigate to featured products page
              },
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
                      right: index == state.featuredProducts!.length - 1 ? 0 : 12,
                    ),
                    child: ProductCard(
                      product: product,
                      isFeatured: true,
                      onTap: () {
                        _showProductDetails(context, product);
                      },
                      onFavoriteToggle: () {
                        context.read<HomeCubit>().toggleProductFavorite(product.id);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 🔹 Categories Section
          _buildCategoriesSection(context),

          // 🔹 All Products Section
          SectionHeader(
            title: '🛍️ All Products',
            onSeeAll: () {
              // Navigate to all products page
            },
          ),
          // Use a simpler approach for the grid
          _buildSimpleProductsGrid(state.products),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      bloc: _categoriesCubit,
      builder: (context, state) {
        return Column(
          children: [
            SectionHeader(
              title: '📂 Categories',
              onSeeAll: () {
                // Navigate to full categories screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: _categoriesCubit,
                      child: const CategoriesScreen(),
                    ),
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
        height: 100,
        child: Center(
          child: Text(
            'Failed to load categories',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    if (state is CategoriesLoaded) {
      final categories = state.categories.take(5).toList();
      return SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final categoryColor = _getCategoryColor(category.name);

            return GestureDetector(
              onTap: () {
                _showCategoryProducts(context, category);
              },
              child: Container(
                width: 100,
                margin: EdgeInsets.only(
                    right: index == categories.length - 1 ? 0 : 12),
                child: Column(
                  children: [
                    // Category Icon Circle
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            categoryColor,
                            categoryColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: categoryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _getCategoryIcon(category.name),
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Category Name
                    Text(
                      category.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  // Helper methods for HomeScreen
  Color _getCategoryColor(String categoryName) {
    final lowerName = categoryName.toLowerCase();

    if (lowerName.contains('mass') || lowerName.contains('gain')) {
      return const Color(0xFFFF9800);
    } else if (lowerName.contains('protein') || lowerName.contains('whey')) {
      return const Color(0xFF2196F3);
    } else if (lowerName.contains('creatine')) {
      return const Color(0xFF9C27B0);
    } else if (lowerName.contains('fat') || lowerName.contains('burn')) {
      return const Color(0xFFF44336);
    } else if (lowerName.contains('vitamin')) {
      return const Color(0xFF4CAF50);
    } else if (lowerName.contains('accessory') || lowerName.contains('equipment')) {
      return const Color(0xFF795548);
    } else if (lowerName.contains('pre-workout')) {
      return const Color(0xFFFF5722);
    } else if (lowerName.contains('amino') || lowerName.contains('eaa')) {
      return const Color(0xFF00BCD4);
    }
    return const Color(0xFF3B82F6);
  }

  IconData _getCategoryIcon(String categoryName) {
    final lowerName = categoryName.toLowerCase();

    if (lowerName.contains('mass') || lowerName.contains('gain')) {
      return Icons.monitor_weight;
    } else if (lowerName.contains('protein') || lowerName.contains('whey')) {
      return Icons.fitness_center;
    } else if (lowerName.contains('creatine')) {
      return Icons.bolt;
    } else if (lowerName.contains('fat') || lowerName.contains('burn')) {
      return Icons.fireplace;
    } else if (lowerName.contains('vitamin') || lowerName.contains('supplement')) {
      return Icons.health_and_safety;
    } else if (lowerName.contains('accessory') || lowerName.contains('equipment')) {
      return Icons.sports;
    } else if (lowerName.contains('pre-workout')) {
      return Icons.energy_savings_leaf;
    } else if (lowerName.contains('amino') || lowerName.contains('eaa')) {
      return Icons.science;
    }
    return Icons.category;
  }

  void _showCategoryProducts(BuildContext context, Category category) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing ${category.name} products...'),
        duration: const Duration(milliseconds: 500),
      ),
    );

    // TODO: Navigate to category products screen
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => CategoryProductsScreen(category: category),
    //   ),
    // );
  }

  Widget _buildSimpleProductsGrid(List<Product> products) {
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
            childAspectRatio: 0.65, // Adjusted for better fit
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              product: product,
              onTap: () {
                _showProductDetails(context, product);
              },
              onFavoriteToggle: () {
                context.read<HomeCubit>().toggleProductFavorite(product.id);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
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
            style: TextStyle(
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(product.getImageUrl()),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              product.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Price: ${product.price} EGP',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stock: ${product.stock} available',
              style: TextStyle(
                fontSize: 14,
                color: product.stock > 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Add to cart functionality
              Navigator.pop(context);
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }
}