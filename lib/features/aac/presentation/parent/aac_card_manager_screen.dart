library aac_card_manager_screen;

import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/aac_audio_player.dart';
import '../../data/aac_custom_card_store.dart';
import '../../domain/aac_card_def.dart';
import '../aac_glyphs.dart';
import '../aac_strings.dart';

/// Parent-created custom AAC cards — docs/aac_design_system.md Phase 4.
///
/// A card's "voice" is the typed label read aloud via TtsService by
/// default, with an optional real recording of the parent's own voice
/// (Phase 5) — see `_VoiceRecorderField`. The written label is always
/// required regardless (it's what's shown on the card); recording only
/// replaces what's *spoken*. Cards are local-only, not synced to the
/// backend, and not scoped per-child — matching how the rest of this app's
/// local-only stores (UserService, ProgressStore) already work off a
/// single "active child" per device rather than a child_id key.
class AacCardManagerScreen extends StatefulWidget {
  const AacCardManagerScreen({super.key});

  @override
  State<AacCardManagerScreen> createState() => _AacCardManagerScreenState();
}

class _AacCardManagerScreenState extends State<AacCardManagerScreen> {
  List<AacCardDef> _cards = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await AacCustomCardStore.instance.getAll();
    if (mounted) {
      setState(() {
        _cards = all;
        _loading = false;
      });
    }
  }

  Future<void> _addOrEdit({AacCardDef? existing}) async {
    final saved = await Navigator.push<AacCardDef>(
      context,
      MaterialPageRoute(builder: (_) => _CardFormScreen(existing: existing)),
    );
    if (saved == null) return;
    if (existing == null) {
      await AacCustomCardStore.instance.add(saved);
    } else {
      await AacCustomCardStore.instance.update(saved);
    }
    await _load();
  }

  Future<void> _delete(AacCardDef card) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await FkDialog.confirm(
      context,
      title: t.removeCardDialogTitle,
      message: t.removeCardDialogBody(card.label.values.firstOrNull ?? card.id),
      confirmLabel: t.removeButton,
      cancelLabel: t.cancelButton,
      isDestructive: true,
    );
    if (confirmed != true) return;
    await AacCustomCardStore.instance.remove(card.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: FkAppBar(title: t.manageCardsAppBarTitle),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _addOrEdit(),
        icon: const Icon(Icons.add_rounded),
        label: Text(t.addCardButton),
      ),
      body: _loading
          ? const Center(child: FkLoadingIndicator())
          : _cards.isEmpty
              ? FkEmptyState(
                  illustration: Icon(Icons.style_outlined,
                      size: 56, color: colors.textTertiary),
                  title: t.noCustomCardsEmptyState,
                  description: '',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: _cards.length,
                  itemBuilder: (context, i) {
                    final card = _cards[i];
                    return FkListRow(
                      leading: SizedBox(
                        width: 44,
                        height: 44,
                        child: glyphForCard(card, size: 32),
                      ),
                      label: card.label.values.firstOrNull ?? card.id,
                      subtitle: card.category.name,
                      showChevron: false,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_rounded),
                            onPressed: () => _addOrEdit(existing: card),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                color: colors.danger),
                            onPressed: () => _delete(card),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class _CardFormScreen extends StatefulWidget {
  final AacCardDef? existing;

  const _CardFormScreen({this.existing});

  @override
  State<_CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<_CardFormScreen> {
  late final TextEditingController _labelController;
  AacCategory _category = AacCategory.needs;
  String? _photoPath;
  String? _recordedAudioPath;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _labelController = TextEditingController(
      text: existing?.label.values.firstOrNull ?? '',
    );
    _category = existing?.category ?? AacCategory.needs;
    _photoPath = existing?.customPhotoPath;
    // Custom cards' audioAsset, when set, is always a recorded device file
    // (never a bundled asset) — see AacAudioPlayer.speak's doc comment.
    // A parent's own typed label / recorded voice isn't translated per
    // language — it's the same text/audio no matter which learning
    // language is active — so it's saved under every AacLanguage below
    // (AacCustomCardStore backfills older single-language cards to match
    // on load), and reading it back here doesn't need to pick a language.
    _recordedAudioPath = existing?.audioAsset.values.firstOrNull;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final t = AppLocalizations.of(context)!;
    final source = await FkBottomSheet.show<ImageSource>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: Text(t.chooseFromPhotos),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: Text(t.takePhoto),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
        ],
      ),
    );
    if (source == null) return;

    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${dir.path}/aac_custom_photos');
    await photosDir.create(recursive: true);
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${picked.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '')}';
    final savedPath = '${photosDir.path}/$fileName';
    await File(picked.path).copy(savedPath);

    if (mounted) setState(() => _photoPath = savedPath);
  }

  void _save() {
    final label = _labelController.text.trim();
    if (label.isEmpty) return;

    final id = widget.existing?.id ??
        'custom_${DateTime.now().millisecondsSinceEpoch}';
    // Saved under every AacLanguage, not just whichever is currently
    // active: a parent's typed label / recorded voice is the same
    // regardless of the child's learning language, so the card must
    // display and speak correctly no matter which language is active —
    // see AacCustomCardStore._backfillAllLanguages for the same reasoning
    // applied to cards saved before this fix.
    final everyLanguage = {for (final lang in AacLanguage.values) lang: label};
    final card = AacCardDef(
      id: id,
      category: _category,
      kind: AacCardKind.direct,
      label: everyLanguage,
      // The spoken sentence IS the typed label, exactly as written — no
      // assumed "I want {noun}" grammar (see AacSentenceComposerService's
      // doc comment for the same reasoning applied to Sentence Strip words).
      sentenceTemplate: everyLanguage,
      animationAsset: '',
      // A recorded voice takes priority (AacAudioPlayer.speak, isDeviceFile:
      // isCustom); with none, AacAudioPlayer falls back to TTS reading the
      // label above.
      audioAsset: _recordedAudioPath != null
          ? {for (final lang in AacLanguage.values) lang: _recordedAudioPath!}
          : const {},
      customPhotoPath: _photoPath,
      difficultyTier: 1,
      isCustom: true,
    );
    Navigator.pop(context, card);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final aac = AacTheme.of(context);
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: FkAppBar(
        title: isEditing ? t.editCardTitle : t.newCardTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: aac.tintFor(_category),
                  borderRadius: BorderRadius.circular(AacSizes.cardRadius),
                  border: Border.all(color: aac.colorFor(_category), width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: _photoPath != null
                    ? Image.file(File(_photoPath!), fit: BoxFit.cover)
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo_rounded,
                                color: aac.colorFor(_category)),
                            const SizedBox(height: 4),
                            Text(t.addPhotoLabel, style: textTheme.bodySmall),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FkTextField(
            labelText: t.cardLabelField,
            hintText: t.cardLabelHint,
            controller: _labelController,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(t.voiceOptionalLabel, style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            t.voiceHelperText,
            style: textTheme.bodySmall?.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          _VoiceRecorderField(
            initialPath: _recordedAudioPath,
            onChanged: (path) => setState(() => _recordedAudioPath = path),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(t.categoryLabel, style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: AacCategory.values.map((c) {
              final selected = c == _category;
              return ChoiceChip(
                label: Text(c.name),
                selected: selected,
                onSelected: (_) => setState(() => _category = c),
                selectedColor: aac.colorFor(c),
                labelStyle: textTheme.bodySmall?.copyWith(
                  color: selected ? Colors.white : colors.textPrimary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_labelController.text.trim().isNotEmpty) ...[
            Text(t.previewLabel, style: textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: AacCard(
                category: _category,
                label: _labelController.text.trim(),
                glyph: _photoPath != null
                    ? ClipRRect(
                        borderRadius: AppRadius.smAll,
                        child: Image.file(File(_photoPath!),
                            width: 78, height: 78, fit: BoxFit.cover),
                      )
                    : aacGlyph('💬'),
                onActivate: () {},
                onSpeak: () => AacAudioPlayer.instance.speak(
                  bundledAssetPath: _recordedAudioPath,
                  sentence: _labelController.text.trim(),
                  language: AacLanguage.en,
                  isDeviceFile: true,
                ),
                speakLabel: AacStrings.of(AacLanguage.en).speakTooltip,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          FkPrimaryButton(
            label: isEditing ? t.saveChangesButton : t.addCardButton,
            fullWidth: true,
            onPressed: _labelController.text.trim().isEmpty ? null : _save,
          ),
        ],
      ),
    );
  }
}

/// Record / preview / re-record a parent's own voice for a custom card.
/// Saved under the app's documents directory (`aac_custom_audio/`), same
/// pattern as `_pickPhoto`'s `aac_custom_photos/` — survives app restarts,
/// unlike the recorder's own default temp path.
class _VoiceRecorderField extends StatefulWidget {
  final String? initialPath;
  final ValueChanged<String?> onChanged;

  const _VoiceRecorderField(
      {required this.initialPath, required this.onChanged});

  @override
  State<_VoiceRecorderField> createState() => _VoiceRecorderFieldState();
}

class _VoiceRecorderFieldState extends State<_VoiceRecorderField> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _previewPlayer = AudioPlayer();
  String? _path;
  bool _recording = false;
  bool _playing = false;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _path = widget.initialPath;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        FkToast.show(
          context,
          AppLocalizations.of(context)!.micPermissionSnackbar,
          type: FkToastType.error,
        );
      }
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/aac_custom_audio');
    await audioDir.create(recursive: true);
    final path =
        '${audioDir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);

    if (!mounted) return;
    setState(() {
      _recording = true;
      _elapsed = Duration.zero;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    _ticker?.cancel();
    if (!mounted) return;
    setState(() {
      _recording = false;
      _path = path;
    });
    widget.onChanged(_path);
  }

  Future<void> _togglePreview() async {
    if (_path == null) return;
    if (_playing) {
      await _previewPlayer.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }
    setState(() => _playing = true);
    // Subscribed before play() is awaited — play()'s Future resolves once
    // playback starts, not once it ends, so attaching this listener only
    // afterward could miss a short recording's completion event and leave
    // the button stuck showing "Pause" forever.
    unawaited(
      _previewPlayer.onPlayerComplete.first.then((_) {
        if (mounted) setState(() => _playing = false);
      }),
    );
    await _previewPlayer.play(DeviceFileSource(_path!));
  }

  void _reRecord() {
    setState(() => _path = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    if (_recording) {
      return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          border: Border.all(color: colors.danger),
          borderRadius: AppRadius.smAll,
        ),
        child: Row(
          children: [
            Icon(Icons.fiber_manual_record_rounded,
                color: colors.danger, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text(t.recordingStatusLabel(_elapsed.inSeconds),
                style: textTheme.bodyMedium),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.stop_circle_rounded),
              tooltip: t.stopTooltip,
              onPressed: _stopRecording,
            ),
          ],
        ),
      );
    }

    if (_path != null) {
      return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          border: Border.all(color: colors.border),
          borderRadius: AppRadius.smAll,
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(_playing
                  ? Icons.pause_circle_rounded
                  : Icons.play_circle_rounded),
              tooltip: _playing ? t.pauseTooltip : t.playTooltip,
              onPressed: _togglePreview,
            ),
            Expanded(
              child: Text(t.voiceRecordedLabel, style: textTheme.bodyMedium),
            ),
            TextButton(onPressed: _reRecord, child: Text(t.reRecordButton)),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: _startRecording,
      icon: const Icon(Icons.mic_rounded),
      label: Text(t.recordVoiceButton),
    );
  }
}
