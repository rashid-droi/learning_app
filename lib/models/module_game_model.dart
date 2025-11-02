class ModuleGame {
  final int id;
  final String moduleId;
  final String name;
  final String details;
  final DateTime createdAt;
  final DateTime updatedAt;

  ModuleGame({
    required this.id,
    required this.moduleId,
    required this.name,
    required this.details,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ModuleGame.fromJson(Map<String, dynamic> json) {
    return ModuleGame(
      id: json['id'],
      moduleId: json['module_id'].toString(),
      name: json['name'],
      details: json['details'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
