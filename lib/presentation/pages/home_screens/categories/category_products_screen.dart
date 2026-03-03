import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hero/data/models/category_model.dart';
import 'package:hero/data/models/product_model.dart';
import 'package:hero/data/services/product_service.dart';
import 'package:hero/presentation/pages/home_screens/Product_Card/Product_Card_widget.dart';
import 'package:hero/presentation/pages/home_screens/Product_Card/Product_detail_screen.dart';
import 'package:hero/presentation/pages/home_screens/cart_screen/cart_cubit/cart_cubit.dart';

class CategoryProductsScreen extends StatefulWidget {
  final Category category;

  const CategoryProductsScreen({super.key, required this.category});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;
  String _sortBy = 'default';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final products =
      await _productService.getProductsByCategory(widget.category.id);
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Product> get _sortedProducts {
    final list = List<Product>.from(_products);
    switch (_sortBy) {
      case 'price_asc':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'name':
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    return list;
  }

  Color get _categoryColor {
    final n = widget.category.name.toLowerCase();
    if (n.contains('mass') || n.contains('gain')) return const Color(0xFFFF9800);
    if (n.contains('protein') || n.contains('whey')) return const Color(0xFF2196F3);
    if (n.contains('creatine')) return const Color(0xFF9C27B0);
    if (n.contains('fat') || n.contains('burn')) return const Color(0xFFF44336);
    if (n.contains('vitamin')) return const Color(0xFF4CAF50);
    if (n.contains('accessory') || n.contains('equipment')) return const Color(0xFF795548);
    if (n.contains('pre-workout')) return const Color(0xFFFF5722);
    if (n.contains('amino') || n.contains('eaa')) return const Color(0xFF00BCD4);
    return const Color(0xFF3B82F6);
  }

  IconData get _categoryIcon {
    final n = widget.category.name.toLowerCase();
    if (n.contains('mass') || n.contains('gain')) return Icons.monitor_weight;
    if (n.contains('protein') || n.contains('whey')) return Icons.fitness_center;
    if (n.contains('creatine')) return Icons.bolt;
    if (n.contains('fat') || n.contains('burn')) return Icons.local_fire_department;
    if (n.contains('vitamin')) return Icons.health_and_safety;
    if (n.contains('accessory') || n.contains('equipment')) return Icons.sports;
    if (n.contains('pre-workout')) return Icons.energy_savings_leaf;
    if (n.contains('amino') || n.contains('eaa')) return Icons.science;
    return Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: color,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withOpacity(0.75)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Opacity(
                        opacity: 0.15,
                        child: Icon(_categoryIcon, size: 160, color: Colors.white),
                      ),
                    ),
                    if (widget.category.description != null)
                      Positioned(
                        left: 20,
                        bottom: 56,
                        right: 20,
                        child: Text(
                          widget.category.description!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              // Sort button
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort, color: Colors.white),
                tooltip: 'Sort',
                onSelected: (value) => setState(() => _sortBy = value),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'default', child: Text('Default')),
                  const PopupMenuItem(value: 'price_asc', child: Text('Price: Low → High')),
                  const PopupMenuItem(value: 'price_desc', child: Text('Price: High → Low')),
                  const PopupMenuItem(value: 'name', child: Text('Name A–Z')),
                ],
              ),
            ],
          ),

          // Stats bar
          SliverToBoxAdapter(
            child: Container(
              color: color.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    _isLoading
                        ? 'Loading...'
                        : '${_sortedProducts.length} Products',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  if (_sortBy != 'default')
                    GestureDetector(
                      onTap: () => setState(() => _sortBy = 'default'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _getSortLabel(),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.close, size: 12, color: color),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                ),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      const Text('Failed to load products',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadProducts,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: color, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_sortedProducts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined,
                          size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No products yet in\n${widget.category.name}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.5),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final product = _sortedProducts[index];
                      return ProductCard(
                        product: product,
                        onTap: () => _navigateToProduct(context, product),
                      );
                    },
                    childCount: _sortedProducts.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'price_asc':
        return 'Price ↑';
      case 'price_desc':
        return 'Price ↓';
      case 'name':
        return 'Name A–Z';
      default:
        return '';
    }
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
}
