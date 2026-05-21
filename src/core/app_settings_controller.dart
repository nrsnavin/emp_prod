import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
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
///
/// PIN storage:
///   The app-lock PIN is hashed with SHA-256 using a per-install
///   random salt. The salt is stored alongside the hash so verify
///   can recompute, and a legacy migration path catches PINs that
///   were written under the older plaintext scheme (no salt key
///   present): a one-time plaintext match silently re-writes as a
///   salted hash and then accepts the unlock.
class AppSettingsController extends GetxController {
  // ── Storage keys ───────────────────────────────────
  static const _kLocale     = 'app.locale';
  static const _kAppLock    = 'app.lockEnabled';
  static const _kPinHash    = 'app.pinHash';
  static const _kPinSalt    = 'app.pinSalt';

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
      await p.remove(_kPinSalt);
      hasPin.value = false;
    }
  }

  Future<void> setPin(String pin) async {
    final p = await SharedPreferences.getInstance();
    final salt = _generateSalt();
    await p.setString(_kPinSalt, salt);
    await p.setString(_kPinHash, _hashPin(pin, salt));
    hasPin.value = true;
  }

  Future<bool> verifyPin(String pin) async {
    final p = await SharedPreferences.getInstance();
    final stored = p.getString(_kPinHash) ?? '';
    if (stored.isEmpty) return false;

    final salt = p.getString(_kPinSalt) ?? '';
    if (salt.isEmpty) {
      // Legacy plaintext PIN (pre-hash rollout). Accept once if it
      // matches, then silently upgrade to a salted hash so the next
      // unlock takes the new code path.
      if (stored == pin) {
        await setPin(pin);
        return true;
      }
      return false;
    }
    return stored == _hashPin(pin, salt);
  }

  void markUnlocked() => unlocked.value = true;
  void markLocked()   => unlocked.value = false;

  // ── PIN crypto helpers ──────────────────────────────────
  static String _generateSalt({int byteLength = 16}) {
    final rng = Random.secure();
    final bytes = List<int>.generate(byteLength, (_) => rng.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }
}
