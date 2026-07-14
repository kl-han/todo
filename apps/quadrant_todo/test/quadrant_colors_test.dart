import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrant_todo/presentation/quadrant_colors.dart';

void main() {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);

  test('each quadrant gets a distinct, stable accent color', () {
    final colors = [for (var q = 1; q <= 4; q++) quadrantColor(q, scheme)];
    expect(colors.toSet(), hasLength(4), reason: 'all four quadrants differ');
    expect(quadrantColor(1, scheme), quadrantColor(1, scheme),
        reason: 'stable for the same quadrant');
  });
}
