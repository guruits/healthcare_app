import 'package:health/data/models/permission.dart';

class Role {
  String? id;
  String name;
  String? description;
  List<Permission> permissions;
  bool isActive;

  Role({
    this.id,
    required this.name,
    this.description,
    required this.permissions,
    this.isActive = true,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      permissions: (json['permissions'] as List)
          .map((p) => Permission.fromJson(p))
          .toList(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'permissions': permissions.map((p) => p.toJson()).toList(),
      'isActive': isActive,
    };
  }
}
