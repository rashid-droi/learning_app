class Module {
  final int id;
  final String courseId;
  final String order;
  final String name;
  final String details;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
 

  Module({
    required this.id,
    required this.courseId,
    required this.order,
    required this.name,
    required this.details,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,

  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'] as int,
      courseId: json['course_id']?.toString() ?? '',
      order: json['order']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      deletedAt: json['deleted_at']?.toString(),
    );
  }
}