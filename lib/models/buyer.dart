class Buyer {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String? phone;
  final String? address;
  final DateTime createdAt;

  Buyer({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    this.address,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'address': address,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Buyer.fromMap(Map<String, dynamic> map) {
    return Buyer(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      phone: map['phone'],
      address: map['address'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
