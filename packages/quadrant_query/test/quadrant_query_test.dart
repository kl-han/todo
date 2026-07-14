import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:quadrant_query/quadrant_query.dart';
import 'package:test/test.dart';

TaskFacts facts({
  bool important = false,
  bool urgent = false,
  Set<String> tags = const <String>{},
}) =>
    TaskFacts(isImportant: important, isUrgent: urgent, tagNames: tags);

bool matches(String rule, TaskFacts f) => FilterRule.parse(rule).matches(f);

void main() {
  group('codec — parse then serialize is canonical and stable', () {
    test('round-trips the documented shapes', () {
      for (final source in [
        'important',
        'urgent',
        'tag = someday',
        'not urgent',
        'important and urgent',
        'important or urgent',
        'important and not tag = someday or urgent',
        'not (important or urgent)',
        '(important or urgent) and tag = work',
        'tag = and',
      ]) {
        expect(FilterRule.parse(source).toSource(), source, reason: source);
      }
    });
  });

  group('precedence (tightest first: parens, comparison, not, and, or)', () {
    test('and binds tighter than or', () {
      // urgent or important and tag = x  ==  urgent or (important and tag = x)
      const rule = 'urgent or important and tag = x';
      // If it parsed as (urgent or important) and tag = x, this case would be
      // false; the documented grouping makes it true.
      expect(matches(rule, facts(urgent: true)), isTrue);
      expect(
        matches(rule, facts(important: true, tags: {'x'})),
        isTrue,
      );
      expect(matches(rule, facts(important: true)), isFalse);
    });

    test('not binds tighter than and', () {
      // not important and urgent  ==  (not important) and urgent
      const rule = 'not important and urgent';
      // important=true, urgent=false distinguishes it from
      // not (important and urgent), which would be true here.
      expect(matches(rule, facts(important: true)), isFalse);
      expect(matches(rule, facts(urgent: true)), isTrue);
    });

    test('parentheses override the default grouping', () {
      expect(
        matches('not (important and urgent)', facts(important: true)),
        isTrue,
      );
      expect(
        matches('not (important and urgent)',
            facts(important: true, urgent: true)),
        isFalse,
      );
    });

    test('the documented example groups as specified', () {
      // important and not tag = someday or urgent
      //   == (important and (not (tag = someday))) or urgent
      const rule = 'important and not tag = someday or urgent';
      expect(matches(rule, facts(urgent: true)), isTrue);
      expect(matches(rule, facts(important: true)), isTrue);
      expect(
        matches(rule, facts(important: true, tags: {'someday'})),
        isFalse,
      );
      expect(matches(rule, facts()), isFalse);
    });
  });

  group('evaluation of terms', () {
    test('flag terms read the matching flag', () {
      expect(matches('important', facts(important: true)), isTrue);
      expect(matches('important', facts(urgent: true)), isFalse);
      expect(matches('urgent', facts(urgent: true)), isTrue);
    });

    test('tag comparison is an exact, case-sensitive membership test', () {
      expect(matches('tag = work', facts(tags: {'work'})), isTrue);
      expect(matches('tag = work', facts(tags: {'home'})), isFalse);
      expect(matches('tag = Work', facts(tags: {'work'})), isFalse);
    });

    test('a keyword-like word is a valid tag value', () {
      expect(matches('tag = and', facts(tags: {'and'})), isTrue);
    });
  });

  group('validation', () {
    test('valid rules validate cleanly', () {
      for (final source in [
        'important',
        'tag = x and (urgent or not important)',
        'not not urgent',
      ]) {
        expect(FilterRule.validate(source), isNull, reason: source);
        expect(FilterRule.isValid(source), isTrue, reason: source);
      }
    });

    test('malformed rules cannot be parsed, validated, or applied', () {
      for (final source in [
        '', // empty
        '   ', // whitespace only
        'important and', // trailing operator
        'and important', // leading operator
        'tag', // comparison without "="
        'tag =', // comparison without a value
        '(important', // unbalanced parenthesis
        'important)', // stray close
        'important urgent', // two terms, no operator
        'important or or urgent', // doubled operator
        'someday', // unknown term
        ')', // not a term
      ]) {
        expect(() => FilterRule.parse(source),
            throwsA(isA<DomainValidationError>()),
            reason: source);
        expect(FilterRule.validate(source), isNotNull, reason: source);
        expect(FilterRule.isValid(source), isFalse, reason: source);
      }
    });
  });

  group('lexing tolerates spacing around punctuation', () {
    test('"=" and parentheses need no surrounding spaces', () {
      expect(matches('tag=work', facts(tags: {'work'})), isTrue);
      expect(
        matches('(urgent)and(important)',
            facts(urgent: true, important: true)),
        isTrue,
      );
    });
  });
}
