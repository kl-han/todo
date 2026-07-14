import 'package:quadrant_domain/quadrant_domain.dart';

import 'task_facts.dart';

/// A boolean flag term in a filter rule.
enum TaskFlag { important, urgent }

// Precedence, tightest binding highest. Mirrors the documented table
// (parentheses > comparisons > not > and > or); parentheses and comparisons
// are both primaries at the top level.
const int _orPrecedence = 1;
const int _andPrecedence = 2;
const int _notPrecedence = 3;
const int _primaryPrecedence = 4;

/// A parsed filter-rule expression. Immutable; evaluate against
/// [TaskFacts], or serialize back to canonical source with [toSource].
///
/// Sealed so adapters (the store's SQL translation) can switch over the
/// node types exhaustively without a fallback case.
sealed class FilterExpr {
  const FilterExpr();

  /// True when this expression matches [facts]. Reference semantics for the
  /// backend/SQLite translation.
  bool evaluate(TaskFacts facts);

  /// Binding strength, used only to parenthesize [toSource] minimally.
  int get precedence;

  /// Canonical source; `FilterRule.parse(e.toSource()).toSource()` is the
  /// identity.
  String toSource();

  /// Renders [child] as an operand of this expression, adding parentheses
  /// only when the child binds more loosely.
  String renderChild(FilterExpr child) => child.precedence < precedence
      ? '(${child.toSource()})'
      : child.toSource();
}

/// `important` / `urgent` — true when the task carries the flag.
class FlagTerm extends FilterExpr {
  const FlagTerm(this.flag);

  final TaskFlag flag;

  @override
  int get precedence => _primaryPrecedence;

  @override
  bool evaluate(TaskFacts facts) =>
      flag == TaskFlag.important ? facts.isImportant : facts.isUrgent;

  @override
  String toSource() => flag == TaskFlag.important ? 'important' : 'urgent';
}

/// `tag = <name>` — true when the task carries the named tag.
class TagEquals extends FilterExpr {
  const TagEquals(this.tagName);

  final String tagName;

  @override
  int get precedence => _primaryPrecedence;

  @override
  bool evaluate(TaskFacts facts) => facts.hasTag(tagName);

  @override
  String toSource() => 'tag = $tagName';
}

/// `not <expr>`.
class NotExpr extends FilterExpr {
  const NotExpr(this.operand);

  final FilterExpr operand;

  @override
  int get precedence => _notPrecedence;

  @override
  bool evaluate(TaskFacts facts) => !operand.evaluate(facts);

  @override
  String toSource() => 'not ${renderChild(operand)}';
}

/// `<left> and <right>`.
class AndExpr extends FilterExpr {
  const AndExpr(this.left, this.right);

  final FilterExpr left;
  final FilterExpr right;

  @override
  int get precedence => _andPrecedence;

  @override
  bool evaluate(TaskFacts facts) =>
      left.evaluate(facts) && right.evaluate(facts);

  @override
  String toSource() => '${renderChild(left)} and ${renderChild(right)}';
}

/// `<left> or <right>`.
class OrExpr extends FilterExpr {
  const OrExpr(this.left, this.right);

  final FilterExpr left;
  final FilterExpr right;

  @override
  int get precedence => _orPrecedence;

  @override
  bool evaluate(TaskFacts facts) =>
      left.evaluate(facts) || right.evaluate(facts);

  @override
  String toSource() => '${renderChild(left)} or ${renderChild(right)}';
}

/// A validated, named filter rule. Parsing enforces the grammar and
/// precedence; an invalid rule can be neither saved nor applied, so callers
/// validate before persisting (see [validate]).
class FilterRule {
  const FilterRule._(this.expression);

  /// Parses [source], throwing [DomainValidationError] when it is not a
  /// well-formed rule. The REST layer maps that to a 400 problem.
  factory FilterRule.parse(String source) =>
      FilterRule._(_Parser(_tokenize(source)).parse());

  final FilterExpr expression;

  /// Validates [source] for live editing: returns `null` when valid, or the
  /// human-readable error message otherwise.
  static String? validate(String source) {
    try {
      FilterRule.parse(source);
      return null;
    } on DomainValidationError catch (error) {
      return error.message;
    }
  }

  /// Whether [source] is a well-formed rule.
  static bool isValid(String source) => validate(source) == null;

