class Category {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final bool? active;
  final int? parentId;
  final String? imageUrl;
  final int? orderIndex;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.active,
    this.parentId,
    this.imageUrl,
    this.orderIndex,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      active: json['active'] as bool?,
      parentId: json['parent_id'] as int?,
      imageUrl: json['image_url'] as String?,
      orderIndex: json['order_index'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'active': active,
      'parent_id': parentId,
      'image_url': imageUrl,
      'order_index': orderIndex,
    };
  }
}