import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import 'season_palette.dart';
import 'season_registry.dart';
import 'season_theme.dart';

/// Holds the active season. Auto mode follows the calendar; the user can pin
/// a specific season, which is persisted.
class SeasonProvider extends ChangeNotifier {
  SeasonProvider({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const _kOverride = 'season_override';
  final DateTime Function() _clock;

  SeasonId? _override; // null = automatic
  bool _loaded = false;

  /// Ambient theme effects (snow, embers...) on every screen. User setting.
  static const _kEffects = 'season_effects_enabled';
  bool _effectsEnabled = true;
  bool get effectsEnabled => _effectsEnabled;

  Future<void> setEffectsEnabled(bool value) async {
    _effectsEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kEffects, value);
    } catch (_) {}
  }

  bool get isLoaded => _loaded;
  bool get isAuto => _override == null;
  SeasonId? get override => _override;

  SeasonTheme get current {
    final t = SeasonRegistry.byId(
      _override ?? SeasonRegistry.forDate(_clock()),
    );
    SeasonPalette.current = t;
    return t;
  }

  /// Dark / Light / System. Persisted; System follows the OS setting and
  /// keeps following it live while the app runs.
  static const _kThemeMode = 'app_theme_mode';
  static const _kFirstSeasonSet = 'season_first_launch_set';
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  /// Resolves [themeMode] against the OS brightness when set to `system`,
  /// and keeps [SeasonPalette.isDark] in sync as a side effect — the same
  /// pattern [current] uses for [SeasonPalette.current] — so static reads
  /// (no BuildContext) see the right brightness too.
  bool get isDark {
    final dark = switch (_themeMode) {
      ThemeMode.light => false,
      ThemeMode.dark => true,
      ThemeMode.system =>
        PlatformDispatcher.instance.platformBrightness == Brightness.dark,
    };
    SeasonPalette.isDark = dark;
    return dark;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_kOverride);
      _override = SeasonId.values.where((e) => e.name == name).firstOrNull;
      // First launch after install opens in Christmas; the user can switch
      // back to Auto or another season from settings afterwards.
      if (!(prefs.getBool(_kFirstSeasonSet) ?? false)) {
        await prefs.setBool(_kFirstSeasonSet, true);
        if (name == null) {
          _override = SeasonId.christmas;
          await prefs.setString(_kOverride, SeasonId.christmas.name);
        }
      }
      _effectsEnabled = prefs.getBool(_kEffects) ?? true;
      final modeName = prefs.getString(_kThemeMode);
      _themeMode =
          ThemeMode.values.where((e) => e.name == modeName).firstOrNull ??
          ThemeMode.dark;
    } catch (_) {
      _override = null;
    }
    // While in "system" mode, a live OS brightness change (user flips it
    // without closing the app) should repaint immediately.
    PlatformDispatcher.instance.onPlatformBrightnessChanged = () {
      if (_themeMode == ThemeMode.system) notifyListeners();
    };
    _loaded = true;
    notifyListeners();
  }

  /// Sets Dark, Light, or System (follows the OS and stays live).
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeMode, mode.name);
    } catch (_) {}
  }

  /// Pin a season, or pass null to go back to automatic.
  Future<void> setOverride(SeasonId? id) async {
    _override = id;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (id == null) {
        await prefs.remove(_kOverride);
      } else {
        await prefs.setString(_kOverride, id.name);
      }
    } catch (_) {}
  }
}
