class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'staff',
      phone: json['phone'] as String? ?? '',
    );
  }

  AppUser copyWith({String? phone}) {
    return AppUser(
      id: id,
      name: name,
      email: email,
      role: role,
      phone: phone ?? this.phone,
    );
  }
}
