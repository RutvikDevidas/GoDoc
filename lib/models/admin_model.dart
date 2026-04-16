class AdminModel {
  final String username;
  final String password;
  final String name;
  final String email;
  final String phone;

  const AdminModel({
    required this.username,
    required this.password,
    required this.name,
    this.email = '',
    this.phone = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'name': name,
      'email': email,
      'phone': phone,
    };
  }

  factory AdminModel.fromMap(Map<String, dynamic> map) {
    return AdminModel(
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
    );
  }
}
