library assistant_screen;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../application/follow_up_suggestions.dart';
import '../../application/insights.dart';
import '../../application/parent_provider.dart';
import '../../domain/parent_models.dart';

/// Parent AI assistant chat screen.
/// Grounded: the backend assembles child data before sending to the LLM.
/// No child PII is forwarded to the AI provider beyond display_name.
class AssistantScreen extends ConsumerStatefulWidget {
  final String childId;

  const AssistantScreen({super.key, required this.childId});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final message = (text ?? _controller.text).trim();
    if (message.isEmpty) return;
    _controller.clear();

    await ref.read(assistantProvider.notifier).sendMessage(
          childId: widget.childId,
          message: message,
          uiLanguage: 'en',
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: FkDurations.normal,
          curve: FkCurves.gentle,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantProvider);

    return Column(
      children: [
        _InsightStrip(childId: widget.childId),
        if (state.messages.isEmpty)
          Expanded(child: _HeroAndPrompts(onTap: _send))
        else
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(FkSpacing.sm),
              itemCount: state.messages.length +
                  (_showFollowUps(state) ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == state.messages.length) {
                  final lastUser = state.messages.reversed
                      .firstWhere((m) => m.isUser, orElse: () => state.messages.last);
                  return _FollowUpChips(
                    suggestions: followUpSuggestions(lastUser.content),
                    onTap: _send,
                  );
                }
                return _MessageBubble(msg: state.messages[i]);
              },
            ),
          ),
        if (state.loading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: FkSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _TypingBubble(),
            ),
          ),
        _InputBar(
          controller: _controller,
          loading: state.loading,
          onSend: () => _send(),
        ),
      ],
    );
  }

  bool _showFollowUps(AssistantState state) =>
      !state.loading && state.messages.isNotEmpty && state.messages.last.isAssistant;
}

// ── Insight strip ────────────────────────────────────────────────────────────

/// Horizontally-scrollable row of proactive, real-data insight cards shown
/// above the chat at all times. Silently renders nothing while loading or on
/// error — insights are a bonus, never a blocker for the chat itself.
class _InsightStrip extends ConsumerWidget {
  final String childId;
  const _InsightStrip({required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(childSummaryProvider(childId));
    final tsAsync = ref.watch(
      timeseriesProvider((childId: childId, metric: 'accuracy', rangeDays: 14)),
    );

    final summary = summaryAsync.valueOrNull;
    final points = tsAsync.valueOrNull;
    if (summary == null || points == null) return const SizedBox.shrink();

    final insights = buildInsights(summary: summary, accuracyPoints: points);
    if (insights.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 92,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(FkSpacing.sm, FkSpacing.xs, FkSpacing.sm, 0),
        scrollDirection: Axis.horizontal,
        itemCount: insights.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _InsightCardView(insight: insights[i], index: i),
      ),
    );
  }
}

class _InsightCardView extends StatelessWidget {
  final InsightCard insight;
  final int index;
  const _InsightCardView({required this.insight, required this.index});

  Color get _tint => switch (insight.tone) {
        InsightTone.positive => FkColors.mint,
        InsightTone.attention => FkColors.warmYellow,
        InsightTone.neutral => FkColors.lavender,
      };

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: FkDurations.slow,
      curve: FkCurves.gentle,
      // Slight stagger so cards don't all pop in at once.
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 8), child: child),
      ),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FkColors.surface,
          borderRadius: FkRadii.mdAll,
          border: Border.all(color: _tint, width: 1.5),
          boxShadow: FkElevation.low(FkColors.ink),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(color: _tint, shape: BoxShape.circle),
                  child: Icon(insight.icon, size: 14, color: FkColors.ink),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight.headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FkTextStyles.adultLabel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              insight.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: FkTextStyles.adultCaption,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero + quick prompts (empty state) ──────────────────────────────────────

class _HeroAndPrompts extends StatelessWidget {
  final void Function(String) onTap;
  const _HeroAndPrompts({required this.onTap});

  static const _prompts = [
    'How is my child doing?',
    'Explain today\'s report',
    'Weekly summary',
    'Practice suggestions',
    'Strengths',
    'Weaknesses',
    'Daily goals',
    'Learning tips',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(FkSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: FkSpacing.sm),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: FkColors.lavender, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, color: FkColors.ink, size: 26),
          ),
          const SizedBox(height: FkSpacing.sm),
          const Text('Your learning assistant', style: FkTextStyles.adultHeadline),
          const SizedBox(height: FkSpacing.xs),
          const Text(
            'Ask about recent practice, get activity ideas, or ask why the '
            'keyboard adapted — every answer is grounded in your child\'s '
            'actual data.',
            style: FkTextStyles.adultBody,
          ),
          const SizedBox(height: FkSpacing.md),
          const Text('Try asking:', style: FkTextStyles.adultLabel),
          const SizedBox(height: FkSpacing.xs),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _prompts.map((q) => _PromptChip(label: q, onTap: () => onTap(q))).toList(),
          ),
          const SizedBox(height: FkSpacing.md),
          const Text(
            'This assistant provides educational guidance only and is not a '
            'substitute for medical or therapeutic advice.',
            style: FkTextStyles.adultCaption,
          ),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PromptChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: FkColors.surface,
          borderRadius: FkRadii.pillAll,
          border: Border.all(color: FkColors.disabled),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lightbulb_outline_rounded, size: 14, color: FkColors.lavender),
            const SizedBox(width: 6),
            Text(label, style: FkTextStyles.adultCaption),
          ],
        ),
      ),
    );
  }
}

