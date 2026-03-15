class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.blocked,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final bool blocked;
  final DateTime? createdAt;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Unknown',
      email: (json['email'] as String?) ?? 'N/A',
      role: (json['role'] as String?) ?? 'user',
      blocked: (json['blocked'] as bool?) ?? false,
      createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
    );
  }

  AdminUser copyWith({String? role, bool? blocked}) {
    return AdminUser(
      id: id,
      name: name,
      email: email,
      role: role ?? this.role,
      blocked: blocked ?? this.blocked,
      createdAt: createdAt,
    );
  }
}
