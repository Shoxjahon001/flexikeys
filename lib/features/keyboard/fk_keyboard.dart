library fk_keyboard;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../design_system/components/keyboard/fk_keyboard_metrics.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_motion.dart';
import '../../design_system/tokens/app_radius.dart';
import '../../design_system/tokens/app_shadows.dart';
import '../../design_system/tokens/app_typography.dart';
import '../../features/adaptive/adaptive_profile.dart';
import 'keyboard_layouts.dart';

/// Telemetry record emitted on every resolved keystroke.
class KeystrokeRecord {
  final String targetKey;
  final String actualKey;
  final bool correct;
  final double latencyMs;
  final double timeToFirstTouchMs;
  final Offset touchOffset;
  final double offsetRatio;
  final bool accidentalTap;
  final bool rejectedByDwell;
  final bool rejectedByDebounce;

  const KeystrokeRecord({
    required this.targetKey,
    required this.actualKey,
    required this.correct,
    required this.latencyMs,
    required this.timeToFirstTouchMs,
    required this.touchOffset,
    required this.offsetRatio,
    this.accidentalTap = false,
    this.rejectedByDwell = false,
    this.rejectedByDebounce = false,
  });
}

/// Adaptive keyboard — renders from [profile] + [layout].
///
/// Input pipeline: raw pointer → dwell filter → debounce filter → keystroke event.
/// Rejected taps are logged as accidentals but show NO negative feedback to child.
///
/// Hint levels:
///   0 — none
///   1 — target key pulses gently
///   2 — pulse + non-targets dimmed
///   3 — pulse + non-targets dimmed + audio prompt (caller handles audio)
class FkKeyboard extends StatefulWidget {
  final KeyboardLayout layout;
  final AdaptationProfile profile;
  final String targetKey;
  final ValueChanged<KeystrokeRecord>? onKeystroke;
  final VoidCallback? onAudioPrompt;

  const FkKeyboard({
    super.key,
    required this.layout,
    required this.profile,
    required this.targetKey,
    this.onKeystroke,
    this.onAudioPrompt,
  });

  @override
  State<FkKeyboard> createState() => _FkKeyboardState();
}

class _FkKeyboardState extends State<FkKeyboard> {
  // Per-key dwell state: key value → dwell timer + start time
  final Map<String, _DwellState> _dwell = {};
  DateTime? _sessionItemStart; // when item was shown (time-to-first-touch base)

  // Debounce: last accepted key + its accept time
  String? _lastAcceptedKey;
  DateTime? _lastAcceptedAt;

  @override
  void initState() {
    super.initState();
    _sessionItemStart = DateTime.now();
    _scheduleAudioPromptIfNeeded();
  }

  @override
  void didUpdateWidget(FkKeyboard old) {
    super.didUpdateWidget(old);
    if (old.targetKey != widget.targetKey) {
      _sessionItemStart = DateTime.now();
      _scheduleAudioPromptIfNeeded();
    }
    // Layout change is safe: _dwell timers reset when keys are rebuilt.
    if (old.layout.language != widget.layout.language ||
        old.profile.keyScale != widget.profile.keyScale ||
        old.profile.keySpacing != widget.profile.keySpacing) {
      _dwell.clear();
    }
  }

