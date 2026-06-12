import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';

class SettingsProvider extends ChangeNotifier {
  static const _kAlias = 'alias';
  static const _kLanguage = 'language';
  static const _kIsDark = 'is_dark';
  static const _kCurrency = 'currency';

  SharedPreferences? _prefs;

  String _alias = '';
  String _language = 'es';
  bool _isDark = true;
  String _currency = 'MXN';

  String get alias => _alias;
  String get language => _language;
  bool get isDark => _isDark;
  String get currency => _currency;

  Strings get strings => _language == 'en' ? Strings.en : Strings.es;

  /// Inicial para el avatar; «?» si aún no hay alias.
  String get aliasInitial =>
      _alias.isEmpty ? '?' : _alias.characters.first.toUpperCase();

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _alias = _prefs!.getString(_kAlias) ?? '';
    _language = _prefs!.getString(_kLanguage) ?? 'es';
    _isDark = _prefs!.getBool(_kIsDark) ?? true;
    _currency = _prefs!.getString(_kCurrency) ?? 'MXN';
    AppColors.setDark(_isDark);
  }

  Future<void> setAlias(String value) async {
    _alias = value.trim().replaceAll('@', '');
    await _prefs?.setString(_kAlias, _alias);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    await _prefs?.setString(_kLanguage, value);
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    _isDark = value;
    AppColors.setDark(value);
    await _prefs?.setBool(_kIsDark, value);
    notifyListeners();
  }

  Future<void> setCurrency(String value) async {
    _currency = value;
    await _prefs?.setString(_kCurrency, value);
    notifyListeners();
  }
}
