import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl_standalone.dart'
if (dart.library.html) 'package:intl/intl_browser.dart';

import '../src/core/app_lock_gate.dart';
import '../src/core/app_settings_controller.dart';
import '../src/core/app_translations.dart';
import '../src/features/auth/controllers/login_controller.dart';
import '../src/features/auth/screens/auth_gate.dart';
import 'theme/erp_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting();
  await findSystemLocale();
  runApp(const EmployeeApp());
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

      home: const AppLockGate(child: AuthGate()),
    );
  }
}
