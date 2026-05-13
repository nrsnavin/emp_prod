import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

import '../theme/erp_theme.dart';
import 'app_settings_controller.dart';

/// Wraps the app body and gates it behind biometric + PIN when
/// `AppSettingsController.appLock` is on. On launch it prompts
/// biometrics first; if the device has none (or the user cancels),
/// it falls back to the saved 4-digit PIN.
///
/// Stateless across hot-restart — the unlocked flag lives in the
/// controller, reset to false whenever this widget mounts.
class AppLockGate extends StatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  bool _tryingBiometric = false;
  final _pinCtrl = TextEditingController();
  String? _pinError;

  AppSettingsController get _s => AppSettingsController.find;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _s.markLocked();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attemptUnlock());
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

  Future<void> _attemptUnlock() async {
    if (!_s.appLock.value || _s.unlocked.value) return;
    setState(() => _tryingBiometric = true);
    try {
      final supported = await _auth.canCheckBiometrics;
      if (supported) {
        final ok = await _auth.authenticate(
          localizedReason: 'Unlock Worker Portal',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );
        if (ok) {
          _s.markUnlocked();
        }
      }
    } catch (_) {
      // Fall through to PIN.
    } finally {
      if (mounted) setState(() => _tryingBiometric = false);
    }
  }

  Future<void> _submitPin() async {
    final ok = await _s.verifyPin(_pinCtrl.text);
    if (ok) {
      _s.markUnlocked();
      _pinCtrl.clear();
    } else {
      setState(() => _pinError = 'Incorrect PIN');
    }
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
                    onPressed: _tryingBiometric ? null : _attemptUnlock,
                    icon: const Icon(Icons.fingerprint_rounded,
                        color: ErpColors.accentLight),
                    label: Text(
                      _tryingBiometric
                          ? 'Authenticating…'
                          : 'Use biometrics',
                      style: const TextStyle(
                          color: ErpColors.accentLight,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
