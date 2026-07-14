import 'package:quadrant_input/quadrant_input.dart';
import 'package:test/test.dart';

void main() {
  group('inlineEntryAt — active token', () {
    test('ordinary text has no active entry', () {
      expect(inlineEntryAt(''), isNull);
      expect(inlineEntryAt('buy milk'), isNull);
      expect(inlineEntryAt('a#b'), isNull, reason: 'sigil not at word start');
    });

    test('# starts a tag entry, caret at end', () {
      final entry = inlineEntryAt('#gro');
      expect(entry, isNotNull);
      expect(entry!.kind, InlineEntryKind.tag);
      expect(entry.query, 'gro');
      expect(entry.start, 0);
      expect(entry.end, 4);
    });

    test('tag entry begins at its own word, not the title start', () {
      final entry = inlineEntryAt('buy milk #gro');
      expect(entry!.kind, InlineEntryKind.tag);
      expect(entry.query, 'gro');
      expect(entry.start, 9);
    });

    test('! starts a flag entry', () {
      final entry = inlineEntryAt('!imp');
      expect(entry!.kind, InlineEntryKind.flag);
      expect(entry.query, 'imp');
    });

    test('a bare ! offers every flag completion', () {
      final entry = inlineEntryAt('!');
      expect(entry!.kind, InlineEntryKind.flag);
      expect(entry.query, '');
      expect(flagSuggestions(entry.query), FlagCompletion.values);
    });

    test('! before a space is literal — no active entry', () {
      // Caret after the space: the word ending at the caret is empty.
      expect(inlineEntryAt('! '), isNull);
      expect(inlineEntryAt('do ! this'), isNull);
    });

    test('a space terminates tag entry', () {
      expect(inlineEntryAt('#tag done'), isNull);
      // Caret placed right after "#tag" still sees the tag entry.
      final entry = inlineEntryAt('#tag done', 4);
      expect(entry!.kind, InlineEntryKind.tag);
      expect(entry.query, 'tag');
    });

    test('caret inside the word truncates the query at the caret', () {
      final entry = inlineEntryAt('#abcd', 3);
      expect(entry!.query, 'ab');
      expect(entry.end, 3);
    });

    test('caret offset is clamped to the string bounds', () {
      expect(inlineEntryAt('#x', 99)!.query, 'x');
      expect(inlineEntryAt('#x', -5), isNull);
    });
  });

  group('tag suggestions', () {
    const tags = ['work', 'Workout', 'home', 'work-later'];

    test('empty query returns all tags in order', () {
      expect(tagSuggestions('', tags), tags);
    });

    test('prefix match narrows and is case-insensitive, order preserved', () {
      expect(tagSuggestions('work', tags), ['work', 'Workout', 'work-later']);
      expect(tagSuggestions('WO', tags), ['work', 'Workout', 'work-later']);
      expect(tagSuggestions('ho', tags), ['home']);
      expect(tagSuggestions('zzz', tags), isEmpty);
    });

    test('duplicates are dropped', () {
      expect(tagSuggestions('a', ['a', 'a', 'ab']), ['a', 'ab']);
    });
  });

  group('createsNewTag', () {
    const tags = ['work', 'home'];

    test('a query matching an existing tag never creates', () {
      expect(createsNewTag('work', tags), isFalse);
      expect(createsNewTag('WORK', tags), isFalse);
    });

    test('an unmatched, non-blank query creates', () {
      expect(createsNewTag('errands', tags), isTrue);
    });

    test('a blank query never creates', () {
      expect(createsNewTag('', tags), isFalse);
      expect(createsNewTag('   ', tags), isFalse);
    });
  });

  group('flag suggestions and mapping', () {
    test('empty query returns all four in order', () {
      expect(flagSuggestions(''), FlagCompletion.values);
    });

    test('prefix narrows the completions', () {
      expect(flagSuggestions('not'),
          [FlagCompletion.notImportant, FlagCompletion.notUrgent]);
      expect(flagSuggestions('u'), [FlagCompletion.urgent]);
      expect(flagSuggestions('important'), [FlagCompletion.important]);
      expect(flagSuggestions('nope'), isEmpty);
    });

    test('each completion maps to the flag change it names', () {
      expect(FlagCompletion.important.flag, MetadataFlag.importance);
      expect(FlagCompletion.important.value, isTrue);
      expect(FlagCompletion.notImportant.flag, MetadataFlag.importance);
      expect(FlagCompletion.notImportant.value, isFalse);
      expect(FlagCompletion.urgent.flag, MetadataFlag.urgency);
      expect(FlagCompletion.urgent.value, isTrue);
      expect(FlagCompletion.notUrgent.flag, MetadataFlag.urgency);
      expect(FlagCompletion.notUrgent.value, isFalse);
    });
  });

  group('tagNameIsInlineAddressable', () {
    test('non-empty, space-free names are addressable', () {
      expect(tagNameIsInlineAddressable('work'), isTrue);
      expect(tagNameIsInlineAddressable('work-later'), isTrue);
    });

    test('empty or whitespace-bearing names are not', () {
      expect(tagNameIsInlineAddressable(''), isFalse);
      expect(tagNameIsInlineAddressable('my project'), isFalse);
      expect(tagNameIsInlineAddressable('a\tb'), isFalse);
    });
  });
}
