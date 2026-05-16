import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/safe_json.dart';
import '../../../theme/erp_theme.dart';
import '../controllers/packing_entry_controller.dart';

// ══════════════════════════════════════════════════════════════
//  PACKING ENTRY FORM — POST /packing/create-packing
//
//  Mirrors the admin app's Add Packing layout: Job header → elastic
//  picker → production data (meters, joints, stretch, size) → weights
//  (net / tare / gross) → QC (checkedBy / packedBy).
// ══════════════════════════════════════════════════════════════
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
  final _formKey = GlobalKey<FormState>();

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

    // Job.elastics is a list of { elastic: { _id, name }, quantity }.
    final elastics = SafeJson.asMapList(widget.job['elastics'])
        .map((row) {
          final el = SafeJson.asMap(row['elastic']);
          return {
            'id':   SafeJson.asString(el['_id']),
            'name': SafeJson.asString(el['name'], 'Elastic'),
          };
        })
        .where((e) => (e['id'] as String).isNotEmpty)
        .toList();

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
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFF1E3A5F)),
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
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

            // ── Elastic picker ────────────────────────────────
            _SectionLabel(label: 'ELASTIC'),
            const SizedBox(height: 8),
            Obx(() => DropdownButtonFormField<String>(
                  value: c.selectedElasticId.value,
                  isExpanded: true,
                  style: ErpTextStyles.fieldValue,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: ErpColors.textSecondary, size: 18),
                  decoration: ErpDecorations.formInput(
                    'Elastic *',
                    prefix: const Icon(Icons.fiber_manual_record_outlined,
                        size: 16, color: ErpColors.textMuted),
                  ),
                  hint: const Text('Select the elastic packed',
                      style: TextStyle(
                          color: ErpColors.textMuted, fontSize: 12)),
                  items: elastics.map((e) {
                    return DropdownMenuItem<String>(
                      value: e['id'] as String,
                      child: Text(e['name'] as String,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ErpColors.textPrimary)),
                    );
                  }).toList(),
                  onChanged: (v) => c.selectedElasticId.value = v,
                  validator: (v) =>
                      v == null ? 'Pick the elastic' : null,
                )),
            const SizedBox(height: 18),

            // ── Production data ───────────────────────────────
            _SectionLabel(label: 'PRODUCTION DATA'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: _numField(
                  ctrl:  c.meterCtrl,
                  label: 'Meters *',
                  icon:  Icons.straighten_outlined,
                  isDouble: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numField(
                  ctrl:  c.jointsCtrl,
                  label: 'Joints',
                  icon:  Icons.link_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (int.tryParse(v) == null) return 'Invalid';
                    return null;
                  },
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _textField(
                  ctrl:  c.stretchCtrl,
                  label: 'Stretch %',
                  icon:  Icons.expand_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _textField(
                  ctrl:  c.sizeCtrl,
                  label: 'Size',
                  icon:  Icons.aspect_ratio_outlined,
                ),
              ),
            ]),
            const SizedBox(height: 18),

            // ── Weights ──────────────────────────────────────────
            _SectionLabel(label: 'WEIGHT DETAILS'),
            const SizedBox(height: 8),
            _numField(
              ctrl:  c.netCtrl,
              label: 'Net Weight (kg) *',
              icon:  Icons.scale_outlined,
              isDouble: true,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _numField(
                  ctrl:  c.tareCtrl,
                  label: 'Tare (kg) *',
                  icon:  Icons.scale_outlined,
                  isDouble: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numField(
                  ctrl:  c.grossCtrl,
                  label: 'Gross (kg) *',
                  icon:  Icons.scale_outlined,
                  isDouble: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid';
                    return null;
                  },
                ),
              ),
            ]),
            const SizedBox(height: 18),

            // ── QC ───────────────────────────────────────────────
            _SectionLabel(label: 'QUALITY CONTROL'),
            const SizedBox(height: 8),
            Obx(() {
              if (c.isEmpLoading.value) {
                return _LoadingChip(label: 'Loading teammates…');
              }
              return Column(children: [
                DropdownButtonFormField<String>(
                  value: c.selectedCheckedById.value,
                  isExpanded: true,
                  style: ErpTextStyles.fieldValue,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: ErpColors.textSecondary, size: 18),
                  decoration: ErpDecorations.formInput(
                    'Checked By *',
                    prefix: const Icon(Icons.person_search_outlined,
                        size: 16, color: ErpColors.textMuted),
                  ),
                  hint: const Text('Select checker',
                      style: TextStyle(
                          color: ErpColors.textMuted, fontSize: 12)),
                  items: c.checkingEmployees.map((e) {
                    final id   = SafeJson.asString(e['_id']);
                    final name = SafeJson.asString(e['name'], '—');
                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text(name, style: ErpTextStyles.fieldValue),
                    );
                  }).toList(),
                  onChanged: (v) => c.selectedCheckedById.value = v,
                  validator: (v) =>
                      v == null ? 'Pick the checker' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: c.selectedPackedById.value,
                  isExpanded: true,
                  style: ErpTextStyles.fieldValue,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: ErpColors.textSecondary, size: 18),
                  decoration: ErpDecorations.formInput(
                    'Packed By *',
                    prefix: const Icon(Icons.inventory_outlined,
                        size: 16, color: ErpColors.textMuted),
                  ),
                  hint: const Text('Select packer',
                      style: TextStyle(
                          color: ErpColors.textMuted, fontSize: 12)),
                  items: c.packingEmployees.map((e) {
                    final id   = SafeJson.asString(e['_id']);
                    final name = SafeJson.asString(e['name'], '—');
                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text(name, style: ErpTextStyles.fieldValue),
                    );
                  }).toList(),
                  onChanged: (v) => c.selectedPackedById.value = v,
                  validator: (v) =>
                      v == null ? 'Pick the packer' : null,
                ),
              ]);
            }),
            const SizedBox(height: 22),

            // ── Submit ───────────────────────────────────────────
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
                            if (!_formKey.currentState!.validate()) return;
                            FocusScope.of(context).unfocus();
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
      ),
    );
  }

  Widget _numField({
    required TextEditingController ctrl,
    required String label,
    IconData? icon,
    bool isDouble = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller:   ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            isDouble ? RegExp(r'[\d.]') : RegExp(r'\d')),
      ],
      style:        ErpTextStyles.fieldValue,
      decoration: ErpDecorations.formInput(
        label,
        prefix: icon != null
            ? Icon(icon, size: 16, color: ErpColors.textMuted)
            : null,
      ),
      validator: validator,
    );
  }

  Widget _textField({
    required TextEditingController ctrl,
    required String label,
    IconData? icon,
  }) {
    return TextFormField(
      controller: ctrl,
      style:      ErpTextStyles.fieldValue,
      decoration: ErpDecorations.formInput(
        label,
        prefix: icon != null
            ? Icon(icon, size: 16, color: ErpColors.textMuted)
            : null,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(label,
            style: const TextStyle(
                color: ErpColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0)),
      );
}

class _LoadingChip extends StatelessWidget {
  final String label;
  const _LoadingChip({required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: ErpColors.bgSurface,
          border: Border.all(color: ErpColors.borderLight),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(children: [
          const SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(
                color: ErpColors.accentBlue, strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  color: ErpColors.textSecondary, fontSize: 12)),
        ]),
      );
}
