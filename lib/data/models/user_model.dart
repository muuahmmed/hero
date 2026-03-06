class AppUser {
  final String id;       // auth UUID
  final int? dbId;       // public.users integer id
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;

  AppUser({
    required this.id,
    this.dbId,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
    };
  }

  AppUser copyWith({
    String? id,
    int? dbId,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) {
    return AppUser(
      id: id ?? this.id,
      dbId: dbId ?? this.dbId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
