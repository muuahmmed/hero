class WishlistItem {
  final int id;
  final int userId;
  final int productId;
  final DateTime? createdAt;
  final String? productName;
  final double? productPrice;
  final String? productImage;
  final int? productStock;
  final String? productCompany;

  WishlistItem({
    required this.id,
    required this.userId,
    required this.productId,
    this.createdAt,
    this.productName,
    this.productPrice,
    this.productImage,
    this.productStock,
    this.productCompany,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    final product = json['products'] as Map<String, dynamic>?;
    return WishlistItem(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      productId: json['product_id'] as int,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      productName: product?['name'] as String?,
      productPrice: product != null ? double.tryParse(product['price'].toString()) : null,
      productImage: product?['image_url'] as String?,
      productStock: product?['stock'] as int?,
      productCompany: product?['company'] as String?,
    );
  }
}

class Review {
  final int id;
  final int userId;
  final int productId;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final String? userName;
  final String? productName;

  Review({
    required this.id,
    required this.userId,
    required this.productId,
    required this.rating,
    this.comment,
    this.createdAt,
    this.userName,
    this.productName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>?;
    final product = json['products'] as Map<String, dynamic>?;
    return Review(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      productId: json['product_id'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      userName: user?['name'] as String?,
      productName: product?['name'] as String?,
    );
  }
}

class AppOrder {
  final int id;
  final int userId;
  final String? status;
  final double? total;
  final String? shippingAddress;
  final DateTime? createdAt;
  final List<AppOrderItem> items;

  AppOrder({
    required this.id,
    required this.userId,
    this.status,
    this.total,
    this.shippingAddress,
    this.createdAt,
    this.items = const [],
  });

  factory AppOrder.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['order_items'] as List<dynamic>?;
    return AppOrder(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      status: json['status'] as String?,
      total: json['total'] != null ? double.tryParse(json['total'].toString()) : null,
      shippingAddress: json['shipping_address'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      items: itemsJson?.map((i) => AppOrderItem.fromJson(i as Map<String, dynamic>)).toList() ?? [],
    );
  }
}

class AppOrderItem {
  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final double price;
  final String? productName;
  final String? productImage;

  AppOrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    this.productName,
    this.productImage,
  });

  factory AppOrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['products'] as Map<String, dynamic>?;
    return AppOrderItem(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      productId: json['product_id'] as int,
      quantity: json['quantity'] as int,
      price: double.tryParse(json['price'].toString()) ?? 0,
      productName: product?['name'] as String?,
      productImage: product?['image_url'] as String?,
    );
  }
}
