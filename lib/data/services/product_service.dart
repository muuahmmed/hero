import 'package:hero/data/models/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Product>> getProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load products');
    }
  }

  Future<List<Product>> getFeaturedProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .eq('is_active', true)
          .eq('featured', true)
          .limit(5);

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Product>> getProductsByCategory(int categoryId) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .eq('category_id', categoryId)
          .eq('is_active', true);

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load category products');
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .ilike('name', '%$query%')
          .eq('is_active', true);

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Search failed');
    }
  }

  Future<Product?> getProductById(int id) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .eq('id', id)
          .single();

      return Product.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // ── Advanced Filter ────────────────────────────────────────────────────────
  Future<List<Product>> getFilteredProducts({
    String? query,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    bool? egyptianOnly,
    String sortBy = 'newest',
  }) async {
    try {
      // 1. Build all filters first
      var request = _supabase
          .from('products')
          .select('*')
          .eq('is_active', true);

      if (query != null && query.trim().isNotEmpty) {
        request = request.ilike('name', '%$query%');
      }
      if (categoryId != null) {
        request = request.eq('category_id', categoryId);
      }
      if (minPrice != null) {
        request = request.gte('price', minPrice);
      }
      if (maxPrice != null) {
        request = request.lte('price', maxPrice);
      }
      if (inStockOnly == true) {
        request = request.gt('stock', 0);
      }
      if (egyptianOnly == true) {
        request = request.eq('is_egyptian', true);
      }

      // 2. Sort at the very end
      final String column;
      final bool ascending;

      switch (sortBy) {
        case 'price_asc':
          column = 'price';
          ascending = true;
          break;
        case 'price_desc':
          column = 'price';
          ascending = false;
          break;
        case 'name_asc':
          column = 'name';
          ascending = true;
          break;
        case 'newest':
        default:
          column = 'created_at';
          ascending = false;
          break;
      }

      final response = await request.order(column, ascending: ascending);

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Filter failed: $e');
    }
  }
}