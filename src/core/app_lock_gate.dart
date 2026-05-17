import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import '../theme/erp_theme.dart';
import 'app_settings_controller.dart';

/// Wraps the app body and gates it behind biometric + PIN when
/// `AppSettingsController.appLock` is on. On launch it probes the
/// device for available biometrics. If none are enrolled — or the
/// `local_auth` plugin throws because the Android MainActivity isn't
/// a `FlutterFragmentActivity` — the failure is surfaced in the lock
/// screen so the operator (or whoever's setting up the device) can
/// actually diagnose it, instead of silently falling through to PIN.
///
/// Setup notes (outside this repo, in the Flutter scaffolding):
///   - `pubspec.yaml` → `local_auth: ^2.x`
///   - `android/app/src/main/AndroidManifest.xml` →
///       `<uses-permission android:name="android.permission.USE_BIOMETRIC" />`
///   - `MainActivity.kt` MUST extend `FlutterFragmentActivity` (not
///     `FlutterActivity`), otherwise every authenticate() call throws
///     `no_fragment_activity`.
class AppLockGate extends StatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  final _pinCtrl = TextEditingController();

  bool _tryingBiometric = false;
  String? _pinError;

  // Diagnostics surfaced to the lock screen. Without these the
  // operator has no way to know whether biometric "didn't work"
  // because of missing OS enrollment, no hardware, or a native-side
  // wiring mistake (FlutterActivity vs FlutterFragmentActivity).
  bool _bioProbed = false;
  bool _bioSupported = false;
  List<BiometricType> _bioAvailable = const [];
  String? _bioError;

  AppSettingsController get _s => AppSettingsController.find;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _s.markLocked();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _probeBiometrics();
      _attemptUnlock();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _s.markLocked();
    }
  }

  // ── Probe biometric capability up front ──────────────────────
  // canCheckBiometrics returns true if the hardware exists AND at
  // least one credential is enrolled. getAvailableBiometrics() tells
  // us which modality (face / fingerprint / strong / weak) so the UI
  // can show the right icon and message.
  Future<void> _probeBiometrics() async {
    try {
      final supported = await _auth.canCheckBiometrics;
      final available = await _auth.getAvailableBiometrics();
      if (!mounted) return;
      setState(() {
        _bioProbed     = true;
        _bioSupported  = supported;
        _bioAvailable  = available;
        _bioError      = null;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _bioProbed = true;
        _bioSupported = false;
        _bioError = _humanizeError(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bioProbed = true;
        _bioSupported = false;
        _bioError = e.toString();
      });
    }
  }

  Future<void> _attemptUnlock() async {
    if (!_s.appLock.value || _s.unlocked.value) return;
    if (!mounted) return;
    if (!_bioSupported) return; // Surface the diagnostic; fall back to PIN.

    setState(() {
      _tryingBiometric = true;
      _bioError = null;
    });

    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock Worker Portal',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allow device PIN as system fallback
        ),
      );
      if (ok && mounted) _s.markUnlocked();
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _bioError = _humanizeError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _bioError = e.toString());
    } finally {
      if (mounted) setState(() => _tryingBiometric = false);
    }
  }

  // ── Map raw plugin errors to operator-friendly strings ─────────────────
  String _humanizeError(PlatformException e) {
    switch (e.code) {
      case auth_error.notAvailable:
        return 'Biometric hardware is not available on this device.';
      case auth_error.notEnrolled:
        return 'No fingerprint or face is enrolled. Add one in the phone\'s Security settings.';
      case auth_error.passcodeNotSet:
        return 'Set a device lock screen (PIN / pattern / password) before enabling biometrics.';
      case auth_error.lockedOut:
        return 'Too many failed attempts. Wait a few seconds and try again.';
      case auth_error.permanentlyLockedOut:
        return 'Biometrics permanently locked out. Unlock with your device passcode first.';
      case 'no_fragment_activity':
        return 'App misconfigured: MainActivity must extend FlutterFragmentActivity. Ask a developer to update the Android side.';
      default:
        return e.message ?? 'Biometric error (${e.code}).';
    }
  }

  Future<void> _submitPin() async {
    final ok = await _s.verifyPin(_pinCtrl.text);
    if (!mounted) return;
    if (ok) {
      _s.markUnlocked();
      _pinCtrl.clear();
    } else {
      setState(() => _pinError = 'Incorrect PIN');
    }
  }

  // ── Button state ───────────────────────────────────────────────
  bool get _bioEnabled => _bioProbed && _bioSupported && !_tryingBiometric;

  String get _bioButtonLabel {
    if (_tryingBiometric)      return 'Authenticating…';
    if (!_bioProbed)           return 'Checking biometric…';
    if (!_bioSupported)        return 'Biometric unavailable';
    if (_bioAvailable.contains(BiometricType.face)) return 'Use Face Unlock';
    if (_bioAvailable.contains(BiometricType.fingerprint) ||
        _bioAvailable.contains(BiometricType.strong)     ||
        _bioAvailable.contains(BiometricType.weak)) {
      return 'Use Fingerprint';
    }
    return 'Use Biometrics';
  }

  IconData get _bioIcon {
    if (_bioAvailable.contains(BiometricType.face)) return Icons.face_outlined;
    return Icons.fingerprint_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!_s.appLock.value || _s.unlocked.value) return widget.child;
      return Scaffold(
        backgroundColor: ErpColors.navyDark,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: ErpColors.accentBlue.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.lock_outline,
                        color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 16),
                  const Text('Worker Portal Locked',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    _s.hasPin.value
                        ? 'Use biometrics or enter your PIN.'
                        : 'Use biometrics to unlock.',
                    style: const TextStyle(
                        color: ErpColors.textOnDarkSub, fontSize: 12),
                  ),
                  const SizedBox(height: 26),
                  if (_s.hasPin.value)
                    TextField(
                      controller: _pinCtrl,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          letterSpacing: 12,
                          fontSize: 22,
                          fontWeight: FontWeight.w900),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••',
                        hintStyle: const TextStyle(
                            color: ErpColors.textOnDarkSub,
                            letterSpacing: 12),
                        filled: true,
                        fillColor: ErpColors.navyMid,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _pinError,
                      ),
                      onChanged: (v) {
                        if (_pinError != null) {
                          setState(() => _pinError = null);
                        }
                        if (v.length == 4) _submitPin();
                      },
                    ),
                  const SizedBox(height: 18),
                  TextButton.icon(
                    onPressed: _bioEnabled ? _attemptUnlock : null,
                    icon: Icon(_bioIcon,
                        color: _bioEnabled
                            ? ErpColors.accentLight
                            : ErpColors.textOnDarkSub),
                    label: Text(
                      _bioButtonLabel,
                      style: TextStyle(
                          color: _bioEnabled
                              ? ErpColors.accentLight
                              : ErpColors.textOnDarkSub,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (_bioError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: ErpColors.errorRed.withOpacity(0.16),
                        border: Border.all(
                            color: ErpColors.errorRed.withOpacity(0.45)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _bioError!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
