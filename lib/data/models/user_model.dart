// إعادة تسمية UserModel إلى AppUser لتجنب التعارض
class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;

  AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'] ?? '',
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
}