import 'package:flutter/material.dart';

Color colorFromHex(String code) {
  var normalized = code.trim();
  if (normalized.startsWith('#')) {
    normalized = normalized.substring(1);
  }
  if (normalized.length == 6) {
    normalized = 'FF$normalized';
  }
  return Color(int.parse(normalized, radix: 16));
}