  /// True when this rule matches [facts].
  bool matches(TaskFacts facts) => expression.evaluate(facts);

  /// Canonical source of the parsed rule.
  String toSource() => expression.toSource();
}

enum _TokenKind { word, lparen, rparen, eq }

class _Token {
  const _Token(this.kind, this.value);

  final _TokenKind kind;
  final String value;
}

bool _isSpace(int codeUnit) =>
    codeUnit == 0x20 ||
    codeUnit == 0x09 ||
    codeUnit == 0x0a ||
    codeUnit == 0x0d;

List<_Token> _tokenize(String input) {
  final tokens = <_Token>[];
  final buffer = StringBuffer();

  void flush() {
    if (buffer.isNotEmpty) {
      tokens.add(_Token(_TokenKind.word, buffer.toString()));
      buffer.clear();
    }
  }

  for (var i = 0; i < input.length; i++) {
    final ch = input[i];
    if (_isSpace(input.codeUnitAt(i))) {
      flush();
    } else if (ch == '(') {
      flush();
      tokens.add(const _Token(_TokenKind.lparen, '('));
    } else if (ch == ')') {
      flush();
      tokens.add(const _Token(_TokenKind.rparen, ')'));
    } else if (ch == '=') {
      flush();
      tokens.add(const _Token(_TokenKind.eq, '='));
    } else {
      buffer.write(ch);
    }
  }
  flush();
  return tokens;
}

/// Recursive-descent parser: or → and → not → primary, with parentheses and
/// comparisons as primaries (the documented precedence).
class _Parser {
  _Parser(this._tokens);

  final List<_Token> _tokens;
  int _pos = 0;

  _Token? get _peek => _pos < _tokens.length ? _tokens[_pos] : null;

  bool get _atEnd => _pos >= _tokens.length;

  void _advance() => _pos++;

  bool _peekKeyword(String keyword) {
    final token = _peek;
    return token != null &&
        token.kind == _TokenKind.word &&
        token.value.toLowerCase() == keyword;
  }

  FilterExpr parse() {
    if (_tokens.isEmpty) {
      throw DomainValidationError('A filter rule must not be empty.');
    }
    final expr = _parseOr();
    if (!_atEnd) {
      throw DomainValidationError(
        'Unexpected "${_peek!.value}" after the expression.',
      );
    }
    return expr;
  }

  FilterExpr _parseOr() {
    var left = _parseAnd();
    while (_peekKeyword('or')) {
      _advance();
      left = OrExpr(left, _parseAnd());
    }
    return left;
  }

  FilterExpr _parseAnd() {
    var left = _parseNot();
    while (_peekKeyword('and')) {
      _advance();
      left = AndExpr(left, _parseNot());
    }
    return left;
  }

  FilterExpr _parseNot() {
    if (_peekKeyword('not')) {
      _advance();
      return NotExpr(_parseNot());
    }
    return _parsePrimary();
  }

  FilterExpr _parsePrimary() {
    final token = _peek;
    if (token == null) {
      throw DomainValidationError('Expected a term but the rule ended.');
    }
    if (token.kind == _TokenKind.lparen) {
      _advance();
      final expr = _parseOr();
      final close = _peek;
      if (close == null || close.kind != _TokenKind.rparen) {
        throw DomainValidationError('Expected ")" to close a group.');
      }
      _advance();
      return expr;
    }
    if (token.kind != _TokenKind.word) {
      throw DomainValidationError('Expected a term but found "${token.value}".');
    }
    switch (token.value.toLowerCase()) {
      case 'tag':
        _advance();
        _expectEquals();
        final value = _peek;
        if (value == null || value.kind != _TokenKind.word) {
          throw DomainValidationError('Expected a tag name after "tag =".');
        }
        _advance();
        return TagEquals(value.value);
      case 'important':
        _advance();
        return const FlagTerm(TaskFlag.important);
      case 'urgent':
        _advance();
        return const FlagTerm(TaskFlag.urgent);
      case 'and':
      case 'or':
        throw DomainValidationError(
          '"${token.value}" needs an expression on its left.',
        );
      default:
        throw DomainValidationError('Unknown term "${token.value}".');
    }
  }

  void _expectEquals() {
    final token = _peek;
    if (token == null || token.kind != _TokenKind.eq) {
      throw DomainValidationError('Expected "=" after "tag".');
    }
    _advance();
  }
}
