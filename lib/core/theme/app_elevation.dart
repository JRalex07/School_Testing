import 'package:flutter/material.dart';

/// Elevation and shadow definitions for UI depth without performance penalty.
class AppElevation {
  AppElevation._();

  static const List<BoxShadow> none = [];

  static const List<BoxShadow> low = [
    BoxShadow(
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
      color: Color(0x14000000), // 8% opacity black
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
      color: Color(0x1A000000), // 10% opacity black
    ),
  ];

  static const List<BoxShadow> modal = [
    BoxShadow(
      offset: Offset(0, 10),
      blurRadius: 24,
      spreadRadius: 0,
      color: Color(0x26000000), // 15% opacity black
    ),
  ];
}
