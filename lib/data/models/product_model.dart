class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String? sku;
  final bool active;
  final int categoryId;
  final DateTime createdAt;
  final String? company;
  final bool? isEgyptian;
  final String? size;
  final String? scope;
  final bool isActive;
  final bool? isFavorite;
  final bool? featured;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.sku,
    required this.active,
    required this.categoryId,
    required this.createdAt,
    this.company,
    this.isEgyptian,
    this.size,
    this.scope,
    required this.isActive,
    this.isFavorite = false,
    this.featured = false,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      sku: json['sku'] as String?,
      active: json['active'] as bool,
      categoryId: json['category_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      company: json['company'] as String?,
      isEgyptian: json['is_egyptian'] as bool?,
      size: json['size'] as String?,
      scope: json['scope'] as String?,
      isActive: json['is_active'] as bool,
      isFavorite: json['is_favorite'] as bool? ?? false,
      featured: json['featured'] as bool? ?? false,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'sku': sku,
      'active': active,
      'category_id': categoryId,
      'created_at': createdAt.toIso8601String(),
      'company': company,
      'is_egyptian': isEgyptian,
      'size': size,
      'scope': scope,
      'is_active': isActive,
      'is_favorite': isFavorite,
      'featured': featured,
      'image_url': imageUrl,
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? sku,
    bool? active,
    int? categoryId,
    DateTime? createdAt,
    String? company,
    bool? isEgyptian,
    String? size,
    String? scope,
    bool? isActive,
    bool? isFavorite,
    bool? featured,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      sku: sku ?? this.sku,
      active: active ?? this.active,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      company: company ?? this.company,
      isEgyptian: isEgyptian ?? this.isEgyptian,
      size: size ?? this.size,
      scope: scope ?? this.scope,
      isActive: isActive ?? this.isActive,
      isFavorite: isFavorite ?? this.isFavorite,
      featured: featured ?? this.featured,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  String getImageUrl() {
    // استخدم الرابط المخزن في قاعدة البيانات
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl!;
    }

    // صورة افتراضية إذا لم توجد
    return 'https://via.placeholder.com/300x300/3B82F6/FFFFFF?text=${Uri.encodeComponent(name)}';
  }
}