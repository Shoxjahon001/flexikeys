// Dart implementation of the deterministic adaptation policy.
// Must produce byte-identical numeric results to Python policy.apply() for the
// test cases defined in shared/adaptive_policy.json.
//
// All constants mirror shared/adaptive_policy.json → policy section.
// See docs/adr/adr_004_adaptive_engine.md for algorithm rationale.

import 'package:flexikeys/features/adaptive/adaptive_profile.dart';

// ── Policy constants ──────────────────────────────────────────────────────────

const double _accuracyLow = 0.60;
const double _accuracyHigh = 0.85;
const double _keyScaleStep = 0.05;
const double _keyScalePerKeyMax = 1.50;
const double _keyScaleGlobalMax = 1.40;
const double _keyScaleMin = 1.00;
const double _keySpacingStep = 0.05;
const double _keySpacingMax = 1.60;
const double _keySpacingMin = 1.00;
const int _dwellStepMs = 20;
const int _dwellMaxMs = 300;
const int _dwellMinMs = 0;
const int _hintMax = 3;
const int _hintMin = 0;
const double _hintDecayMasteryThreshold = 0.90;
const double _accidentalTapThreshold = 0.08;
const double _hesitationThresholdMs = 2000.0;
const double _touchOffsetThreshold = 0.30;

// ── Policy input types ────────────────────────────────────────────────────────

class PolicyMetrics {
  final double? accidentalTapRate;
  final double? touchPrecision;
  final bool fatigued;
  final Map<String, SkillMetrics> perSkill;

  const PolicyMetrics({
    this.accidentalTapRate,
    this.touchPrecision,
    this.fatigued = false,
    this.perSkill = const {},
  });
}

class SkillMetrics {
  final double? ewmaAccuracy;
  final double? hesitationMs;

  const SkillMetrics({this.ewmaAccuracy, this.hesitationMs});
}

class PolicyChange {
  final String param;
  final dynamic oldValue;
  final dynamic newValue;
  final String reasonCode;
  final String explanationKey;

  const PolicyChange({
    required this.param,
    required this.oldValue,
    required this.newValue,
    required this.reasonCode,
    required this.explanationKey,
  });
}

// ── Hysteresis state ──────────────────────────────────────────────────────────

class HysteresisEntry {
  final int direction; // +1 or -1
  final String sessionId;

  const HysteresisEntry({required this.direction, required this.sessionId});
}

// ── Main policy function ──────────────────────────────────────────────────────

class AdaptivePolicyResult {
  final AdaptationProfile profile;
  final List<PolicyChange> changes;

  const AdaptivePolicyResult({required this.profile, required this.changes});
}

