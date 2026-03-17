import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hero/data/models/product_model.dart';
import 'package:hero/presentation/pages/home_screens/Product_Card/Product_Card_widget.dart';
import 'package:hero/presentation/pages/home_screens/Product_Card/Product_detail_screen.dart';
import 'package:hero/presentation/pages/home_screens/cart_screen/cart_cubit/cart_cubit.dart';
import 'package:hero/presentation/pages/home_screens/cart_screen/cart_cubit/cart_states.dart';
import 'package:hero/presentation/pages/home_screens/categories/categories_cubit/categories_cubit.dart';
import 'package:hero/presentation/pages/home_screens/categories/categories_cubit/categories_states.dart';
import 'package:hero/presentation/pages/home_screens/section_header/section_header_screen.dart';
import 'home_cubit/home_cubit.dart';
import 'home_cubit/home_states.dart';

// ── Filter Model ──────────────────────────────────────────────────────────────
class ProductFilter {
  final double? minPrice;
  final double? maxPrice;
  final bool inStockOnly;
  final bool egyptianOnly;
  final String sortBy;

  const ProductFilter({
    this.minPrice,
    this.maxPrice,
    this.inStockOnly = false,
    this.egyptianOnly = false,
    this.sortBy = 'newest',
  });

  bool get isActive =>
      minPrice != null ||
          maxPrice != null ||
          inStockOnly ||
          egyptianOnly ||
          sortBy != 'newest';

  int get activeCount {
    int count = 0;
    if (minPrice != null || maxPrice != null) count++;
    if (inStockOnly) count++;
    if (egyptianOnly) count++;
    if (sortBy != 'newest') count++;
    return count;
  }

  ProductFilter copyWith({
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    bool? egyptianOnly,
    String? sortBy,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
  }) {
    return ProductFilter(
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      inStockOnly: inStockOnly ?? this.inStockOnly,
      egyptianOnly: egyptianOnly ?? this.egyptianOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

// ── HomeScreen ────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int? _selectedCategoryId;
  String? _selectedCategoryName;
  ProductFilter _filter = const ProductFilter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeCubit>().fetchProducts();
      context.read<HomeCubit>().fetchFeaturedProducts();
      context.read<CategoriesCubit>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearCategoryFilter() {
    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryName = null;
    });
  }

  void _applyCurrentFilter() {
    context.read<HomeCubit>().applyFilter(
      query: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      categoryId: _selectedCategoryId,
      minPrice: _filter.minPrice,
      maxPrice: _filter.maxPrice,
      inStockOnly: _filter.inStockOnly ? true : null,
      egyptianOnly: _filter.egyptianOnly ? true : null,
      sortBy: _filter.sortBy,
    );
  }

  void _clearAllFilters() {
    setState(() {
      _filter = const ProductFilter();
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _searchController.clear();
    });
    context.read<HomeCubit>().fetchProducts();
  }

  // ── Filter Bottom Sheet ───────────────────────────────────────────────────
  void _openFilterSheet() async {
    final result = await showModalBottomSheet<ProductFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterBottomSheet(currentFilter: _filter),
    );

