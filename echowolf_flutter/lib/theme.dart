// lib/theme.dart
import 'package:flutter/material.dart';

class EWColors {
  // Night
  static const nightBg      = Color(0xFF080b10);
  static const nightPanel   = Color(0xFF0d1117);
  static const nightCard    = Color(0xFF111820);
  static const nightBorder  = Color(0xFF1e2d3d);
  static const nightAccent  = Color(0xFF00d4ff);
  static const nightAccent2 = Color(0xFF0096b3);
  static const nightMuted   = Color(0xFF4a6274);
  static const nightDim     = Color(0xFF1a2535);
  static const nightText    = Color(0xFFe8f4f8);

  // Day
  static const dayBg      = Color(0xFFdde4ec);
  static const dayPanel   = Color(0xFFc8d4de);
  static const dayCard    = Color(0xFFffffff);
  static const dayBorder  = Color(0xFF8aa8c4);
  static const dayAccent  = Color(0xFF005bb5);
  static const dayAccent2 = Color(0xFF003d8f);
  static const dayMuted   = Color(0xFF3a5068);
  static const dayDim     = Color(0xFFb8c8d8);
  static const dayText    = Color(0xFF060c18);

  // Status colors (same for both themes)
  static const green  = Color(0xFF00e676);
  static const yellow = Color(0xFFffd600);
  static const red    = Color(0xFFff3d3d);
  static const orange = Color(0xFFff8c00);
  static const white  = Color(0xFFffffff);
}

class EWTheme {
  final bool dark;
  EWTheme(this.dark);

  Color get bg      => dark ? EWColors.nightBg      : EWColors.dayBg;
  Color get panel   => dark ? EWColors.nightPanel   : EWColors.dayPanel;
  Color get card    => dark ? EWColors.nightCard    : EWColors.dayCard;
  Color get border  => dark ? EWColors.nightBorder  : EWColors.dayBorder;
  Color get accent  => dark ? EWColors.nightAccent  : EWColors.dayAccent;
  Color get accent2 => dark ? EWColors.nightAccent2 : EWColors.dayAccent2;
  Color get muted   => dark ? EWColors.nightMuted   : EWColors.dayMuted;
  Color get dim     => dark ? EWColors.nightDim     : EWColors.dayDim;
  Color get text    => dark ? EWColors.nightText    : EWColors.dayText;

  Color get green  => EWColors.green;
  Color get yellow => EWColors.yellow;
  Color get red    => EWColors.red;
  Color get orange => EWColors.orange;

  // value-based color helpers
  Color loadColor(double v)   => v < 60 ? green : v < 85 ? yellow : red;
  Color iatColor(int v)       => v < 40 ? green : v < 55 ? yellow : red;
  Color timingColor(double v) => v.abs() < 10 ? accent : v.abs() < 20 ? yellow : red;
  Color battColor(double v)   => v >= 13.5 && v <= 14.8 ? green : v > 12.0 ? yellow : red;
  Color ftColor(double v)     => v.abs() < 5 ? green : v.abs() < 12 ? yellow : red;
  Color o2Color(double v)     => v > 0.45 ? red : v > 0.1 ? green : muted;

  ThemeData get materialTheme => ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: accent,
      onPrimary: dark ? EWColors.nightBg : EWColors.dayBg,
      secondary: accent2,
      onSecondary: dark ? EWColors.nightBg : EWColors.dayBg,
      error: red,
      onError: EWColors.white,
      surface: card,
      onSurface: text,
    ),
    fontFamily: 'monospace',
    tabBarTheme: TabBarTheme(
      labelColor: accent,
      unselectedLabelColor: muted,
      indicatorColor: accent,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: panel,
      foregroundColor: text,
      elevation: 0,
    ),
  );
}
