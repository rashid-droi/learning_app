class Assessment {
  final int id;
  final String moduleId;
  final String type; // pre, post, quiz
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<Section> sections;

  Assessment({
    required this.id,
    required this.moduleId,
    required this.type,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.sections,
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
      sections: (json['sections'] as List<dynamic>?)
              ?.map((section) => Section.fromJson(section))
              .toList() ??
          [],
    );
  }
}

class Section {
  final int id;
  final String assessmentId;
  final String title;
  final int? order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<MCQ> mcqs;

  Section({
    required this.id,
    required this.assessmentId,
    required this.title,
    this.order,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.mcqs,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id'],
      assessmentId: json['assessment_id'].toString(),
      title: json['title'],
      order: json['order'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
      mcqs: (json['mcqs'] as List<dynamic>?)
              ?.map((mcq) => MCQ.fromJson(mcq))
              .toList() ??
          [],
    );
  }
}

class MCQ {
  final int id;
  final String sectionId;
  final String question;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<Option> options;

  MCQ({
    required this.id,
    required this.sectionId,
    required this.question,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.options,
  });

  factory MCQ.fromJson(Map<String, dynamic> json) {
    return MCQ(
      id: json['id'],
      sectionId: json['section_id'].toString(),
      question: json['question'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
      options: (json['options'] as List<dynamic>?)
              ?.map((option) => Option.fromJson(option))
              .toList() ??
          [],
    );
  }
}

class Option {
  final int id;
  final String mcqId;
  final String optionText;
  final bool isCorrect;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Option({
    required this.id,
    required this.mcqId,
    required this.optionText,
    required this.isCorrect,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      id: json['id'],
      mcqId: json['mcq_id'].toString(),
      optionText: json['option_text'],
      isCorrect: json['is_correct'] == '1',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    );
  }
}
