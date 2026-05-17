import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide settings (locale + app-lock).
///
/// Persisted to SharedPreferences so the choice survives restarts.
/// `GetMaterialApp` reads `locale` directly from here (see
/// `main.dart`).
///
/// Theme: app is locked to the light palette in `main.dart`. The
/// `themeMode` observable is preserved for historical SharedPreferences
/// reads but is no longer used by the app shell.
class AppSettingsController extends GetxController {
  // ── Storage keys ───────────────────────────────────
  static const _kLocale     = 'app.locale';
  static const _kAppLock    = 'app.lockEnabled';
  static const _kPinHash    = 'app.pinHash';

  static AppSettingsController get find =>
      Get.isRegistered<AppSettingsController>()
          ? Get.find<AppSettingsController>()
          : Get.put(AppSettingsController(), permanent: true);

  // ── Observable state ───────────────────────────────
  // Kept around to avoid breaking any caller that still reads it; the
  // app shell ignores this value (see main.dart).
  final themeMode  = ThemeMode.light.obs;
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
    locale.value    = Locale(p.getString(_kLocale) ?? 'en');
    appLock.value   = p.getBool(_kAppLock) ?? false;
    hasPin.value    = (p.getString(_kPinHash) ?? '').isNotEmpty;
    // themeMode intentionally not loaded — light-only.
  }

  // ── Locale ──────────────────────────────────────────────
  Future<void> setLocale(String code) async {
    locale.value = Locale(code);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLocale, code);
    Get.updateLocale(Locale(code));
  }

  // ── App lock ────────────────────────────────────────────
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
