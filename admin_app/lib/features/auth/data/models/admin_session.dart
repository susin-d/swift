class AdminSession {
  const AdminSession({
    required this.token,
    required this.userId,
    required this.email,
    required this.role,
  });

  final String token;
  final String userId;
  final String email;
  final String role;

  bool get isAdmin => role == 'admin';

  factory AdminSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final session = json['session'] as Map<String, dynamic>;
    return AdminSession(
      token: (session['access_token'] as String?) ?? '',
      userId: (user['id'] as String?) ?? '',
      email: (user['email'] as String?) ?? '',
      role: (user['role'] as String?) ?? 'user',
    );
  }
}
