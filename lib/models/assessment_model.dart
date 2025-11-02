class Assessment {
  final int id;
  final String moduleId;
  final String type; // pre, post, quiz
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Assessment({
    required this.id,
    required this.moduleId,
    required this.type,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      id: json['id'],
      moduleId: json['module_id'].toString(),
      type: json['type'],
      title: json['title'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    );
  }
}
