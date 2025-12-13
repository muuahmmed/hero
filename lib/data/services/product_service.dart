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

      final products = (response as List)
          .map((json) => Product.fromJson(json))
          .toList();

      return products;
    } catch (e) {
      print('Error fetching products: $e');
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
      print('Error fetching featured products: $e');
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
}