// ── Follow-up chips (after an assistant reply) ──────────────────────────────

class _FollowUpChips extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onTap;
  const _FollowUpChips({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((s) => _PromptChip(label: s, onTap: () => onTap(s))).toList(),
      ),
    );
  }
}

// ── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: isUser ? null : () => _copy(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? FkColors.lavender : FkColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(FkRadii.md),
                  topRight: const Radius.circular(FkRadii.md),
                  bottomLeft: Radius.circular(isUser ? FkRadii.md : 4),
                  bottomRight: Radius.circular(isUser ? 4 : FkRadii.md),
                ),
                boxShadow: FkElevation.low(FkColors.lavender),
              ),
              child: isUser
                  ? Text(msg.content, style: FkTextStyles.adultBody.copyWith(color: FkColors.ink))
                  : _MarkdownLiteText(msg.content),
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(_relativeTime(msg.createdAt), style: FkTextStyles.adultCaption),
          ),
        ],
      ),
    );

    final row = Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: isUser
          ? [bubble]
          : [const _AssistantAvatar(), const SizedBox(width: 8), Flexible(child: bubble)],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _EntranceFade(child: row),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: msg.content));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(color: FkColors.lavender, shape: BoxShape.circle),
      child: const Icon(Icons.auto_awesome_rounded, size: 14, color: FkColors.ink),
    );
  }
}

/// Fires a one-time fade + slight upward-slide entrance the first time this
/// subtree is built — used for newly-appended chat messages.
class _EntranceFade extends StatefulWidget {
  final Widget child;
  const _EntranceFade({required this.child});

  @override
  State<_EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<_EntranceFade> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: FkDurations.normal,
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _ctrl, curve: FkCurves.gentle);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
        child: widget.child,
      ),
    );
  }
}

/// Minimal markdown rendering for assistant replies: `**bold**` spans and
/// `- ` / `* ` bullet lines. Deliberately not a full markdown parser — this
/// repo doesn't depend on the `flutter_markdown` package, and the assistant
/// only ever emits simple formatting.
class _MarkdownLiteText extends StatelessWidget {
  final String text;
  const _MarkdownLiteText(this.text);

  @override
  Widget build(BuildContext context) {
    final style = FkTextStyles.adultBody.copyWith(color: FkColors.ink);
    final lines = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in lines) _buildLine(line, style),
      ],
    );
  }

  Widget _buildLine(String line, TextStyle style) {
    final isBullet = line.trimLeft().startsWith('- ') || line.trimLeft().startsWith('* ');
    final content = isBullet ? line.trimLeft().substring(2) : line;
    final spans = _boldSpans(content, style);

    if (line.trim().isEmpty) return const SizedBox(height: 6);

    if (isBullet) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('•  ', style: style),
            Expanded(child: RichText(text: TextSpan(children: spans, style: style))),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(text: TextSpan(children: spans, style: style)),
    );
  }

  List<TextSpan> _boldSpans(String line, TextStyle style) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    var last = 0;
    for (final match in pattern.allMatches(line)) {
      if (match.start > last) {
        spans.add(TextSpan(text: line.substring(last, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ));
      last = match.end;
    }
    if (last < line.length) spans.add(TextSpan(text: line.substring(last)));
    return spans;
  }
}

// ── Typing indicator ─────────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: FkColors.surface,
        borderRadius: FkRadii.mdAll,
        boxShadow: FkElevation.low(FkColors.lavender),
      ),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Stagger each dot by a third of the cycle for a bounce wave.
            final t = (_ctrl.value - i * 0.2) % 1.0;
            final bounce = t < 0.5 ? t * 2 : (1 - t) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.translate(
                offset: Offset(0, -4 * bounce.clamp(0, 1)),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(color: FkColors.lavender, shape: BoxShape.circle),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.loading, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FkColors.surface,
      padding: EdgeInsets.fromLTRB(
        FkSpacing.sm,
        FkSpacing.xs,
        FkSpacing.sm,
        FkSpacing.xs + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !loading,
              maxLength: 4000,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
              decoration: const InputDecoration(
                hintText: 'Ask about your child\'s practice…',
                hintStyle: FkTextStyles.adultCaption,
                filled: true,
                fillColor: FkColors.background,
                border: OutlineInputBorder(
                  borderRadius: FkRadii.mdAll,
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: FkSpacing.sm, vertical: 12),
              ),
              style: FkTextStyles.adultBody,
              onSubmitted: loading ? null : (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: loading ? null : onSend,
            child: AnimatedContainer(
              duration: FkDurations.fast,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: loading ? FkColors.disabled : FkColors.lavender,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                size: 20,
                color: loading ? FkColors.disabledInk : FkColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
