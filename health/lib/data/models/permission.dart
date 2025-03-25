class Permission {
  String? id;
   String screen;
  bool create;
  bool read;
  bool update;
  bool delete;

  Permission({
    this.id,
    required this.screen,
    this.create = false,
    this.read = false,
    this.update = false,
    this.delete = false,
  });

  Map<String, dynamic> toJson() => {
    'screen': screen,
    'create': create,
    'read': read,
    'update': update,
    'delete': delete,
  };

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      screen: json['screen'],
      create: json['create'] ?? false,
      read: json['read'] ?? false,
      update: json['update'] ?? false,
      delete: json['delete'] ?? false,
    );
  }

  //get id => null;

  Permission copyWith({
    String? screen,
    bool? create,
    bool? read,
    bool? update,
    bool? delete,
  }) {
    return Permission(
      screen: screen ?? this.screen,
      create: create ?? this.create,
      read: read ?? this.read,
      update: update ?? this.update,
      delete: delete ?? this.delete,
    );
  }


  bool hasAnyPermission() {
    return create || read || update || delete;
  }
}