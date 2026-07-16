library curriculum_models;

/// Dart models for the curriculum API responses.
///
/// These mirror the backend LevelOut / LessonDetailOut / ItemOut schemas.
/// All fields are nullable-safe — the models accept partial data when
/// the app is operating offline from a local cache.

class CurriculumItemL10n {
  final String text;
  final String audioUrl;
  final String? imageUrl;
  final String? soundUrl;
  final List<List<double>>? tracePath;

  const CurriculumItemL10n({
    required this.text,
    required this.audioUrl,
    this.imageUrl,
    this.soundUrl,
    this.tracePath,
  });

  factory CurriculumItemL10n.fromJson(Map<String, dynamic> json) {
    List<List<double>>? tp;
    if (json['trace_path'] != null) {
      tp = (json['trace_path'] as List)
          .map((row) => (row as List).map((v) => (v as num).toDouble()).toList())
          .toList();
    }
    return CurriculumItemL10n(
      text: json['text'] as String,
      audioUrl: json['audio_url'] as String,
      imageUrl: json['image_url'] as String?,
      soundUrl: json['sound_url'] as String?,
      tracePath: tp,
    );
  }
}

class CurriculumItem {
  final String id;
  final String type;
  final String skillKey;
  final CurriculumItemL10n l10n;

  const CurriculumItem({
    required this.id,
    required this.type,
    required this.skillKey,
    required this.l10n,
  });

  factory CurriculumItem.fromJson(Map<String, dynamic> json) {
    return CurriculumItem(
      id: json['id'] as String,
      type: json['type'] as String,
      skillKey: json['skill_key'] as String,
      l10n: CurriculumItemL10n.fromJson(json['l10n'] as Map<String, dynamic>),
    );
  }
}

class LessonSummary {
  final String id;
  final String slug;
  final String type;
  final String title;
  final int itemCount;

  const LessonSummary({
    required this.id,
    required this.slug,
    required this.type,
    required this.title,
    required this.itemCount,
  });

  factory LessonSummary.fromJson(Map<String, dynamic> json) {
    return LessonSummary(
      id: json['id'] as String,
      slug: json['slug'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      itemCount: json['item_count'] as int,
    );
  }
}

class LessonDetail {
  final String id;
  final String slug;
  final String type;
  final String title;
  final List<CurriculumItem> items;

  const LessonDetail({
    required this.id,
    required this.slug,
    required this.type,
    required this.title,
    required this.items,
  });

  factory LessonDetail.fromJson(Map<String, dynamic> json) {
    return LessonDetail(
      id: json['id'] as String,
      slug: json['slug'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      items: (json['items'] as List)
          .map((e) => CurriculumItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LevelSummary {
  final String id;
  final int level;
  final String slug;
  final String title;
  final int lessonCount;
  final int itemCount;

  const LevelSummary({
    required this.id,
    required this.level,
    required this.slug,
    required this.title,
    required this.lessonCount,
    required this.itemCount,
  });

  factory LevelSummary.fromJson(Map<String, dynamic> json) {
    return LevelSummary(
      id: json['id'] as String,
      level: json['level'] as int,
      slug: json['slug'] as String,
      title: json['title'] as String,
      lessonCount: json['lesson_count'] as int,
      itemCount: json['item_count'] as int,
    );
  }
}

/// The next lesson plan returned by `GET /curriculum/next`.
class NextLessonPlan {
  final String lessonId;
  final String lessonSlug;
  final List<CurriculumItem> items;
  final List<CurriculumItem> dueReviewItems;

  const NextLessonPlan({
    required this.lessonId,
    required this.lessonSlug,
    required this.items,
    required this.dueReviewItems,
  });

  factory NextLessonPlan.fromJson(Map<String, dynamic> json) {
    return NextLessonPlan(
      lessonId: json['lesson_id'] as String,
      lessonSlug: json['lesson_slug'] as String,
      items: (json['items'] as List)
          .map((e) => CurriculumItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      dueReviewItems: (json['due_review_items'] as List)
          .map((e) => CurriculumItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}