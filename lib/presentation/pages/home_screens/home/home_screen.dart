import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Product_Card/Product_Card_widget.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeCubit>().fetchProducts();
    });
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Text
          Text(
            'Welcome to Hero Fitness',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Premium supplements for your journey',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                context.read<HomeCubit>().searchProducts(value);
              },
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<HomeCubit>().fetchProducts();
                  },
                )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, HomeState state) {
    if (state is HomeLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is HomeError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<HomeCubit>().fetchProducts(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is HomeLoaded) {
      return RefreshIndicator(
        onRefresh: () async {
          await context.read<HomeCubit>().fetchProducts();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            // 🔹 Featured Products Section
            if (state.featuredProducts?.isNotEmpty ?? false) ...[
              SectionHeader(
                title: 'Featured Products',
                onSeeAll: () {
                  // Navigate to featured products page
                },
              ),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.featuredProducts!.length,
                  itemBuilder: (context, index) {
                    final product = state.featuredProducts![index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ProductCard(
                        product: product,
                        isFeatured: true,
                        onTap: () {
                          // Navigate to product details
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 🔹 All Products Section
            SectionHeader(
              title: 'Latest Products',
              onSeeAll: () {
                // Navigate to all products page
              },
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: state.products.length,
              itemBuilder: (context, index) {
                final product = state.products[index];
                return ProductCard(
                  product: product,
                  onTap: () {
                    // Navigate to product details
                  },
                  onFavoriteToggle: () {
                    context.read<HomeCubit>().toggleProductFavorite(product.id);
                  },
                );
              },
            ),
          ],
        ),
      );
    }

    return const Center(child: Text('No products available'));
  }
}