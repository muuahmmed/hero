import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hero/data/models/category_model.dart';
import 'package:hero/presentation/pages/home_screens/cart_screen/cart_cubit/cart_cubit.dart';
import 'categories_cubit/categories_cubit.dart';
import 'categories_cubit/categories_states.dart';
import 'category_card.dart';
import 'category_products_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriesCubit>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search categories...',
                  hintStyle:
                  TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: InputBorder.none,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    color: Colors.grey[400],
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<CategoriesCubit, CategoriesState>(
        builder: (context, state) {
          if (state is CategoriesLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor:
                AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            );
          }

          if (state is CategoriesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  const Text('Failed to load categories',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(state.error,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.read<CategoriesCubit>().fetchCategories(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (state is CategoriesLoaded) {
            final filtered = _searchQuery.isEmpty
                ? state.categories
                : state.categories
                .where((c) => c.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
                .toList();

            if (filtered.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No categories found for\n"$_searchQuery"',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Text(
                        '${filtered.length} ${filtered.length == 1 ? 'Category' : 'Categories'}',
                        style:
                        TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final category = filtered[index];
                      return CategoryCard(
                        category: category,
                        productCount: category.orderIndex,
                        onTap: () => _navigateToCategory(context, category),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _navigateToCategory(BuildContext context, Category category) {
    final cartCubit = context.read<CartCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cartCubit,
          child: CategoryProductsScreen(category: category),
        ),
      ),
    );
  }
}