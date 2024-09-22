class User {
  String phone;
  String name;
  String city;
  String district;

  User({
    required this.phone,
    required this.name,
    required this.city,
    required this.district,
  });

  // Map'ten nesne oluşturma
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      phone: map['phone'] ?? '',
      name: map['name'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
    );
  }

  // Nesneyi Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'name': name,
      'city': city,
      'district': district,
    };
  }
}
