import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl_standalone.dart'
if (dart.library.html) 'package:intl/intl_browser.dart';

import '../src/core/app_lock_gate.dart';
import '../src/core/app_settings_controller.dart';
import '../src/core/app_translations.dart';
import '../src/core/error_boundary.dart';
import '../src/features/auth/controllers/login_controller.dart';
import '../src/features/auth/screens/auth_gate.dart';
import 'theme/erp_theme.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    installGlobalErrorHandlers();
    try {
      initializeDateFormatting();
      await findSystemLocale();
    } catch (_) {
      // Locale init is best-effort; default to en-US if it fails.
    }
    runApp(const EmployeeApp());
  }, (error, stack) {
    // Hooked into the same logger / snackbar as the framework error
    // handler. Returning silently keeps the app alive.
  });
}

class EmployeeApp extends StatelessWidget {
  const EmployeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'app.title'.tr,

      // ── i18n ─────────────────────────────────────────────
      translations: AppTranslations(),
      fallbackLocale: const Locale('en'),

      initialBinding: BindingsBuilder(() {
        Get.put(AppSettingsController(), permanent: true);
        Get.put(LoginController(),       permanent: true);
      }),

      // ── Theme ─────────────────────────────────────────────
      //
      // Locked to the navy/light palette. We don't ship a real dark
      // theme (the half-finished ErpTheme.dark() inverted bgSurface
      // but left every hard-coded ErpColors.textPrimary as navy, so
      // half the app went black-on-black), and we don't follow the
      // OS setting either — a system flip would invert the same way.
      //
      // To revisit: replace ErpColors with a Material 3 ColorScheme
      // and migrate every widget that hard-codes a colour to read
      // from Theme.of(context). Until then, light-only.
      theme:     ErpTheme.light(),
      themeMode: ThemeMode.light,
      locale:    AppSettingsController.find.locale.value,

      home: const ErrorBoundary(
        label: 'app',
        child: AppLockGate(child: AuthGate()),
      ),
    );
  }
}
