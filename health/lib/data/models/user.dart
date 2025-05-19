class User {
  late final String id;
  final String aadhaarNumber;
  final String name;
  final DateTime?  dob;
  final String phoneNumber;
  final String address;
  final List<String> roles;
  final bool isActive;

  User({
    required this.id,
    required this.aadhaarNumber,
    required this.name,
    this.dob,
    required this.phoneNumber,
    required this.address,
    this.roles = const[],
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      aadhaarNumber: json['aadhaarNumber'] ?? '',
      name: json['name'] ?? '',
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'] ?? '',
      roles: List<String>.from(json['roles'] ?? []),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aadhaarNumber': aadhaarNumber,
      'name': name,
      'dob': dob?.toIso8601String(),
      'phone_number': phoneNumber,
      'address': address,
      'roles': roles,
      'isActive': isActive,
    };
  }
}


