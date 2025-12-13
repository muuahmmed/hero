import 'package:hero/data/models/product_model.dart';

import 'category_model.dart';

class ProductWithCategory {
  final Product product;
  final Category category;

  ProductWithCategory({
    required this.product,
    required this.category,
  });

  factory ProductWithCategory.fromJson(Map<String, dynamic> json) {
    return ProductWithCategory(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'category': category.toJson(),
    };
  }

  // Helper method to create from joined query
  factory ProductWithCategory.fromJoinedJson(Map<String, dynamic> json) {
    // Assuming the joined query returns both product and category fields
    return ProductWithCategory(
      product: Product.fromJson(json),
      category: Category(
        id: json['category_id'] as int,
        name: json['category_name'] as String? ?? '',
        description: json['category_description'] as String?,
        createdAt: DateTime.parse(json['category_created_at'] as String),
        active: json['category_active'] as bool?,
        parentId: json['category_parent_id'] as int?,
        imageUrl: json['category_image_url'] as String?,
        orderIndex: json['category_order_index'] as int?,
      ),
    );
  }
}