/// The kind of inline entry the caret is currently inside.
enum InlineEntryKind {
  /// The caret is in ordinary title text; neither `#` nor `!` is active.
  none,

  /// The caret is inside a `#` tag entry.
  tag,

  /// The caret is inside a `!` metadata (flag) entry.
  flag,
}

/// Which flag a [FlagCompletion] sets.
enum MetadataFlag { importance, urgency }

/// The four completions offered after `!`. Confirming one sets the
/// corresponding flag (`important`/`urgent` set it, the `not-` forms clear
/// it). The [token] is exactly what the user types after `!`.
enum FlagCompletion {
  important('important', MetadataFlag.importance, true),
  notImportant('not-important', MetadataFlag.importance, false),
  urgent('urgent', MetadataFlag.urgency, true),
  notUrgent('not-urgent', MetadataFlag.urgency, false);

  const FlagCompletion(this.token, this.flag, this.value);

  /// The literal text after `!` (e.g. `not-important`).
  final String token;

  /// The flag this completion changes.
  final MetadataFlag flag;

  /// The value the flag is set to when this completion is confirmed.
  final bool value;
}

/// An active inline entry: the `#`/`!` run the caret is currently within.
///
/// [start] is the index of the sigil (`#` or `!`); [end] is the caret
/// offset. [query] is the text between them — what has been typed so far,
/// used to filter suggestions.
class InlineEntry {
  const InlineEntry({
    required this.kind,
    required this.query,
    required this.start,
    required this.end,
  });

  final InlineEntryKind kind;
  final String query;
  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is InlineEntry &&
      other.kind == kind &&
      other.query == query &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(kind, query, start, end);

  @override
  String toString() =>
      'InlineEntry($kind, query: "$query", start: $start, end: $end)';
}

bool _isSeparator(int codeUnit) =>
    codeUnit == 0x20 || // space
    codeUnit == 0x09 || // tab
    codeUnit == 0x0a || // newline
    codeUnit == 0x0d; // carriage return

/// The inline entry the caret is currently inside, or `null` when the caret
/// is in ordinary text.
///
/// [caret] is a UTF-16 offset into [text] and defaults to the end of the
/// string; it is clamped to `0..text.length`. The active entry is the
/// whitespace-delimited word ending at the caret when that word begins with
/// `#` or `!`. Because a space terminates the word, a tag name can never
/// contain a space, and `!` immediately followed by a space is ordinary
/// text (there is no active entry), exactly as specified.
InlineEntry? inlineEntryAt(String text, [int? caret]) {
  var end = caret ?? text.length;
  if (end < 0) end = 0;
  if (end > text.length) end = text.length;

  var start = end;
  while (start > 0 && !_isSeparator(text.codeUnitAt(start - 1))) {
    start--;
  }
  if (start >= end) return null;

  final sigil = text.codeUnitAt(start);
  final InlineEntryKind kind;
  if (sigil == 0x23) {
    kind = InlineEntryKind.tag; // '#'
  } else if (sigil == 0x21) {
    kind = InlineEntryKind.flag; // '!'
  } else {
    return null;
  }

  return InlineEntry(
    kind: kind,
    query: text.substring(start + 1, end),
    start: start,
    end: end,
  );
}

/// Existing-tag suggestions for a `#` entry: [existingTags] whose name
/// starts with [query] (case-insensitive), keeping the input order and
/// dropping duplicates. An empty [query] returns every tag.
List<String> tagSuggestions(String query, Iterable<String> existingTags) {
  final prefix = query.toLowerCase();
  final seen = <String>{};
  final matches = <String>[];
  for (final tag in existingTags) {
    if (!tag.toLowerCase().startsWith(prefix)) continue;
    if (seen.add(tag)) matches.add(tag);
  }
  return matches;
}

/// Whether confirming [query] with a space would create a new tag rather
/// than assign an existing one — i.e. no existing tag matches it exactly
/// (case-insensitively). A blank query never creates a tag.
bool createsNewTag(String query, Iterable<String> existingTags) {
  if (query.trim().isEmpty) return false;
  final target = query.toLowerCase();
  for (final tag in existingTags) {
    if (tag.toLowerCase() == target) return false;
  }
  return true;
}

/// The `!` flag completions whose token starts with [query]
/// (case-insensitive), in enum order. An empty [query] returns all four.
List<FlagCompletion> flagSuggestions(String query) {
  final prefix = query.toLowerCase();
  return [
    for (final completion in FlagCompletion.values)
      if (completion.token.startsWith(prefix)) completion,
  ];
}

/// Whether [name] is inline-addressable via `#`: non-empty and free of
/// whitespace, so it can be typed after `#` and terminated by a space.
///
/// v2.1 forbids spaces in tag names for this reason; migrating pre-2.1
/// names that contain spaces is tracked in `docs/src/todo.rst`.
bool tagNameIsInlineAddressable(String name) {
  if (name.isEmpty) return false;
  for (var i = 0; i < name.length; i++) {
    if (_isSeparator(name.codeUnitAt(i))) return false;
  }
  return true;
}
