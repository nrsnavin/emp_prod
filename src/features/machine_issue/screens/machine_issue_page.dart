import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../theme/erp_theme.dart';
import '../controllers/machine_issue_controller.dart';

class MachineIssuePage extends StatelessWidget {
  const MachineIssuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(MachineIssueController(), tag: 'machine-issue');
    return Scaffold(
      backgroundColor: ErpColors.bgBase,
      appBar: AppBar(
        backgroundColor: ErpColors.navyDark,
        elevation: 0,
        title: const Text('Machine Issues', style: ErpTextStyles.pageTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ErpColors.errorRed,
        onPressed: () => _openReportSheet(context, c),
        icon: const Icon(Icons.report_problem_outlined, color: Colors.white),
        label: const Text('Report',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: ErpColors.accentBlue));
        }
        if (c.errorMsg.value != null) {
          return _Error(msg: c.errorMsg.value!, onRetry: c.fetchAll);
        }
        if (c.issues.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 100),
              Icon(Icons.build_circle_outlined,
                  size: 44, color: ErpColors.textMuted),
              SizedBox(height: 10),
              Center(
                child: Text('No machine issues reported.',
                    style: TextStyle(
                        color: ErpColors.textSecondary, fontSize: 13)),
              ),
            ],
          );
        }
        return RefreshIndicator(
          onRefresh: c.fetchAll,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
            itemCount: c.issues.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _IssueCard(c: c, issue: c.issues[i]),
          ),
        );
      }),
    );
  }

  void _openReportSheet(BuildContext ctx, MachineIssueController c) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _ReportSheet(c: c),
      ),
    );
  }
}

// ── Issue card ─────────────────────────────────────────────────
class _IssueCard extends StatelessWidget {
  final MachineIssueController c;
  final Map<String, dynamic> issue;
  const _IssueCard({required this.c, required this.issue});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, HH:mm');
    final raw = issue['createdAt']?.toString();
    String when = '—';
    if (raw != null) {
      try { when = fmt.format(DateTime.parse(raw).toLocal()); } catch (_) {}
    }
    final title = issue['title']?.toString() ?? '—';
    final desc  = issue['description']?.toString() ?? '';
    final sev   = (issue['severity']?.toString() ?? 'medium').toLowerCase();
    final status = (issue['status']?.toString() ?? 'open').toLowerCase();
    final machine = (issue['machine'] as Map?)?.cast<String, dynamic>();
    final machineId = machine?['ID']?.toString() ?? '—';
    final id = issue['_id']?.toString() ?? '';
    final notes = issue['resolutionNotes']?.toString() ?? '';

    return Container(
      decoration: ErpDecorations.card,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _Chip(label: sev.toUpperCase(), color: _severityColor(sev)),
            const SizedBox(width: 6),
            _Chip(label: status.toUpperCase(), color: _statusColor(status)),
            const Spacer(),
            Text('M-$machineId',
                style: const TextStyle(
                    color: ErpColors.textMuted, fontSize: 11)),
          ]),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                  color: ErpColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(desc,
                style: const TextStyle(
                    color: ErpColors.textSecondary, fontSize: 12)),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ErpColors.bgMuted,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Resolution: $notes',
                  style: const TextStyle(
                      color: ErpColors.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic)),
            ),
          ],
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.schedule, size: 12, color: ErpColors.textMuted),
            const SizedBox(width: 4),
            Text(when,
                style: const TextStyle(
                    color: ErpColors.textMuted, fontSize: 11)),
            const Spacer(),
            if (status == 'open')
              TextButton.icon(
                onPressed: () => c.withdraw(id),
                icon: const Icon(Icons.close_rounded,
                    size: 14, color: ErpColors.errorRed),
                label: const Text('Withdraw',
                    style: TextStyle(
                        color: ErpColors.errorRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
          ]),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800)),
      );
}

Color _severityColor(String s) {
  switch (s) {
    case 'low':      return ErpColors.successGreen;
    case 'medium':   return ErpColors.warningAmber;
    case 'high':     return ErpColors.errorRed;
    case 'critical': return Colors.purple;
    default:         return ErpColors.textMuted;
  }
}

Color _statusColor(String s) {
  switch (s) {
    case 'open':         return ErpColors.warningAmber;
    case 'acknowledged': return ErpColors.accentBlue;
    case 'in_progress':  return ErpColors.accentLight;
    case 'resolved':     return ErpColors.successGreen;
    case 'rejected':     return ErpColors.errorRed;
    default:             return ErpColors.textMuted;
  }
}

// ── Report bottom sheet ────────────────────────────────────────
class _ReportSheet extends StatefulWidget {
  final MachineIssueController c;
  const _ReportSheet({required this.c});
  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  String _severity = 'medium';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Container(
      decoration: const BoxDecoration(
        color: ErpColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: ErpColors.borderMid,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Report Machine Issue',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: ErpColors.textPrimary)),
          const SizedBox(height: 4),
          Obx(() {
            final m = c.activeMachineLabel.value;
            if (m.isEmpty) {
              return const Text(
                'No active machine detected. You can still report — '
                'open a shift first for an automatic machine link.',
                style: TextStyle(
                    color: ErpColors.warningAmber, fontSize: 11),
              );
            }
            return Text('Machine: M-$m',
                style: const TextStyle(
                    color: ErpColors.textSecondary, fontSize: 12));
          }),
          const SizedBox(height: 14),
          TextField(
            controller: _titleCtrl,
            decoration: ErpDecorations.formInput(
              'Title *',
              hint: 'e.g. Head 3 thread broken',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _severity,
            decoration: ErpDecorations.formInput('Severity *'),
            items: const [
              DropdownMenuItem(value: 'low',      child: Text('Low')),
              DropdownMenuItem(value: 'medium',   child: Text('Medium')),
              DropdownMenuItem(value: 'high',     child: Text('High')),
              DropdownMenuItem(value: 'critical', child: Text('Critical')),
            ],
            onChanged: (v) => setState(() => _severity = v ?? 'medium'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: ErpDecorations.formInput(
              'Description *',
              hint: 'What exactly is wrong / when did it start?',
            ),
          ),
          const SizedBox(height: 18),
          Obx(() => SizedBox(
                height: 44,
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ErpColors.errorRed,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: c.isSubmitting.value
                      ? null
                      : () async {
                          final mid = c.activeMachineId.value ?? '';
                          final ok = await c.submit(
                            machineId: mid,
                            title: _titleCtrl.text,
                            description: _descCtrl.text,
                            severity: _severity,
                          );
                          if (ok && Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                  icon: c.isSubmitting.value
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                  label: Text(
                    c.isSubmitting.value ? 'Sending…' : 'Report Issue',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14),
                  ),
                ),
              )),
        ],
      ),
    );
  }
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
