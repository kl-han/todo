import 'package:flutter/material.dart';

/// Stable accent color per Eisenhower quadrant, blended with the theme
/// surface so it reads in both light and dark themes. The hue encodes the
/// quadrant's action: Q1 do (red), Q2 plan (blue), Q3 delegate (amber),
/// Q4 drop (grey). Quadrant membership itself is never stored — this is
/// presentation only (see docs/src/product/quadrant-behavior.rst).
Color quadrantColor(int quadrant, ColorScheme scheme) {
  final base = switch (quadrant) {
    1 => const Color(0xFFD32F2F),
    2 => const Color(0xFF1976D2),
    3 => const Color(0xFFF9A825),
    _ => const Color(0xFF757575),
  };
  return Color.alphaBlend(base.withValues(alpha: 0.16), scheme.surface);
}
