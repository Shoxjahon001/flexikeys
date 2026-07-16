library parent_models;

/// Aggregated today + streak summary for one child.
class ChildSummary {
  final String childId;
  final String displayName;
  final double todayMinutes;
  final int todayItems;
  final int streakDays;
  final String learningLanguage;
  final String uiLanguage;

  const ChildSummary({
    required this.childId,
    required this.displayName,
    required this.todayMinutes,
    required this.todayItems,
    required this.streakDays,
    required this.learningLanguage,
    required this.uiLanguage,
  });

  factory ChildSummary.fromJson(Map<String, dynamic> json) => ChildSummary(
        childId: json['child_id'] as String,
        displayName: json['display_name'] as String,
        todayMinutes: (json['today_minutes'] as num).toDouble(),
        todayItems: json['today_items'] as int,
        streakDays: json['streak_days'] as int,
        learningLanguage: json['learning_language'] as String,
        uiLanguage: json['ui_language'] as String,
      );
}

/// A single skill's mastery level.
class SkillEntry {
  final String skillKey;
  final String label;
  final double pKnown;
  final int attempts;
  final int correct;

  const SkillEntry({
    required this.skillKey,
    required this.label,
    required this.pKnown,
    required this.attempts,
    required this.correct,
  });

  factory SkillEntry.fromJson(Map<String, dynamic> json) => SkillEntry(
        skillKey: json['skill_key'] as String,
        label: json['label'] as String,
        pKnown: (json['p_known'] as num).toDouble(),
        attempts: json['attempts'] as int,
        correct: json['correct'] as int,
      );

  bool get isMastered => pKnown >= 0.8;
  bool get isPracticing => pKnown >= 0.4 && pKnown < 0.8;
  bool get isStarting => pKnown < 0.4;
}

/// One point in a timeseries metric (accuracy, speed, time).
class TimeseriesPoint {
  final DateTime date;
  final double? value;

  const TimeseriesPoint({required this.date, required this.value});

  factory TimeseriesPoint.fromJson(Map<String, dynamic> json) => TimeseriesPoint(
        date: DateTime.parse(json['date'] as String),
        value: json['value'] != null ? (json['value'] as num).toDouble() : null,
      );
}

/// One entry in the adaptation feed — what changed and why in plain language.
class AdaptationFeedItem {
  final String id;
  final DateTime changedAt;
  final String param;
  final String? oldValue;
  final String? newValue;
  final String reasonCode;
  final String sentence;

  const AdaptationFeedItem({
    required this.id,
    required this.changedAt,
    required this.param,
    required this.oldValue,
    required this.newValue,
    required this.reasonCode,
    required this.sentence,
  });

  factory AdaptationFeedItem.fromJson(Map<String, dynamic> json) => AdaptationFeedItem(
        id: json['id'] as String,
        changedAt: DateTime.parse(json['changed_at'] as String),
        param: json['param'] as String,
        oldValue: json['old_value'] as String?,
        newValue: json['new_value'] as String?,
        reasonCode: json['reason_code'] as String,
        sentence: json['sentence'] as String,
      );
}

/// A parent chat message.
class ChatMessage {
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        role: json['role'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

/// State for the assistant conversation.
class AssistantState {
  final List<ChatMessage> messages;
  final bool loading;
  final String? conversationId;

  const AssistantState({
    this.messages = const [],
    this.loading = false,
    this.conversationId,
  });

  AssistantState copyWith({
    List<ChatMessage>? messages,
    bool? loading,
    String? conversationId,
  }) =>
      AssistantState(
        messages: messages ?? this.messages,
        loading: loading ?? this.loading,
        conversationId: conversationId ?? this.conversationId,
      );
}