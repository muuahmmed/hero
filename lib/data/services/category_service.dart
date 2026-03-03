import 'package:hero/data/models/category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Category>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select('*')
          .order('order_index', ascending: true);

      final categories = (response as List)
          .map((json) => Category.fromJson(json))
          .toList();

      // Filter in Dart — safe even if active column doesn't exist yet
      return categories.where((c) => c.active != false).toList();
    } catch (e) {
      print('CategoryService error: $e');
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<List<Category>> getCategoriesWithProductCount() async {
    try {
      final response =
      await _supabase.rpc('get_categories_with_product_count');
      return (response as List)
          .map((json) => Category.fromJson(json))
          .toList();
    } catch (_) {
      return getCategories();
    }
  }
}