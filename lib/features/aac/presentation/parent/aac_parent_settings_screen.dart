library aac_parent_settings_screen;

import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/aac_progression_store.dart';
import '../../data/aac_settings_store.dart';
import '../../domain/aac_progression.dart';

/// "My Voice" accessibility + progression settings — docs/aac_design_system.md
/// Phase 4. Reuses AacSettingsStore (Phase 2) and AacProgressionStore
/// (persisted here for the first time — the model existed since Phase 1 but
/// had no store until this screen needed one to write to).
class AacParentSettingsScreen extends StatefulWidget {
  const AacParentSettingsScreen({super.key});

  @override
  State<AacParentSettingsScreen> createState() =>
      _AacParentSettingsScreenState();
}

class _AacParentSettingsScreenState extends State<AacParentSettingsScreen> {
  AacSettings _settings = const AacSettings();
  AacProgressionState? _progression;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      AacSettingsStore.instance.get(),
      AacProgressionStore.instance.get(),
    ]);
    if (!mounted) return;
    setState(() {
      _settings = results[0] as AacSettings;
      _progression = results[1] as AacProgressionState;
      _loading = false;
    });
  }

  Future<void> _updateSettings(AacSettings settings) async {
    setState(() => _settings = settings);
    await AacSettingsStore.instance.update(settings);
  }

  Future<void> _updateLevel(AacLevel level) async {
    await AacProgressionStore.instance.setLevel(level);
    final updated = await AacProgressionStore.instance.get();
    if (mounted) setState(() => _progression = updated);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: FkColors.background,
      appBar: AppBar(
        backgroundColor: FkColors.background,
        elevation: 0,
        title:
            Text(t.myVoiceSettingsTitle, style: FkTextStyles.adultHeadline),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(FkSpacing.sm),
              children: [
                _SectionHeader(title: t.progressionLevelHeader),
                FkCard(
                  child: Padding(
                    padding: const EdgeInsets.all(FkSpacing.sm),
                    child: _LevelPicker(
                      current: _progression?.level ?? AacLevel.level1,
                      onChanged: _updateLevel,
                    ),
                  ),
                ),
                const SizedBox(height: FkSpacing.sm),
                _SectionHeader(title: t.cardSizeHeader),
                FkCard(
                  child: Padding(
                    padding: const EdgeInsets.all(FkSpacing.sm),
                    child: _CardSizePicker(
                      current: _settings.cardSize,
                      onChanged: (size) =>
                          _updateSettings(_settings.copyWith(cardSize: size)),
                    ),
                  ),
                ),
                const SizedBox(height: FkSpacing.sm),
                _SectionHeader(title: t.accessibilityHeader),
                FkCard(
                  // FkCard now provides its own Material ancestor for
                  // ListTile/SwitchListTile ink effects — see fk_card.dart.
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text(t.dwellTimeSwitchTitle,
                            style: FkTextStyles.adultBody),
                        subtitle: Text(
                          t.dwellTimeSwitchSubtitle,
                          style: FkTextStyles.adultCaption,
                        ),
                        value: _settings.dwellEnabled,
                        onChanged: (v) => _updateSettings(
                            _settings.copyWith(dwellEnabled: v)),
                      ),
                      if (_settings.dwellEnabled)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            FkSpacing.sm,
                            0,
                            FkSpacing.sm,
                            FkSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              Text(t.holdDurationLabel,
                                  style: FkTextStyles.adultCaption),
                              Expanded(
                                child: Slider(
                                  value: _settings.dwellDuration.inMilliseconds
                                      .toDouble()
                                      .clamp(
                                        AacSizes.dwellMin.inMilliseconds
                                            .toDouble(),
                                        AacSizes.dwellMax.inMilliseconds
                                            .toDouble(),
                                      ),
                                  min: AacSizes.dwellMin.inMilliseconds
                                      .toDouble(),
                                  max: AacSizes.dwellMax.inMilliseconds
                                      .toDouble(),
                                  divisions: 17,
                                  label: t.holdDurationMs(
                                      _settings.dwellDuration.inMilliseconds),
                                  onChanged: (v) => _updateSettings(
                                    _settings.copyWith(
                                      dwellDuration:
                                          Duration(milliseconds: v.round()),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text(t.highContrastSwitchTitle,
                            style: FkTextStyles.adultBody),
                        subtitle: Text(
                          t.highContrastSwitchSubtitle,
                          style: FkTextStyles.adultCaption,
                        ),
                        value: _settings.highContrast,
                        onChanged: (v) => _updateSettings(
                            _settings.copyWith(highContrast: v)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text(t.reducedMotionSwitchTitle,
                            style: FkTextStyles.adultBody),
                        subtitle: Text(
                          t.reducedMotionSwitchSubtitle,
                          style: FkTextStyles.adultCaption,
                        ),
                        value: _settings.reducedMotion,
                        onChanged: (v) => _updateSettings(
                            _settings.copyWith(reducedMotion: v)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _LevelPicker extends StatelessWidget {
  final AacLevel current;
  final ValueChanged<AacLevel> onChanged;

  const _LevelPicker({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final descriptions = {
      AacLevel.level1: t.level1Option,
      AacLevel.level2: t.level2Option,
      AacLevel.level3: t.level3Option,
      AacLevel.level4: t.level4Option,
    };
    return Column(
      children: AacLevel.values.map((level) {
        final selected = level == current;
        return Padding(
          padding: const EdgeInsets.only(bottom: FkSpacing.xxs),
          child: GestureDetector(
            onTap: () => onChanged(level),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: FkSpacing.sm,
                vertical: FkSpacing.xs,
              ),
              decoration: BoxDecoration(
                color:
                    selected ? FkColors.lavender.withValues(alpha: 0.15) : null,
                borderRadius: FkRadii.smAll,
                border: Border.all(
                  color: selected ? FkColors.lavender : FkColors.disabled,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected ? FkColors.lavender : FkColors.disabledInk,
                  ),
                  const SizedBox(width: FkSpacing.xs),
                  Expanded(
                    child: Text(descriptions[level]!,
                        style: FkTextStyles.adultBody),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CardSizePicker extends StatelessWidget {
  final AacCardSizeSetting current;
  final ValueChanged<AacCardSizeSetting> onChanged;

  const _CardSizePicker({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final labels = {
      AacCardSizeSetting.l: t.cardSizeLOption,
      AacCardSizeSetting.xl: t.cardSizeXLOption,
      AacCardSizeSetting.xxl: t.cardSizeXXLOption,
    };
    return Row(
      children: AacCardSizeSetting.values.map((size) {
        final selected = size == current;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: FkSpacing.xxs),
            child: GestureDetector(
              onTap: () => onChanged(size),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: FkSpacing.xs),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? FkColors.lavender : FkColors.background,
                  borderRadius: FkRadii.smAll,
                  border: Border.all(
                    color: selected ? FkColors.lavender : FkColors.disabled,
                  ),
                ),
                child: Text(
                  labels[size]!,
                  style: FkTextStyles.adultBody.copyWith(
                    color: selected ? Colors.white : FkColors.ink,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FkSpacing.xs, left: FkSpacing.xxs),
      child: Text(title, style: FkTextStyles.adultCaption),
    );
  }
}