    if (result != null) {
      setState(() => _filter = result);
      _applyCurrentFilter();
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

  // ── HEADER ────────────────────────────────────────────────────────────────
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hero Fitness',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Premium supplements',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Cart button
              BlocBuilder<CartCubit, CartState>(
                builder: (context, cartState) {
                  final itemCount = cartState is CartLoaded
                      ? cartState.items
                      .fold<int>(0, (sum, item) => sum + item.quantity)
                      : 0;
                  return Stack(
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
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Search + Filter Row ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {});
                      if (_selectedCategoryId != null) _clearCategoryFilter();
                      _applyCurrentFilter();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search supplements, protein...',
                      hintStyle:
                      TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon:
                      Icon(Icons.search, color: Colors.grey[400]),
                      border: InputBorder.none,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        color: Colors.grey[400],
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          _applyCurrentFilter();
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
              ),
              const SizedBox(width: 10),

              // ── Filter Button ─────────────────────────────────────────────
              GestureDetector(
                onTap: _openFilterSheet,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _filter.isActive
                            ? const Color(0xFF3B82F6)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _filter.isActive
                              ? const Color(0xFF3B82F6)
                              : Colors.grey[200]!,
                        ),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: _filter.isActive
                            ? Colors.white
                            : Colors.grey[600],
                        size: 22,
                      ),
                    ),
                    if (_filter.activeCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${_filter.activeCount}',
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── CONTENT ───────────────────────────────────────────────────────────────
  Widget _buildContent(BuildContext context, HomeState state) {
    if (state is HomeLoading) return _buildLoading();
    if (state is HomeError) return _buildError(context, state);
    if (state is HomeLoaded) return _buildLoadedContent(context, state);
    return _buildEmpty();
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor:
            AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
          const SizedBox(height: 16),
          Text('Loading products...',
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

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
              child:
              Icon(Icons.error_outline, size: 50, color: Colors.red[400]),
            ),
            const SizedBox(height: 20),
            const Text('Something went wrong',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(state.error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<HomeCubit>().fetchProducts(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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

  Widget _buildLoadedContent(BuildContext context, HomeLoaded state) {
    if (state.products.isEmpty) return _buildEmpty();

    final displayedProducts = _selectedCategoryId != null
        ? state.products
        .where((p) => p.categoryId == _selectedCategoryId)
        .toList()
        : state.products;

    final bool isSearching = _searchController.text.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () async {
        _clearAllFilters();
      },
      color: const Color(0xFF3B82F6),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Featured Products
          if (state.featuredProducts?.isNotEmpty == true &&
              _selectedCategoryId == null &&
              !isSearching &&
              !_filter.isActive) ...[
            SectionHeader(title: '⭐ Featured', onSeeAll: null),
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
                      onFavoriteToggle: () async {
                        try {
                          await context
                              .read<HomeCubit>()
                              .toggleProductFavorite(product.id);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Wishlist error: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Categories
          if (!isSearching && !_filter.isActive)
            _buildCategoriesSection(context),

          // Active Filter Chips
          if (_filter.isActive || _selectedCategoryId != null)
            _buildActiveFilterChips(),

          // Products Header
          SectionHeader(
            title: _selectedCategoryName != null
                ? '🛍️ $_selectedCategoryName'
                : _filter.isActive
                ? '🔍 Filtered Results'
                : '🛍️ All Products',
            subtitle: '${displayedProducts.length} products',
            onSeeAll: null,
          ),

          // Products Grid
          if (displayedProducts.isEmpty)
            _buildNoResults()
          else
            _buildProductsGrid(context, displayedProducts),
        ],
      ),
    );
  }

  // ── Active Filter Chips ───────────────────────────────────────────────────
  Widget _buildActiveFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          if (_selectedCategoryName != null)
            _FilterChip(
              label: _selectedCategoryName!,
              icon: Icons.category_outlined,
              onRemove: () {
                _clearCategoryFilter();
                _applyCurrentFilter();
              },
            ),
          if (_filter.minPrice != null || _filter.maxPrice != null)
            _FilterChip(
              label: _filter.minPrice != null && _filter.maxPrice != null
                  ? '${_filter.minPrice!.toInt()} – ${_filter.maxPrice!.toInt()} EGP'
                  : _filter.minPrice != null
                  ? 'From ${_filter.minPrice!.toInt()} EGP'
                  : 'Up to ${_filter.maxPrice!.toInt()} EGP',
              icon: Icons.attach_money,
              onRemove: () {
                setState(() => _filter =
                    _filter.copyWith(clearMinPrice: true, clearMaxPrice: true));
                _applyCurrentFilter();
              },
            ),
          if (_filter.inStockOnly)
            _FilterChip(
              label: 'In Stock',
              icon: Icons.inventory_2_outlined,
              onRemove: () {
                setState(() =>
                _filter = _filter.copyWith(inStockOnly: false));
                _applyCurrentFilter();
              },
            ),
          if (_filter.egyptianOnly)
            _FilterChip(
              label: 'Egyptian',
              icon: Icons.flag_outlined,
              onRemove: () {
                setState(() =>
                _filter = _filter.copyWith(egyptianOnly: false));
                _applyCurrentFilter();
              },
            ),
          if (_filter.sortBy != 'newest')
            _FilterChip(
              label: _getSortLabel(_filter.sortBy),
              icon: Icons.sort,
              onRemove: () {
                setState(
                        () => _filter = _filter.copyWith(sortBy: 'newest'));
                _applyCurrentFilter();
              },
            ),
          // Clear all
          if (_filter.activeCount > 1)
            GestureDetector(
              onTap: _clearAllFilters,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.clear_all, size: 14, color: Colors.red),
                    SizedBox(width: 4),
                    Text(
                      'Clear All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'price_asc':
        return 'Price: Low → High';
      case 'price_desc':
        return 'Price: High → Low';
      case 'name_asc':
        return 'Name A–Z';
      default:
        return 'Newest';
    }
  }

  // ── Categories ────────────────────────────────────────────────────────────
  Widget _buildCategoriesSection(BuildContext context) {
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        return Column(
          children: [
            SectionHeader(title: '📂 Categories', onSeeAll: null),
            _buildCategoriesList(context, state),
            const SizedBox(height: 8),
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
              strokeWidth: 2, color: Colors.grey[300]),
        ),
      );
    }

    if (state is CategoriesLoaded) {
      final categories = state.categories.take(10).toList();
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
                _applyCurrentFilter();
                _scrollController.animateTo(0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                margin: EdgeInsets.only(
                    right: index == categories.length - 1 ? 0 : 12),
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
                          )
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
                          color:
                          isSelected ? Colors.white : categoryColor,
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
                        color: isSelected
                            ? categoryColor
                            : Colors.grey[700],
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

  // ── Products Grid ─────────────────────────────────────────────────────────
  Widget _buildProductsGrid(BuildContext context, List<Product> products) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth > 600 ? 3 : 2,
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
              onFavoriteToggle: () async {
                try {
                  await context
                      .read<HomeCubit>()
                      .toggleProductFavorite(product.id);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Wishlist error: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
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
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No products found',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('No products match your filters',
              style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _clearAllFilters,
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Filters'),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6)),
          ),
        ],
      ),
    );
  }

  void _navigateToProduct(BuildContext context, Product product) {
    final cartCubit = context.read<CartCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cartCubit,
          child: ProductDetailScreen(product: product),
        ),
      ),
    );
  }

  Color _getCategoryColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('mass') || n.contains('gain'))
      return const Color(0xFFFF9800);
    if (n.contains('protein') || n.contains('whey'))
      return const Color(0xFF2196F3);
    if (n.contains('creatine')) return const Color(0xFF9C27B0);
    if (n.contains('fat') || n.contains('burn'))
      return const Color(0xFFF44336);
    if (n.contains('vitamin')) return const Color(0xFF4CAF50);
    if (n.contains('accessory') || n.contains('equipment'))
      return const Color(0xFF795548);
    if (n.contains('pre-workout')) return const Color(0xFFFF5722);
    if (n.contains('amino') || n.contains('eaa'))
      return const Color(0xFF00BCD4);
    return const Color(0xFF3B82F6);
  }

  IconData _getCategoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('mass') || n.contains('gain')) return Icons.monitor_weight;
    if (n.contains('protein') || n.contains('whey'))
      return Icons.fitness_center;
    if (n.contains('creatine')) return Icons.bolt;
    if (n.contains('fat') || n.contains('burn'))
      return Icons.local_fire_department;
    if (n.contains('vitamin')) return Icons.health_and_safety;
    if (n.contains('accessory') || n.contains('equipment')) return Icons.sports;
    if (n.contains('pre-workout')) return Icons.energy_savings_leaf;
    if (n.contains('amino') || n.contains('eaa')) return Icons.science;
    return Icons.category;
  }
}

