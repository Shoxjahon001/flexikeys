library teacher_models;

class ClassItem {
  final String id;
  final String name;
  final String joinCode;
  final int studentCount;
  final DateTime createdAt;

  const ClassItem({
    required this.id,
    required this.name,
    required this.joinCode,
    required this.studentCount,
    required this.createdAt,
  });

  factory ClassItem.fromJson(Map<String, dynamic> json) => ClassItem(
        id: json['id'] as String,
        name: json['name'] as String,
        joinCode: json['join_code'] as String,
        studentCount: (json['student_count'] as num).toInt(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class StudentSummary {
  final String childId;
  final String displayName;
  final double masteryScore;
  final DateTime? lastActive;
  final bool needsAttention;
  final List<String> skillsNeedingPractice;

  const StudentSummary({
    required this.childId,
    required this.displayName,
    required this.masteryScore,
    this.lastActive,
    required this.needsAttention,
    this.skillsNeedingPractice = const [],
  });

  factory StudentSummary.fromJson(Map<String, dynamic> json) => StudentSummary(
        childId: json['child_id'] as String,
        displayName: json['display_name'] as String,
        masteryScore: (json['mastery_score'] as num).toDouble(),
        lastActive: json['last_active'] != null
            ? DateTime.parse(json['last_active'] as String)
            : null,
        needsAttention: json['needs_attention'] as bool,
        skillsNeedingPractice: (json['skills_needing_practice'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  String get masteryLabel {
    if (masteryScore >= 0.8) return 'On track';
    if (masteryScore >= 0.4) return 'Practising';
    return 'Getting started';
  }
}

class ClassAnalytics {
  final String classId;
  final String className;
  final int studentCount;
  final double avgMastery;
  final int needsAttentionCount;
  final List<StudentSummary> studentSummaries;

  const ClassAnalytics({
    required this.classId,
    required this.className,
    required this.studentCount,
    required this.avgMastery,
    required this.needsAttentionCount,
    required this.studentSummaries,
  });

  factory ClassAnalytics.fromJson(Map<String, dynamic> json) => ClassAnalytics(
        classId: json['class_id'] as String,
        className: json['class_name'] as String,
        studentCount: (json['student_count'] as num).toInt(),
        avgMastery: (json['avg_mastery'] as num).toDouble(),
        needsAttentionCount: (json['needs_attention_count'] as num).toInt(),
        studentSummaries: (json['student_summaries'] as List<dynamic>)
            .map((e) => StudentSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Assignment {
  final String id;
  final String classId;
  final String? levelId;
  final String? lessonId;
  final DateTime? dueAt;
  final String? instructions;
  final DateTime createdAt;

  const Assignment({
    required this.id,
    required this.classId,
    this.levelId,
    this.lessonId,
    this.dueAt,
    this.instructions,
    required this.createdAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        id: json['id'] as String,
        classId: json['class_id'] as String,
        levelId: json['level_id'] as String?,
        lessonId: json['lesson_id'] as String?,
        dueAt:
            json['due_at'] != null ? DateTime.parse(json['due_at'] as String) : null,
        instructions: json['instructions'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class EnrollResult {
  final String classId;
  final String className;
  final DateTime enrolledAt;

  const EnrollResult({
    required this.classId,
    required this.className,
    required this.enrolledAt,
  });

  factory EnrollResult.fromJson(Map<String, dynamic> json) => EnrollResult(
        classId: json['class_id'] as String,
        className: json['class_name'] as String,
        enrolledAt: DateTime.parse(json['enrolled_at'] as String),
      );
}