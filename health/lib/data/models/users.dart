class Users {
  final String id;
  final String aadhaarNumber;
  final String name;
  final DateTime? dob;
  final String phoneNumber;
  final String address;
  final String roleId;
  final String? currentPassword;
  final String? newPassword;

  Users({
    required this.id,
    required this.aadhaarNumber,
    required this.name,
    this.dob,
    required this.phoneNumber,
    required this.address,
    required this.roleId,
    this.currentPassword,  // Add these parameters
    this.newPassword,     // Add these parameters
  });

  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
      id: json['_id'] ?? '',
      aadhaarNumber: json['aadhaarNumber'] ?? '',
      name: json['name'] ?? '',
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'] ?? '',
      roleId: json['rolesId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'aadhaarNumber': aadhaarNumber,
      'name': name,
      'dob': dob?.toIso8601String(),
      'phone_number': phoneNumber,
      'address': address,
      'roles': roleId,
    };

    // Only add password fields if they are present
    if (currentPassword != null) data['currentPassword'] = currentPassword;
    if (newPassword != null) data['newPassword'] = newPassword;

    return data;
  }
}