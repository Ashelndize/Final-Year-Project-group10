class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String phone;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        username: json['username'] as String,
        email: json['email'] as String? ?? '',
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        role: json['role'] as String? ?? 'FARMER',
        phone: json['phone'] as String? ?? '',
      );

  String get fullName => '$firstName $lastName'.trim();
  bool get isFarmer => role == 'FARMER';
  bool get isVet => role == 'VET';
}
