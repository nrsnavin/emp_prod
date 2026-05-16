import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/safe_json.dart';
import '../../../theme/erp_theme.dart';
import '../controllers/packing_entry_controller.dart';

// ═════════════════════════════════════════════════════════════
//  PACKING ENTRY FORM — POST /packing/create-packing
// ═════════════════════════════════════════════════════════════
class PackingEntryFormPage extends StatefulWidget {
  final Map<String, dynamic> job;
  final PackingEntryController controller;
  const PackingEntryFormPage({
    super.key,
    required this.job,
    required this.controller,
  });

  @override
  State<PackingEntryFormPage> createState() => _PackingEntryFormPageState();
}

class _PackingEntryFormPageState extends State<PackingEntryFormPage> {
  PackingEntryController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.loadEmployees();
  }

  @override
  Widget build(BuildContext context) {
    final jobId      = SafeJson.asString(widget.job['_id']);
    final jobOrderNo = SafeJson.asInt(widget.job['jobOrderNo']);
    final cust       = SafeJson.asMap(widget.job['customer']);
    final custName   = SafeJson.asStringOrNull(cust['name']) ??
        SafeJson.asStringOrNull(widget.job['customer']);

    return Scaffold(
      backgroundColor: ErpColors.bgBase,
      appBar: AppBar(
        backgroundColor: ErpColors.navyDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pack Job #$jobOrderNo', style: ErpTextStyles.pageTitle),
            const Text('Packing  ›  New entry',
                style: TextStyle(
                    color: ErpColors.textOnDarkSub, fontSize: 10)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Job header card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ErpColors.navyDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: ErpColors.successGreen.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    color: ErpColors.successGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Job #$jobOrderNo',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900)),
                      if (custName != null)
                        Text(custName,
                            style: const TextStyle(
                                color: ErpColors.textOnDarkSub,
                                fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                    ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          // Quantity
          TextFormField(
            controller: c.qtyCtrl,
            keyboardType: TextInputType.number,
            style: ErpTextStyles.fieldValue,
            decoration: ErpDecorations.formInput(
              'Quantity (pcs) *',
              hint: '0',
              prefix: const Icon(Icons.numbers_rounded,
                  size: 16, color: ErpColors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          // Weight
          TextFormField(
            controller: c.weightCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: ErpTextStyles.fieldValue,
            decoration: ErpDecorations.formInput(
              'Weight (kg) *',
              hint: '0.000',
              prefix: const Icon(Icons.scale_outlined,
                  size: 16, color: ErpColors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          // Teammate dropdown (optional)
          Obx(() {
            if (c.isEmpLoading.value) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: ErpColors.bgSurface,
                  border: Border.all(color: ErpColors.borderLight),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(children: [
                  SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        color: ErpColors.accentBlue, strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Loading teammates…',
                      style: TextStyle(
                          color: ErpColors.textSecondary, fontSize: 12)),
                ]),
              );
            }
            final items = <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('— None —',
                    style: TextStyle(color: ErpColors.textMuted)),
              ),
              ...c.employees.map((e) {
                final id   = SafeJson.asString(e['_id']);
                final name = SafeJson.asString(e['name'], '—');
                return DropdownMenuItem<String?>(
                  value: id,
                  child: Text(name, style: ErpTextStyles.fieldValue),
                );
              }),
            ];
            return DropdownButtonFormField<String?>(
              value: c.selectedEmployeeId.value,
              decoration: ErpDecorations.formInput(
                'Teammate (optional)',
                prefix: const Icon(Icons.group_outlined,
                    size: 16, color: ErpColors.textMuted),
              ),
              items: items,
              onChanged: (v) => c.selectedEmployeeId.value = v,
            );
          }),
          const SizedBox(height: 12),
          // Notes
          TextFormField(
            controller: c.notesCtrl,
            maxLines: 3,
            style: ErpTextStyles.fieldValue,
            decoration: ErpDecorations.formInput(
              'Notes (optional)',
              hint: 'Carton labels, dispatch lot etc.',
              prefix: const Icon(Icons.notes_rounded,
                  size: 16, color: ErpColors.textMuted),
            ),
          ),
          const SizedBox(height: 18),
          // Submit
          Obx(() => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ErpColors.successGreen,
                    disabledBackgroundColor:
                        ErpColors.successGreen.withOpacity(0.45),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: c.isSubmitting.value
                      ? null
                      : () async {
                          final ok = await c.submit(jobId: jobId);
                          if (ok && mounted) Get.back();
                        },
                  icon: c.isSubmitting.value
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Icon(Icons.check_circle_outline_rounded,
                          color: Colors.white, size: 20),
                  label: Text(
                    c.isSubmitting.value ? 'Saving…' : 'Save Packing Entry',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