/// Pure deterministic function — same inputs always produce same outputs.
/// Mirrors Python policy.apply() exactly.
AdaptivePolicyResult applyPolicy({
  required AdaptationProfile profile,
  required PolicyMetrics metrics,
  required Map<String, double> mastery,
  required Map<String, HysteresisEntry> lastChanges,
  required String sessionId,
}) {
  final changes = <PolicyChange>[];
  var newProfile = profile;

  // Mutable working copies of per-key maps
  final keyScalePerKey = Map<String, double>.from(newProfile.keyScalePerKey);
  final hintLevel = Map<String, int>.from(newProfile.hintLevel);
  var keyScale = newProfile.keyScale;
  var keySpacing = newProfile.keySpacing;
  var dwellTimeMs = newProfile.dwellTimeMs;
  var sessionPacing = newProfile.sessionPacing;

  bool canChange(String param, int direction) {
    final prev = lastChanges[param];
    if (prev == null) return true;
    if (prev.sessionId == sessionId) return true;
    return prev.direction != -direction;
  }

  void record(String param, dynamic old, dynamic newVal, String reason, String expl, int direction) {
    if (old == newVal) return;
    changes.add(PolicyChange(
      param: param,
      oldValue: old,
      newValue: newVal,
      reasonCode: reason,
      explanationKey: expl,
    ));
    lastChanges[param] = HysteresisEntry(direction: direction, sessionId: sessionId);
  }

  // ── Per-skill accuracy → key_scale_per_key ──────────────────────────────────
  for (final entry in metrics.perSkill.entries) {
    final sk = entry.key;
    final sm = entry.value;
    final paramK = 'key_scale.$sk';
    var currentScale = keyScalePerKey[sk] ?? 1.0;

    final acc = sm.ewmaAccuracy;
    if (acc != null) {
      if (acc < _accuracyLow && canChange(paramK, 1)) {
        final newScale = _r2(_clamp(currentScale + _keyScaleStep, _keyScaleMin, _keyScalePerKeyMax));
        record(paramK, currentScale, newScale, 'accuracy_drop', 'adaptation.key_scale_up', 1);
        keyScalePerKey[sk] = newScale;
        currentScale = newScale;
      } else if (acc >= _accuracyHigh && currentScale > _keyScaleMin && canChange(paramK, -1)) {
        final newScale = _r2(_clamp(currentScale - _keyScaleStep, _keyScaleMin, _keyScalePerKeyMax));
        record(paramK, currentScale, newScale, 'mastery_gain', 'adaptation.key_scale_down', -1);
        keyScalePerKey[sk] = newScale;
      }
    }

    // Hesitation → hint_level
    final paramH = 'hint_level.$sk';
    var curHint = hintLevel[sk] ?? 0;
    final hesitation = sm.hesitationMs;
    if (hesitation != null && hesitation > _hesitationThresholdMs && curHint < _hintMax && canChange(paramH, 1)) {
      final newHint = curHint + 1;
      record(paramH, curHint, newHint, 'latency_rise', 'adaptation.hint_level_up', 1);
      hintLevel[sk] = newHint;
      curHint = newHint;
    }

    // Mastery → hint decay
    final pKnown = mastery[sk] ?? 0.0;
    if (pKnown >= _hintDecayMasteryThreshold && curHint > _hintMin && canChange(paramH, -1)) {
      final newHint = (curHint - 1).clamp(_hintMin, _hintMax);
      record(paramH, curHint, newHint, 'mastery_gain', 'adaptation.hint_level_down', -1);
      hintLevel[sk] = newHint;
    }
  }

  // ── Accidental taps → dwell_time_ms + key_spacing ──────────────────────────
  final accTap = metrics.accidentalTapRate;
  if (accTap != null && accTap > _accidentalTapThreshold) {
    final oldDwell = dwellTimeMs;
    final newDwell = _clampInt(oldDwell + _dwellStepMs, _dwellMinMs, _dwellMaxMs);
    if (canChange('dwell_time_ms', 1)) {
      record('dwell_time_ms', oldDwell, newDwell, 'accidental_taps', 'adaptation.dwell_time_up', 1);
      dwellTimeMs = newDwell;
    }

    final oldSpacing = keySpacing;
    final newSpacing = _r2(_clamp(oldSpacing + _keySpacingStep, _keySpacingMin, _keySpacingMax));
    if (canChange('key_spacing', 1)) {
      record('key_spacing', oldSpacing, newSpacing, 'accidental_taps', 'adaptation.key_spacing_up', 1);
      keySpacing = newSpacing;
    }
  }

  // ── Touch precision → global key_scale ────────────────────────────────────
  final precision = metrics.touchPrecision;
  if (precision != null && precision > _touchOffsetThreshold) {
    final oldScale = keyScale;
    final newScale = _r2(_clamp(oldScale + _keyScaleStep, _keyScaleMin, _keyScaleGlobalMax));
    if (canChange('key_scale', 1)) {
      record('key_scale', oldScale, newScale, 'accuracy_drop', 'adaptation.global_scale_up', 1);
      keyScale = newScale;
    }
  }

  // ── Fatigue → suggest break ───────────────────────────────────────────────
  final oldBreak = sessionPacing.suggestBreak;
  if (metrics.fatigued && !oldBreak) {
    sessionPacing = const SessionPacing(suggestBreak: true);
    changes.add(const PolicyChange(
      param: 'session_pacing.suggest_break',
      oldValue: false,
      newValue: true,
      reasonCode: 'fatigue',
      explanationKey: 'adaptation.break_suggested',
    ));
  } else if (!metrics.fatigued && oldBreak) {
    sessionPacing = const SessionPacing(suggestBreak: false);
  }

  // ── Build new profile ─────────────────────────────────────────────────────
  final versionBump = changes.isNotEmpty ? newProfile.version + 1 : newProfile.version;
  newProfile = newProfile.copyWith(
    keyScale: keyScale,
    keyScalePerKey: keyScalePerKey,
    keySpacing: keySpacing,
    dwellTimeMs: dwellTimeMs,
    hintLevel: hintLevel,
    sessionPacing: sessionPacing,
    version: versionBump,
  );

  return AdaptivePolicyResult(profile: newProfile, changes: changes);
}

// ── Math utilities ────────────────────────────────────────────────────────────

double _clamp(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

int _clampInt(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

/// Round to 2 decimal places (mirrors Python round(v, 2)).
double _r2(double v) => (v * 100).roundToDouble() / 100;
