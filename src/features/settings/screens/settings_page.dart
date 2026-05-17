import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/app_settings_controller.dart';
import '../../../theme/erp_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppSettingsController.find;
    return Scaffold(
      backgroundColor: ErpColors.bgBase,
      appBar: AppBar(
        backgroundColor: ErpColors.navyDark,
        elevation: 0,
        title: Text('settings.title'.tr, style: ErpTextStyles.pageTitle),
      ),
      body: Obx(() => ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              // Theme picker removed — the app is locked to light mode
              // in main.dart. Half-baked dark mode was rendering text
              // black-on-black; revisit when we migrate to a proper
              // Material 3 ColorScheme.

              _SectionHeader('settings.language'.tr),
              _LangRadio(code: 'en', label: 'settings.language.en'.tr,
                  current: s.locale.value.languageCode,
                  onChanged: s.setLocale),
              _LangRadio(code: 'ta', label: 'settings.language.ta'.tr,
                  current: s.locale.value.languageCode,
                  onChanged: s.setLocale),
              _LangRadio(code: 'hi', label: 'settings.language.hi'.tr,
                  current: s.locale.value.languageCode,
                  onChanged: s.setLocale),
              const SizedBox(height: 16),

              _SectionHeader('settings.appLock'.tr),
              Container(
                decoration: ErpDecorations.card,
                child: Column(children: [
                  SwitchListTile.adaptive(
                    value: s.appLock.value,
                    onChanged: (on) async {
                      await s.setAppLock(on);
                      if (on && !s.hasPin.value) {
                        await _promptSetPin(context, s);
                      }
                    },
                    title: Text('settings.appLock'.tr,
                        style: ErpTextStyles.cardTitle),
                    subtitle: Text('settings.appLock.desc'.tr,
                        style: const TextStyle(
                            color: ErpColors.textMuted, fontSize: 11)),
                  ),
                  if (s.appLock.value)
                    ListTile(
                      title: Text(
                          s.hasPin.value
                              ? 'settings.changePin'.tr
                              : 'settings.setPin'.tr,
                          style: ErpTextStyles.cardTitle),
                      leading: const Icon(Icons.pin_outlined,
                          color: ErpColors.accentBlue),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _promptSetPin(context, s),
                    ),
                ]),
              ),
            ],
          )),
    );
  }

  Future<void> _promptSetPin(
      BuildContext ctx, AppSettingsController s) async {
    final ctrl = TextEditingController();
    String? error;
    await showDialog(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(builder: (_, setState) {
        return AlertDialog(
          title: Text('settings.setPin'.tr),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(letterSpacing: 12, fontSize: 22),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('common.cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () async {
                if (ctrl.text.length != 4) {
                  setState(() => error = '4 digits required');
                  return;
                }
                await s.setPin(ctrl.text);
                Get.snackbar(
                  'Saved', 'settings.pinSaved'.tr,
                  backgroundColor: ErpColors.successGreen,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
                if (Navigator.of(dialogCtx).canPop()) {
                  Navigator.of(dialogCtx).pop();
                }
              },
              child: Text('common.save'.tr),
            ),
          ],
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
        child: Text(label.toUpperCase(), style: ErpTextStyles.sectionHeader),
      );
}

class _LangRadio extends StatelessWidget {
  final String code, label, current;
  final void Function(String) onChanged;
  const _LangRadio({
    required this.code,
    required this.label,
    required this.current,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Container(
        decoration: ErpDecorations.card,
        margin: const EdgeInsets.only(bottom: 6),
        child: RadioListTile<String>(
          value: code,
          groupValue: current,
          onChanged: (v) => v != null ? onChanged(v) : null,
          title: Text(label, style: ErpTextStyles.cardTitle),
        ),
      );
}
