class Screen {
   final  String id;
  final String name;
  final String description;
  final bool isActive;
  final int v;

  const Screen({
     required this.id,
    required this.name,
    required this.description,
    this.isActive = true,
    this.v = 0,
  });

  factory Screen.fromJson(Map<String, dynamic> json) {
    return Screen(
      id: json['_id'] as String,  // Changed from 'id' to '_id' to match MongoDB
      name: json['name'] as String,
      description: json['description'] as String,
      isActive: json['isActive'] as bool? ?? true,
      v: json['__v'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,  // Changed from 'id' to '_id'
      'name': name,
      'description': description,
      'isActive': isActive,
      '__v': v,
    };
  }
}