// ── Filter Chip Widget ────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onRemove;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: Color(0xFF3B82F6)),
          ),
        ],
      ),
    );
  }
}

// ── Filter Bottom Sheet ───────────────────────────────────────────────────────
class _FilterBottomSheet extends StatefulWidget {
  final ProductFilter currentFilter;

  const _FilterBottomSheet({required this.currentFilter});

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late double _minPrice;
  late double _maxPrice;
  late bool _inStockOnly;
  late bool _egyptianOnly;
  late String _sortBy;

  final double _absoluteMin = 0;
  final double _absoluteMax = 5000;

  @override
  void initState() {
    super.initState();
    _minPrice = widget.currentFilter.minPrice ?? _absoluteMin;
    _maxPrice = widget.currentFilter.maxPrice ?? _absoluteMax;
    _inStockOnly = widget.currentFilter.inStockOnly;
    _egyptianOnly = widget.currentFilter.egyptianOnly;
    _sortBy = widget.currentFilter.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Text(
                  'Filter & Sort',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _minPrice = _absoluteMin;
                      _maxPrice = _absoluteMax;
                      _inStockOnly = false;
                      _egyptianOnly = false;
                      _sortBy = 'newest';
                    });
                  },
                  child: const Text('Reset',
                      style: TextStyle(color: Color(0xFF3B82F6))),
                ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Sort ─────────────────────────────────────────────────
                  const _SheetSectionTitle(title: 'Sort By'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SortChip(
                        label: 'Newest',
                        value: 'newest',
                        selected: _sortBy == 'newest',
                        onTap: () => setState(() => _sortBy = 'newest'),
                      ),
                      _SortChip(
                        label: 'Price ↑',
                        value: 'price_asc',
                        selected: _sortBy == 'price_asc',
                        onTap: () => setState(() => _sortBy = 'price_asc'),
                      ),
                      _SortChip(
                        label: 'Price ↓',
                        value: 'price_desc',
                        selected: _sortBy == 'price_desc',
                        onTap: () => setState(() => _sortBy = 'price_desc'),
                      ),
                      _SortChip(
                        label: 'Name A–Z',
                        value: 'name_asc',
                        selected: _sortBy == 'name_asc',
                        onTap: () => setState(() => _sortBy = 'name_asc'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Price Range ───────────────────────────────────────────
                  const _SheetSectionTitle(title: 'Price Range'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_minPrice.toInt()} EGP',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B82F6)),
                        ),
                      ),
                      const Text('—', style: TextStyle(color: Colors.grey)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_maxPrice.toInt()} EGP',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B82F6)),
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(_minPrice, _maxPrice),
                    min: _absoluteMin,
                    max: _absoluteMax,
                    divisions: 50,
                    activeColor: const Color(0xFF3B82F6),
                    inactiveColor:
                    const Color(0xFF3B82F6).withOpacity(0.2),
                    onChanged: (values) => setState(() {
                      _minPrice = values.start;
                      _maxPrice = values.end;
                    }),
                  ),

                  const SizedBox(height: 16),

                  // ── Toggles ───────────────────────────────────────────────
                  const _SheetSectionTitle(title: 'Product Type'),
                  const SizedBox(height: 12),
                  _ToggleTile(
                    icon: Icons.inventory_2_outlined,
                    iconColor: Colors.green,
                    title: 'In Stock Only',
                    subtitle: 'Show only available products',
                    value: _inStockOnly,
                    onChanged: (v) => setState(() => _inStockOnly = v),
                  ),
                  const SizedBox(height: 8),
                  _ToggleTile(
                    icon: Icons.flag_outlined,
                    iconColor: Colors.teal,
                    title: 'Egyptian Products',
                    subtitle: 'Show only local Egyptian brands',
                    value: _egyptianOnly,
                    onChanged: (v) => setState(() => _egyptianOnly = v),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Apply Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    ProductFilter(
                      minPrice:
                      _minPrice == _absoluteMin ? null : _minPrice,
                      maxPrice:
                      _maxPrice == _absoluteMax ? null : _maxPrice,
                      inStockOnly: _inStockOnly,
                      egyptianOnly: _egyptianOnly,
                      sortBy: _sortBy,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────
class _SheetSectionTitle extends StatelessWidget {
  final String title;
  const _SheetSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF3B82F6)
              : const Color(0xFF3B82F6).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF3B82F6)
                : const Color(0xFF3B82F6).withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF3B82F6),
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: value ? iconColor.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? iconColor.withOpacity(0.3) : Colors.grey[200]!,
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: iconColor,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}