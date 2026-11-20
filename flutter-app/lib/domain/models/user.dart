class User {
  final int id;
  final String name;
  final String email;
  final String? roleName;
  final String? roleSlug;
  final String? phone;
  final String? emailVerifiedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.roleName,
    this.roleSlug,
    this.phone,
    this.emailVerifiedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      roleName: json['role']?['name'],
      roleSlug: json['role']?['slug'],
      phone: json['phone'],
      emailVerifiedAt: json['email_verified_at'],
    );
  }

  bool get isVerified => (emailVerifiedAt?.isNotEmpty ?? false);

  bool get isParent => roleSlug == 'parent';
  bool get isMedecin => roleSlug == 'medecin';
  bool get isAdmin => roleSlug == 'medecin';
}