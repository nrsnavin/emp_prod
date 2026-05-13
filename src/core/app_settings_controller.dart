import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide settings (theme, locale, app-lock).
///
/// Persisted to SharedPreferences so the choice survives restarts.
/// `GetMaterialApp` reads `themeMode` and `locale` directly from
/// here (see `main.dart`).
class AppSettingsController extends GetxController {
  // ── Storage keys ───────────────────────────────────────────
  static const _kThemeMode  = 'app.themeMode';      // 'light' | 'dark' | 'system'
  static const _kLocale     = 'app.locale';         // 'en' | 'ta' | 'hi'
  static const _kAppLock    = 'app.lockEnabled';    // bool
  static const _kPinHash    = 'app.pinHash';        // 4-digit PIN, plain (workers'
                                                    //   device, single-user). For
                                                    //   stronger guarantees move
                                                    //   to flutter_secure_storage.

  static AppSettingsController get find =>
      Get.isRegistered<AppSettingsController>()
          ? Get.find<AppSettingsController>()
          : Get.put(AppSettingsController(), permanent: true);

  // ── Observable state ───────────────────────────────────────
  final themeMode  = ThemeMode.system.obs;
  final locale     = const Locale('en').obs;
  final appLock    = false.obs;
  final hasPin     = false.obs;

  // Volatile flag — set true by AppLockGate once the user has unlocked
  // this session; reset to false on app pause.
  final unlocked   = false.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    themeMode.value = _parseTheme(p.getString(_kThemeMode));
    locale.value    = Locale(p.getString(_kLocale) ?? 'en');
    appLock.value   = p.getBool(_kAppLock) ?? false;
    hasPin.value    = (p.getString(_kPinHash) ?? '').isNotEmpty;
  }

  // ── Theme ──────────────────────────────────────────────────
  Future<void> setThemeMode(ThemeMode m) async {
    themeMode.value = m;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kThemeMode, m.name);
    Get.changeThemeMode(m);
  }

  ThemeMode _parseTheme(String? s) {
    switch (s) {
      case 'light': return ThemeMode.light;
      case 'dark':  return ThemeMode.dark;
      default:      return ThemeMode.system;
    }
  }

  // ── Locale ─────────────────────────────────────────────────
  Future<void> setLocale(String code) async {
    locale.value = Locale(code);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLocale, code);
    Get.updateLocale(Locale(code));
  }

  // ── App lock ───────────────────────────────────────────────
  Future<void> setAppLock(bool on) async {
    appLock.value = on;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kAppLock, on);
    if (!on) {
      await p.remove(_kPinHash);
      hasPin.value = false;
    }
  }

  Future<void> setPin(String pin) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPinHash, pin);
    hasPin.value = true;
  }

  Future<bool> verifyPin(String pin) async {
    final p = await SharedPreferences.getInstance();
    final stored = p.getString(_kPinHash) ?? '';
    return stored.isNotEmpty && stored == pin;
  }

  void markUnlocked() => unlocked.value = true;
  void markLocked()   => unlocked.value = false;
}
