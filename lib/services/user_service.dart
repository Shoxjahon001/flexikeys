import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const _keyName = 'kid_name';
  static const _keyAge = 'kid_age';
  static const _keyLanguage = 'kid_language';
  static const _keyStars = 'stars';
  static const _keyLettersStage = 'letters_stage';
  static const _keyOwnedItems = 'owned_items';
  static const _keyTotalCorrect = 'total_correct';
  static const _keyTotalAnswers = 'total_answers';
  static const _keyTimeSpent = 'time_spent_minutes';
  static const _keyLastDate = 'last_session_date';
  static const _keyRegistered = 'is_registered';
  static const _keyCompletedLevels = 'completed_levels';
  static const _keyVolume = 'tts_volume';

  static SharedPreferences? _cachedPrefs;
  static Future<SharedPreferences> get _prefs async =>
      _cachedPrefs ??= await SharedPreferences.getInstance();

  // ─── Registration ────────────────────────────────────────────────────────────

  static Future<void> saveRegistration({
    required String name,
    required int age,
    required String language,
  }) async {
    final p = await _prefs;
    await p.setString(_keyName, name);
    await p.setInt(_keyAge, age);
    await p.setString(_keyLanguage, language);
    await p.setBool(_keyRegistered, true);
    if (!p.containsKey(_keyOwnedItems)) {
      await p.setStringList(_keyOwnedItems, ['dino']);
    }
  }

  static Future<bool> isRegistered() async {
    final p = await _prefs;
    return p.getBool(_keyRegistered) ?? false;
  }

  static Future<String> getName() async {
    final p = await _prefs;
    return p.getString(_keyName) ?? '';
  }

  static Future<int> getAge() async {
    final p = await _prefs;
    return p.getInt(_keyAge) ?? 5;
  }

  static Future<String> getLanguage() async {
    final p = await _prefs;
    return p.getString(_keyLanguage) ?? 'en';
  }

  // ─── Stars ───────────────────────────────────────────────────────────────────

  static Future<int> getStars() async {
    final p = await _prefs;
    return p.getInt(_keyStars) ?? 0;
  }

  static Future<void> addStars(int amount) async {
    final p = await _prefs;
    final current = p.getInt(_keyStars) ?? 0;
    await p.setInt(_keyStars, current + amount);
  }

  static Future<bool> spendStars(int amount) async {
    final p = await _prefs;
    final current = p.getInt(_keyStars) ?? 0;
    if (current < amount) return false;
    await p.setInt(_keyStars, current - amount);
    return true;
  }

  // ─── Level completion ─────────────────────────────────────────────────────

  static Future<Set<String>> getCompletedLevels() async {
    final p = await _prefs;
    return (p.getStringList(_keyCompletedLevels) ?? []).toSet();
  }

  static Future<void> completeLevel(String levelId) async {
    final p = await _prefs;
    final levels = (p.getStringList(_keyCompletedLevels) ?? []).toSet();
    levels.add(levelId);
    await p.setStringList(_keyCompletedLevels, levels.toList());
  }

  static Future<bool> isLevelCompleted(String levelId) async {
    final completed = await getCompletedLevels();
    return completed.contains(levelId);
  }

  // ─── Letters stage (legacy + integrated) ─────────────────────────────────

  static Future<int> getLettersStage() async {
    final p = await _prefs;
    return p.getInt(_keyLettersStage) ?? 0;
  }

  static Future<void> setLettersStage(int stage) async {
    final p = await _prefs;
    await p.setInt(_keyLettersStage, stage);
    if (stage >= 1) {
      await completeLevel('letters_1');
      await completeLevel('letters');
    }
    if (stage >= 2) await completeLevel('letters_2');
  }

  // ─── Shop ─────────────────────────────────────────────────────────────────

  static Future<List<String>> getOwnedItems() async {
    final p = await _prefs;
    return p.getStringList(_keyOwnedItems) ?? ['dino'];
  }

  static Future<void> addOwnedItem(String item) async {
    final p = await _prefs;
    final list = p.getStringList(_keyOwnedItems) ?? ['dino'];
    if (!list.contains(item)) {
      list.add(item);
      await p.setStringList(_keyOwnedItems, list);
    }
  }

  // ─── Stats ────────────────────────────────────────────────────────────────

  static Future<void> recordAnswer({required bool correct}) async {
    final p = await _prefs;
    final total = (p.getInt(_keyTotalAnswers) ?? 0) + 1;
    final correctCount =
        (p.getInt(_keyTotalCorrect) ?? 0) + (correct ? 1 : 0);
    await p.setInt(_keyTotalAnswers, total);
    await p.setInt(_keyTotalCorrect, correctCount);
  }

  static Future<int> getTotalCorrect() async {
    final p = await _prefs;
    return p.getInt(_keyTotalCorrect) ?? 0;
  }

  static Future<int> getTotalAnswers() async {
    final p = await _prefs;
    return p.getInt(_keyTotalAnswers) ?? 0;
  }

  static Future<void> addTimeSpent(int minutes) async {
    final p = await _prefs;
    final today = _todayStr();
    final lastDate = p.getString(_keyLastDate) ?? '';
    int current = p.getInt(_keyTimeSpent) ?? 0;
    if (lastDate != today) {
      current = 0;
      await p.setString(_keyLastDate, today);
    }
    await p.setInt(_keyTimeSpent, current + minutes);
  }

  static Future<int> getTimeSpentToday() async {
    final p = await _prefs;
    final today = _todayStr();
    final lastDate = p.getString(_keyLastDate) ?? '';
    if (lastDate != today) return 0;
    return p.getInt(_keyTimeSpent) ?? 0;
  }

  // ─── Volume ───────────────────────────────────────────────────────────────

  static Future<double> getVolume() async {
    final p = await _prefs;
    return p.getDouble(_keyVolume) ?? 0.7;
  }

  static Future<void> setVolume(double vol) async {
    final p = await _prefs;
    await p.setDouble(_keyVolume, vol);
  }

  // ─── Sign out ─────────────────────────────────────────────────────────────

  static Future<void> signOut() async {
    final p = await _prefs;
    await p.clear();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
