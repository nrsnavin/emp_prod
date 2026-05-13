import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../theme/erp_theme.dart';
import '../controllers/active_job_controller.dart';
import 'elastic_detail_sheet.dart';

class ActiveJobPage extends StatelessWidget {
  const ActiveJobPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ActiveJobController(), tag: 'active-job');
    return Scaffold(
      backgroundColor: ErpColors.bgBase,
      appBar: AppBar(
        backgroundColor: ErpColors.navyDark,
        elevation: 0,
        title: const Text('Current Job', style: ErpTextStyles.pageTitle),
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: ErpColors.accentBlue));
        }
        if (c.errorMsg.value != null) {
          return _Error(msg: c.errorMsg.value!, onRetry: c.fetch);
        }
        if (c.shift.value == null) {
          return _Empty(onRefresh: c.fetch);
        }
        return RefreshIndicator(
          onRefresh: c.fetch,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              _ShiftHeader(shift: c.shift.value!),
              const SizedBox(height: 14),
              _MachineCard(shift: c.shift.value!),
              const SizedBox(height: 14),
              _OrderCard(shift: c.shift.value!),
              const SizedBox(height: 14),
              _ElasticsCard(shift: c.shift.value!),
            ],
          ),
        );
      }),
    );
  }
}

// ── Shift header ───────────────────────────────────────────────
class _ShiftHeader extends StatelessWidget {
  final Map<String, dynamic> shift;
  const _ShiftHeader({required this.shift});
  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, dd MMM yyyy');
    final raw = shift['date']?.toString();
    String when = '—';
    if (raw != null) {
      try { when = fmt.format(DateTime.parse(raw).toLocal()); } catch (_) {}
    }
    final shiftLabel = (shift['shift']?.toString() ?? '—').toUpperCase();
    return Container(
      decoration: BoxDecoration(
        color: ErpColors.navyDark,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: ErpColors.accentBlue.withOpacity(0.25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.precision_manufacturing_outlined,
              color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OPEN SHIFT',
                  style: TextStyle(
                      color: ErpColors.textOnDarkSub,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text('$shiftLabel · $when',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Machine card ───────────────────────────────────────────────
class _MachineCard extends StatelessWidget {
  final Map<String, dynamic> shift;
  const _MachineCard({required this.shift});
  @override
  Widget build(BuildContext context) {
    final m = (shift['machine'] as Map?)?.cast<String, dynamic>() ?? {};
    final id     = m['ID']?.toString() ?? '—';
    final status = m['status']?.toString() ?? '—';
    final heads  = (m['NoOfHead'] as num?)?.toInt() ?? 0;
    final hooks  = (m['NoOfHooks'] as num?)?.toInt() ?? 0;

    return ErpSectionCard(
      title: 'MACHINE',
      icon: Icons.precision_manufacturing_outlined,
      child: Column(children: [
        _kv(Icons.tag, 'ID',     id),
        _kv(Icons.bolt_outlined, 'Status', status.toUpperCase()),
        _kv(Icons.view_module_outlined, 'Heads × Hooks',
            '$heads × $hooks'),
      ]),
    );
  }

  Widget _kv(IconData icon, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 13, color: ErpColors.textMuted),
          const SizedBox(width: 8),
          Text('$k: ',
              style: const TextStyle(
                  color: ErpColors.textMuted, fontSize: 12)),
          Expanded(
            child: Text(v,
                style: const TextStyle(
                    color: ErpColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ),
        ]),
      );
}

// ── Order card ─────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> shift;
  const _OrderCard({required this.shift});
  @override
  Widget build(BuildContext context) {
    final m = (shift['machine'] as Map?)?.cast<String, dynamic>() ?? {};
    final running = (m['orderRunning'] as Map?)?.cast<String, dynamic>();
    final shiftJob = (shift['job']      as Map?)?.cast<String, dynamic>();

    final job = running ?? shiftJob;
    if (job == null) {
      return ErpSectionCard(
        title: 'JOB ORDER',
        icon: Icons.receipt_long_outlined,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('No active job on this machine.',
              style: TextStyle(
                  color: ErpColors.textSecondary, fontSize: 12)),
        ),
      );
    }
    final jobNo    = job['jobOrderNo']?.toString() ?? '—';
    final status   = job['status']?.toString() ?? '—';
    final order    = (job['order']    as Map?)?.cast<String, dynamic>();
    final customer = (job['customer'] as Map?)?.cast<String, dynamic>();
    final po       = order?['po']?.toString() ?? '—';
    final cust     = customer?['name']?.toString() ?? '—';
    final supplyRaw = order?['supplyDate']?.toString();
    String supplyWhen = '—';
    if (supplyRaw != null) {
      try {
        supplyWhen = DateFormat('dd MMM yyyy')
            .format(DateTime.parse(supplyRaw).toLocal());
      } catch (_) {}
    }

    return ErpSectionCard(
      title: 'JOB ORDER',
      icon: Icons.receipt_long_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ErpColors.statusOpenBg,
                border: Border.all(color: ErpColors.statusOpenBorder),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('JOB #$jobNo',
                  style: const TextStyle(
                      color: ErpColors.statusOpenText,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ErpColors.statusInProgressBg,
                border: Border.all(color: ErpColors.statusInProgressBorder),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(status.toUpperCase(),
                  style: const TextStyle(
                      color: ErpColors.statusInProgressText,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 10),
          _kv(Icons.confirmation_number_outlined, 'PO', po),
          _kv(Icons.business_outlined,            'Customer', cust),
          _kv(Icons.event_outlined,               'Supply by', supplyWhen),
        ],
      ),
    );
  }

  Widget _kv(IconData icon, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 13, color: ErpColors.textMuted),
          const SizedBox(width: 8),
          Text('$k: ',
              style: const TextStyle(
                  color: ErpColors.textMuted, fontSize: 12)),
          Expanded(
            child: Text(v,
                style: const TextStyle(
                    color: ErpColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      );
}

// ── Elastics card ──────────────────────────────────────────────
class _ElasticsCard extends StatelessWidget {
  final Map<String, dynamic> shift;
  const _ElasticsCard({required this.shift});
  @override
  Widget build(BuildContext context) {
    // Per-head mapping first (most useful on the floor).
    final heads = ((shift['elastics'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();

    // Order-level elastics (qty per spec).
    final m       = (shift['machine'] as Map?)?.cast<String, dynamic>() ?? {};
    final running = (m['orderRunning'] as Map?)?.cast<String, dynamic>();
    final orderElastics =
        ((running?['elastics'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();

    return ErpSectionCard(
      title: 'ELASTICS',
      icon: Icons.line_axis_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (heads.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('No head-elastic mapping set on this shift.',
                  style: TextStyle(
                      color: ErpColors.textSecondary, fontSize: 12)),
            )
          else ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                  'Tap any row to see the full spec in plain English.',
                  style: TextStyle(
                      color: ErpColors.textMuted,
                      fontSize: 11,
                      fontStyle: FontStyle.italic)),
            ),
            ...heads.map((h) {
              final headNo = (h['head'] as num?)?.toInt() ?? 0;
              final e      = (h['elastic'] as Map?)?.cast<String, dynamic>();
              final name   = e?['name']?.toString() ?? '—';
              final weave  = e?['weaveType']?.toString() ?? '';
              final weight = (e?['weight'] as num?)?.toString() ?? '';
              return InkWell(
                onTap: e == null
                    ? null
                    : () => ElasticDetailSheet.show(context,
                        elastic: e, headNo: headNo),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 6, horizontal: 4),
                  child: Row(children: [
                    Container(
                      width: 30, height: 24,
                      decoration: BoxDecoration(
                        color: ErpColors.accentBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text('H$headNo',
                          style: const TextStyle(
                              color: ErpColors.accentBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              color: ErpColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (weave.isNotEmpty)
                      Text('W$weave',
                          style: const TextStyle(
                              color: ErpColors.textMuted, fontSize: 11)),
                    if (weight.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text('${weight}g',
                          style: const TextStyle(
                              color: ErpColors.textMuted, fontSize: 11)),
                    ],
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: ErpColors.textMuted),
                  ]),
                ),
              );
            }).toList(),
          ],
          if (orderElastics.isNotEmpty) ...[
            const Divider(height: 16, color: ErpColors.borderLight),
            const Text('Order requirements',
                style: ErpTextStyles.fieldLabel),
            const SizedBox(height: 6),
            ...orderElastics.map((o) {
              final e   = (o['elastic'] as Map?)?.cast<String, dynamic>();
              final qty = (o['quantity'] as num?)?.toInt() ?? 0;
              final name = e?['name']?.toString() ?? '—';
              return InkWell(
                onTap: e == null
                    ? null
                    : () => ElasticDetailSheet.show(context, elastic: e),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 6, horizontal: 4),
                  child: Row(children: [
                    const Icon(Icons.fiber_manual_record,
                        size: 8, color: ErpColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              color: ErpColors.textPrimary, fontSize: 12)),
                    ),
                    Text('$qty m',
                        style: const TextStyle(
                            color: ErpColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: ErpColors.textMuted),
                  ]),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}

// ── Empty + error ──────────────────────────────────────────────
class _Empty extends StatelessWidget {
  final VoidCallback onRefresh;
  const _Empty({required this.onRefresh});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_busy_outlined,
                  size: 40, color: ErpColors.textMuted),
              const SizedBox(height: 10),
              const Text('No active shift right now',
                  style: TextStyle(
                      color: ErpColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text(
                  'Your supervisor hasn\'t opened a shift for you yet. '
                  'Pull to refresh once it\'s assigned.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: ErpColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: onRefresh, child: const Text('Refresh')),
            ],
          ),
        ),
      );
}

class _Error extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _Error({required this.msg, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  color: ErpColors.textMuted, size: 36),
              const SizedBox(height: 10),
              Text(msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: ErpColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
