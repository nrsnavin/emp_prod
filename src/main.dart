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
  // Wrap the whole app in a zoned guard so async errors that escape
  // try/catch (e.g. fire-and-forget controller initialisations) get
  // routed to the global error handler instead of killing the
  // isolate.
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

      // ── i18n ────────────────────────────────────────────────
      translations: AppTranslations(),
      fallbackLocale: const Locale('en'),

      // ── Initial bindings ────────────────────────────────────
      // Settings is permanent so it can drive theme/locale/lock
      // from anywhere. Login controller is permanent too so the
      // AuthGate Obx binding sees its observables on first frame.
      initialBinding: BindingsBuilder(() {
        Get.put(AppSettingsController(), permanent: true);
        Get.put(LoginController(),       permanent: true);
      }),

      // ── Theme ───────────────────────────────────────────────
      theme:     ErpTheme.light(),
      darkTheme: ErpTheme.dark(),
      themeMode: AppSettingsController.find.themeMode.value,
      locale:    AppSettingsController.find.locale.value,

      home: const ErrorBoundary(
        label: 'app',
        child: AppLockGate(child: AuthGate()),
      ),
    );
  }
}
