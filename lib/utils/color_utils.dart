import 'package:flutter/material.dart';

/// Always save colors as 32-bit ARGB ints (0xAARRGGBB).
int encodeColor(Color c) => c.value;

/// Decode Firestore number to a Flutter Color (handles int or double).
Color decodeColor(dynamic firestoreValue, {Color fallback = const Color(0xFF2196F3)}) {
  if (firestoreValue == null) return fallback;
  if (firestoreValue is int) return Color(firestoreValue);
  if (firestoreValue is double) return Color(firestoreValue.toInt());
  // If someone stored hex string, try to parse:
  if (firestoreValue is String) {
    final cleaned = firestoreValue.replaceFirst('0x', '').replaceAll('#', '');
    final parsed = int.tryParse(cleaned, radix: 16);
    if (parsed != null) {
      // If string was just RRGGBB, add full alpha.
      if (cleaned.length == 6) return Color(0xFF000000 | parsed);
      return Color(parsed);
    }
  }
  return fallback;
}
