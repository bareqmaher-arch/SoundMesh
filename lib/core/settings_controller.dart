import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'i18n/app_text.dart';

class AppSettings {
  final ThemeMode themeMode;
  final String localeCode; // 'en' | 'ar'

  const AppSettings({this.themeMode = ThemeMode.dark, this.localeCode = 'en'});

  AppSettings copyWith({ThemeMode? themeMode, String? localeCode}) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        localeCode: localeCode ?? this.localeCode,
      );
}

class SettingsController extends StateNotifier<AppSettings> {
  final Box box;
  static const _kTheme = 'theme_mode';
  static const _kLocale = 'locale_code';

  SettingsController(this.box) : super(_load(box));

  static AppSettings _load(Box box) {
    final themeStr = box.get(_kTheme, defaultValue: 'dark') as String;
    final locale = box.get(_kLocale, defaultValue: 'en') as String;
    return AppSettings(
      themeMode: _parseTheme(themeStr),
      localeCode: locale,
    );
  }

  static ThemeMode _parseTheme(String s) => switch (s) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };

  void setTheme(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    box.put(_kTheme, mode.name);
  }

  void setLocale(String code) {
    state = state.copyWith(localeCode: code);
    box.put(_kLocale, code);
  }

  void toggleTheme() {
    setTheme(state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark);
  }
}

/// يُهيّأ في main عبر override.
final settingsBoxProvider = Provider<Box>((ref) {
  throw UnimplementedError('init in main');
});

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
  return SettingsController(ref.watch(settingsBoxProvider));
});

/// نصوص التطبيق حسب اللغة الحالية.
final appTextProvider = Provider<AppText>((ref) {
  final code = ref.watch(settingsControllerProvider).localeCode;
  return AppText.of(code);
});
