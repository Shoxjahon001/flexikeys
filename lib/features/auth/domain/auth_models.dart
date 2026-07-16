library auth_models;

/// The authenticated parent/teacher/admin account. Mirrors backend `UserOut`.
class AppUser {
  final String id;
  final String? email;
  final String role;
  final String locale;

  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.locale,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String?,
        role: json['role'] as String,
        locale: json['locale'] as String? ?? 'en',
      );
}

/// A child profile under a parent account. Mirrors backend `ChildOut`.
class ChildProfile {
  final String id;
  final String parentId;
  final String displayName;
  final String learningLanguage;
  final String uiLanguage;
  final int? birthYear;
  final String? avatarId;

  const ChildProfile({
    required this.id,
    required this.parentId,
    required this.displayName,
    required this.learningLanguage,
    required this.uiLanguage,
    this.birthYear,
    this.avatarId,
  });

  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
        id: json['id'] as String,
        parentId: json['parent_id'] as String,
        displayName: json['display_name'] as String,
        learningLanguage: json['learning_language'] as String,
        uiLanguage: json['ui_language'] as String,
        birthYear: json['birth_year'] as int?,
        avatarId: json['avatar_id'] as String?,
      );
}

/// Fields needed to create a child profile — mirrors backend `ChildCreate`.
class ChildCreateData {
  final String displayName;
  final String learningLanguage;
  final String uiLanguage;
  final int? birthYear;
  final String? avatarId;

  const ChildCreateData({
    required this.displayName,
    this.learningLanguage = 'en',
    this.uiLanguage = 'en',
    this.birthYear,
    this.avatarId,
  });

  Map<String, dynamic> toJson() => {
        'display_name': displayName,
        'learning_language': learningLanguage,
        'ui_language': uiLanguage,
        if (birthYear != null) 'birth_year': birthYear,
        if (avatarId != null) 'avatar_id': avatarId,
      };
}
