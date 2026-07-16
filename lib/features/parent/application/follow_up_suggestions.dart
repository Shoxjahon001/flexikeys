library follow_up_suggestions;

/// Static, topic-keyed follow-up prompts shown as chips after an assistant
/// reply. This is a heuristic suggestion layer — keyword-matched against the
/// user's own prompt, not model-generated — so tapping one just sends
/// another real question through the same grounded `/ai-assistant/chat`
/// pipeline; nothing here is fabricated content.
List<String> followUpSuggestions(String lastUserPrompt) {
  final p = lastUserPrompt.toLowerCase();

  if (p.contains('week') || p.contains('summary')) {
    return const ['Compare to last week', 'Any concerns?', 'What should we practice next?'];
  }
  if (p.contains('practice') || p.contains('activit') || p.contains('goal')) {
    return const ['Why these activities?', 'How long should we practice?'];
  }
  if (p.contains('letter') || p.contains('hard') || p.contains('weak') || p.contains('strength')) {
    return const ['How can I help at home?', 'Is this normal for this age?'];
  }
  if (p.contains('adapt') || p.contains('keyboard')) {
    return const ['Why did this change?', 'What else has adapted?'];
  }
  if (p.contains('motivat')) {
    return const ['How can I encourage without pressure?', 'Suggest a break schedule'];
  }
  return const ['What should we practice today?', 'How is my child doing overall?'];
}