  void _scheduleAudioPromptIfNeeded() {
    final hintLevel = widget.profile.hintLevel[widget.targetKey] ?? 0;
    if (hintLevel >= 3 && widget.onAudioPrompt != null) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) widget.onAudioPrompt?.call();
      });
    }
  }

  void _onPointerDown(String key, Offset localPos, Offset keySize) {
    final dwellMs = widget.profile.dwellTimeMs;
    final now = DateTime.now();
    final timeToFirstTouch = _sessionItemStart != null
        ? now.difference(_sessionItemStart!).inMicroseconds / 1000.0
        : 0.0;

    if (dwellMs <= 0) {
      _resolveKey(key, localPos, keySize, timeToFirstTouch, rejectedByDwell: false);
      return;
    }

    // Start dwell timer
    final timer = Timer(Duration(milliseconds: dwellMs), () {
      _resolveKey(key, localPos, keySize, timeToFirstTouch, rejectedByDwell: false);
      setState(() => _dwell.remove(key));
    });

    setState(() {
      _dwell[key] = _DwellState(
        timer: timer,
        startTime: now,
        dwellMs: dwellMs,
        localPos: localPos,
        keySize: keySize,
        timeToFirstTouch: timeToFirstTouch,
      );
    });
  }

  void _onPointerUp(String key) {
    final ds = _dwell[key];
    if (ds == null) return;
    // Lifted before dwell threshold — accidental tap
    ds.timer.cancel();
    setState(() => _dwell.remove(key));

    final record = KeystrokeRecord(
      targetKey: widget.targetKey,
      actualKey: key,
      correct: key == widget.targetKey,
      latencyMs: DateTime.now().difference(ds.startTime).inMicroseconds / 1000.0,
      timeToFirstTouchMs: ds.timeToFirstTouch,
      touchOffset: ds.localPos - Offset(ds.keySize.dx / 2, ds.keySize.dy / 2),
      offsetRatio: _offsetRatio(ds.localPos, ds.keySize),
      accidentalTap: true,
      rejectedByDwell: true,
    );
    widget.onKeystroke?.call(record);
  }

  void _resolveKey(
    String key,
    Offset localPos,
    Offset keySize,
    double timeToFirstTouch, {
    required bool rejectedByDwell,
  }) {
    final now = DateTime.now();
    final debounceMs = widget.profile.debounceMs;

    // Debounce: reject if same key accepted within debounce window
    bool rejectedByDebounce = false;
    if (_lastAcceptedKey == key && _lastAcceptedAt != null) {
      final elapsed = now.difference(_lastAcceptedAt!).inMilliseconds;
      if (elapsed < debounceMs) {
        rejectedByDebounce = true;
      }
    }

    final offsetVec = localPos - _centerOf(keySize);
    final offsetR = _offsetRatio(localPos, keySize);

    final record = KeystrokeRecord(
      targetKey: widget.targetKey,
      actualKey: key,
      correct: key == widget.targetKey,
      latencyMs: timeToFirstTouch > 0 ? timeToFirstTouch : 0,
      timeToFirstTouchMs: timeToFirstTouch,
      touchOffset: offsetVec,
      offsetRatio: offsetR,
      accidentalTap: rejectedByDwell || rejectedByDebounce,
      rejectedByDwell: rejectedByDwell,
      rejectedByDebounce: rejectedByDebounce,
    );

    if (!rejectedByDebounce && !rejectedByDwell) {
      _lastAcceptedKey = key;
      _lastAcceptedAt = now;
    }

    widget.onKeystroke?.call(record);
  }

  static Offset _centerOf(Offset keySize) => Offset(keySize.dx / 2, keySize.dy / 2);

  static double _offsetRatio(Offset localPos, Offset keySize) {
    final cx = keySize.dx / 2;
    final cy = keySize.dy / 2;
    final dx = (localPos.dx - cx).abs() / cx;
    final dy = (localPos.dy - cy).abs() / cy;
    return (dx + dy) / 2;
  }

  @override
  void dispose() {
    for (final ds in _dwell.values) {
      ds.timer.cancel();
    }
    _dwell.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final hintLevel = profile.hintLevel[widget.targetKey] ?? 0;

    return AnimatedContainer(
      duration: AppMotion.slow,
      curve: AppMotion.transition,
      color: AppColors.background,
      padding: EdgeInsets.all(FkKeyboardMetrics.outerPadding(profile)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.layout.rows.map((row) {
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: FkKeyboardMetrics.innerSpacing(profile),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((keyDef) {
                return _KeyWidget(
                  keyDef: keyDef,
                  profile: profile,
                  targetKey: widget.targetKey,
                  hintLevel: hintLevel,
                  dwellProgress: _dwell[keyDef.value]?.progress ?? 0.0,
                  onPointerDown: (lp, ks) => _onPointerDown(keyDef.value, lp, ks),
                  onPointerUp: () => _onPointerUp(keyDef.value),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DwellState {
  final Timer timer;
  final DateTime startTime;
  final int dwellMs;
  final Offset localPos;
  final Offset keySize;
  final double timeToFirstTouch;

  _DwellState({
    required this.timer,
    required this.startTime,
    required this.dwellMs,
    required this.localPos,
    required this.keySize,
    required this.timeToFirstTouch,
  });

  double get progress {
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    return (elapsed / dwellMs).clamp(0.0, 1.0);
  }
}

/// Individual key widget with dwell fill, hint pulse, and per-key scaling.
class _KeyWidget extends StatefulWidget {
  final KeyDef keyDef;
  final AdaptationProfile profile;
  final String targetKey;
  final int hintLevel;
  final double dwellProgress;
  final void Function(Offset localPos, Offset keySize) onPointerDown;
  final VoidCallback onPointerUp;

  const _KeyWidget({
    required this.keyDef,
    required this.profile,
    required this.targetKey,
    required this.hintLevel,
    required this.dwellProgress,
    required this.onPointerDown,
    required this.onPointerUp,
  });

  @override
  State<_KeyWidget> createState() => _KeyWidgetState();
}

class _KeyWidgetState extends State<_KeyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  bool get _isTarget => widget.keyDef.value == widget.targetKey;
  bool get _isBackspace => widget.keyDef.value == '⌫';

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulse, curve: AppMotion.transition),
    );
    _updatePulse();
  }

  @override
  void didUpdateWidget(_KeyWidget old) {
    super.didUpdateWidget(old);
    if (old.hintLevel != widget.hintLevel || old.targetKey != widget.targetKey) {
      _updatePulse();
    }
  }

  void _updatePulse() {
    final shouldPulse = _isTarget && widget.hintLevel >= 1;
    final reduced = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.reduceMotion;
    if (shouldPulse && !reduced) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    // Key geometry — see fk_keyboard_metrics.dart for why this stays
    // pinned/isolated from the token system.
    final size = FkKeyboardMetrics.keySize(
      profile: profile,
      keyDef: widget.keyDef,
      isBackspace: _isBackspace,
    );
    final effectiveW = size.width;
    final effectiveH = size.height;
    final spacing = FkKeyboardMetrics.innerSpacing(profile);
    final fontSize = FkKeyboardMetrics.keyFontSize(profile);

    // Color logic. Note: AppColors.primary is a vivid, saturated purple —
    // unlike the legacy fk.primary it replaces (a pale lavender that
    // worked fine with dark ink text), so the target-key state needs a
    // white foreground for contrast, not the shared dark default below.
    Color bg;
    Color fg = AppColors.textPrimary;
    if (_isBackspace) {
      bg = AppColors.surface;
    } else if (_isTarget && widget.hintLevel >= 1) {
      bg = AppColors.primary;
      fg = Colors.white;
    } else if (widget.hintLevel >= 2 && !_isTarget) {
      bg = AppColors.surfaceMuted.withValues(alpha: 0.6);
      fg = AppColors.textSecondary;
    } else {
      bg = AppColors.surface;
    }

    return Padding(
      padding: EdgeInsets.all(spacing),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) => Transform.scale(
          scale: _isTarget ? _pulseAnim.value : 1.0,
          child: child,
        ),
        child: Listener(
          onPointerDown: (e) => widget.onPointerDown(
            e.localPosition,
            Offset(effectiveW, effectiveH),
          ),
          onPointerUp: (_) => widget.onPointerUp(),
          onPointerCancel: (_) => widget.onPointerUp(),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: AppMotion.fast,
                width: effectiveW,
                height: effectiveH,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: AppRadius.mdAll, // 16dp — same value as the old FkRadii.sm it replaces
                  boxShadow: AppShadows.soft,
                ),
                child: Center(
                  child: Text(
                    widget.keyDef.value,
                    style: AppTypography.bodyLarge.copyWith(
                      fontSize: fontSize,
                      color: fg,
                    ),
                  ),
                ),
              ),
              // Dwell fill overlay — fills softly as dwell progresses
              if (widget.dwellProgress > 0)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: AppRadius.mdAll,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: widget.dwellProgress,
                        child: Container(
                          color: AppColors.success.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}