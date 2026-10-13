import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's light / dark / system preference.
class ThemeModeCubit extends Cubit<ThemeMode> {
  static const _key = 'theme_mode';
  final SharedPreferences prefs;

  ThemeModeCubit(this.prefs) : super(_read(prefs));

  static ThemeMode _read(SharedPreferences prefs) {
    final stored = prefs.getString(_key);
    return ThemeMode.values.firstWhere((m) => m.name == stored, orElse: () => ThemeMode.system);
  }

  void setMode(ThemeMode mode) {
    prefs.setString(_key, mode.name);
    emit(mode);
  }

  /// Flips between light and dark, resolving `system` against the current
  /// platform brightness so the first click always visibly changes the theme.
  void toggle(Brightness current) {
    setMode(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
