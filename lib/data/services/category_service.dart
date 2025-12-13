import 'package:hero/data/models/category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Category>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select('*')
          .eq('active', true)
          .order('order_index', ascending: true);

      return (response as List)
          .map((json) => Category.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load categories');
    }
  }

  Future<List<Category>> getCategoriesWithProductCount() async {
    try {
      final response = await _supabase
          .rpc('get_categories_with_product_count');

      return (response as List)
          .map((json) => Category.fromJson(json))
          .toList();
    } catch (e) {
      return getCategories();
    }
  }
}