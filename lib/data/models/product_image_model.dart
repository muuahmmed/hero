class ProductImage {
  final int id;
  final int productId;
  final String imageUrl;
  final String? altText;
  final int? orderIndex;
  final DateTime createdAt;
  final bool isPrimary;
  final String? thumbnailUrl;

  ProductImage({
    required this.id,
    required this.productId,
    required this.imageUrl,
    this.altText,
    this.orderIndex,
    required this.createdAt,
    required this.isPrimary,
    this.thumbnailUrl,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      imageUrl: json['image_url'] as String,
      altText: json['alt_text'] as String?,
      orderIndex: json['order_index'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isPrimary: json['is_primary'] as bool,
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'image_url': imageUrl,
      'alt_text': altText,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'is_primary': isPrimary,
      'thumbnail_url': thumbnailUrl,
    };
  }
}