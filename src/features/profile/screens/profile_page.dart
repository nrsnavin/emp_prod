import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/safe_json.dart';
import '../../../theme/erp_theme.dart';
import '../../auth/controllers/login_controller.dart';
import '../controllers/profile_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ProfileController(), tag: 'profile');
    final u = LoginController.find.user.value;
    return Scaffold(
      backgroundColor: ErpColors.bgBase,
      appBar: AppBar(
        backgroundColor: ErpColors.navyDark,
        elevation: 0,
        title: const Text('My Profile', style: ErpTextStyles.pageTitle),
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: ErpColors.accentBlue));
        }
        if (c.errorMsg.value != null) {
          return _Error(msg: c.errorMsg.value!, onRetry: c.fetch);
        }
        final p = c.profile.value ?? const {};
        return RefreshIndicator(
          onRefresh: c.fetch,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              _IdentityCard(profile: p, email: u.email),
              const SizedBox(height: 14),
              _StatsCard(profile: p),
              const SizedBox(height: 14),
              _ContactCard(profile: p),
              const SizedBox(height: 14),
              _RecentShiftsCard(shifts: SafeJson.asMapList(p['result'])),
            ],
          ),
        );
      }),
    );
  }
}

// ── Identity card ──────────────────────────────────────────────
class _IdentityCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final String email;
  const _IdentityCard({required this.profile, required this.email});
  @override
  Widget build(BuildContext context) {
    final name = SafeJson.asString(profile['name'], '—');
    final dept = SafeJson.asString(profile['department'], '—');
    final role = SafeJson.asString(profile['role'], '—');
    return Container(
      decoration: BoxDecoration(
        color: ErpColors.navyDark,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: ErpColors.accentBlue.withOpacity(0.25),
          child: const Icon(Icons.person_outline,
              color: Colors.white, size: 30),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text('$dept  ·  $role',
                  style: const TextStyle(
                      color: ErpColors.textOnDarkSub, fontSize: 12)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.mail_outline,
                    size: 12, color: ErpColors.textOnDarkSub),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(email,
                      style: const TextStyle(
                          color: ErpColors.textOnDarkSub, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Stats card ─────────────────────────────────────────────────
class _StatsCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  const _StatsCard({required this.profile});
  @override
  Widget build(BuildContext context) {
    final skill       = SafeJson.asInt(profile['skill']);
    final performance = SafeJson.asInt(profile['performance']);
    final totalShifts = SafeJson.asInt(profile['totalShifts']);
    return ErpSectionCard(
      title: 'PERFORMANCE',
      icon: Icons.insights_outlined,
      child: Row(children: [
        _Stat('Skill',       '$skill', ErpColors.accentBlue),
        const SizedBox(width: 10),
        _Stat('Performance', '$performance%', ErpColors.successGreen),
        const SizedBox(width: 10),
        _Stat('Total Shifts','$totalShifts', ErpColors.warningAmber),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      );
}

// ── Contact card ───────────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  const _ContactCard({required this.profile});
  @override
  Widget build(BuildContext context) {
    return ErpSectionCard(
      title: 'CONTACT & PERSONAL',
      icon: Icons.contact_phone_outlined,
      child: Column(children: [
        _kv(Icons.phone_outlined, 'Phone',
            SafeJson.asString(profile['phoneNumber'], '—')),
        _kv(Icons.badge_outlined, 'Aadhaar',
            SafeJson.asString(profile['aadhar'], 'Not Provided')),
      ]),
    );
  }

  Widget _kv(IconData icon, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, size: 14, color: ErpColors.textMuted),
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

// ── Recent shifts ──────────────────────────────────────────────
class _RecentShiftsCard extends StatelessWidget {
  final List<Map<String, dynamic>> shifts;
  const _RecentShiftsCard({required this.shifts});
  @override
  Widget build(BuildContext context) {
    if (shifts.isEmpty) {
      return ErpSectionCard(
        title: 'RECENT SHIFTS',
        icon: Icons.history_outlined,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('No recent shifts recorded.',
              style: TextStyle(
                  color: ErpColors.textSecondary, fontSize: 12)),
        ),
      );
    }
    final fmt = DateFormat('dd MMM');
    return ErpSectionCard(
      title: 'RECENT SHIFTS',
      icon: Icons.history_outlined,
      child: Column(
        children: shifts.take(10).map((s) {
          final dt = SafeJson.asLocalDateTime(s['date']);
          final when = dt == null ? '—' : fmt.format(dt);
          final shiftLabel = SafeJson.asString(s['shift'], '—');
          final machine    = SafeJson.asString(s['machine'], '—');
          final output     = SafeJson.asInt(s['outputMeters']);
          final efficiency = SafeJson.asDouble(s['efficiency']);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              SizedBox(
                width: 56,
                child: Text(when,
                    style: const TextStyle(
                        color: ErpColors.textMuted, fontSize: 11)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ErpColors.statusOpenBg,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(shiftLabel.toUpperCase(),
                    style: const TextStyle(
                        color: ErpColors.statusOpenText,
                        fontSize: 9,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('M-$machine',
                    style: const TextStyle(
                        color: ErpColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ),
              Text('$output m',
                  style: const TextStyle(
                      color: ErpColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              Text('${efficiency.toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: efficiency >= 80
                          ? ErpColors.successGreen
                          : ErpColors.warningAmber,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ]),
          );
        }).toList(),
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
