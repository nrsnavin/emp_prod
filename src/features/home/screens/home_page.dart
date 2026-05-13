import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/error_boundary.dart';
import '../../../theme/erp_theme.dart';
import '../../active_job/screens/active_job_page.dart';
import '../../attendance/screens/attendance_page.dart';
import '../../auth/controllers/login_controller.dart';
import '../../bonus/screens/bonus_page.dart';
import '../../feedback/screens/feedback_page.dart';
import '../../leave/screens/leave_page.dart';
import '../../machine_issue/screens/machine_issue_page.dart';
import '../../notice_board/screens/notice_board_page.dart';
import '../../payroll/screens/payroll_page.dart';
import '../../profile/screens/profile_page.dart';
import '../../settings/screens/settings_page.dart';
import '../../shift_history/screens/shift_history_page.dart';
import '../../shift_production/screens/shift_production_page.dart';
import '../../wastage/screens/wastage_page.dart';

/// Dashboard shown after successful login.
///
/// Header: navy hero showing employee name + department + linked-id
/// banner if the User has no Employee link.
/// Body : scrollable grid of feature cards.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = LoginController.find;
    return Scaffold(
      backgroundColor: ErpColors.bgBase,
      body: SafeArea(
        child: Obx(() {
          final u = c.user.value;
          return Column(children: [
            // ── Hero header ────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
              decoration: const BoxDecoration(color: ErpColors.navyDark),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          ErpColors.accentBlue.withOpacity(0.22),
                      child: const Icon(Icons.person_outline,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.name.isNotEmpty ? u.name : 'Welcome',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (u.department?.isNotEmpty ?? false) u.department!,
                              if (u.employeeRole?.isNotEmpty ?? false) u.employeeRole!,
                            ].join('  ·  '),
                            style: const TextStyle(
                              color: ErpColors.textOnDarkSub,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Settings',
                      icon: const Icon(Icons.settings_outlined,
                          color: Colors.white, size: 20),
                      onPressed: () =>
                          _open('Settings', const SettingsPage()),
                    ),
                    IconButton(
                      tooltip: 'Sign out',
                      icon: const Icon(Icons.logout_outlined,
                          color: Colors.white, size: 20),
                      onPressed: () async {
                        await c.logout();
                      },
                    ),
                  ]),
                  if (!u.hasEmployeeLink) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: ErpColors.warningAmber.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color:
                                ErpColors.warningAmber.withOpacity(0.45)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'No employee record linked to your login. Ask your supervisor to link your User to an Employee.',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),
            ),

            // ── Feature grid ───────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: [
                    _FeatureCard(
                      title:    'Enter Shift\nProduction',
                      subtitle: 'Close an open shift',
                      icon:     Icons.precision_manufacturing_outlined,
                      color:    ErpColors.accentBlue,
                      enabled:  u.hasEmployeeLink,
                      onTap: () => _open('Shift Production',
                          const ShiftProductionPage()),
                    ),
                    _FeatureCard(
                      title:    'Shift\nHistory',
                      subtitle: 'Open & closed shifts',
                      icon:     Icons.calendar_view_day_outlined,
                      color:    const Color(0xFF0891B2),
                      enabled:  u.hasEmployeeLink,
                      onTap: () => _open('Shift History',
                          const ShiftHistoryPage()),
                    ),
                    _FeatureCard(
                      title:    'Attendance',
                      subtitle: 'Monthly calendar',
                      icon:     Icons.calendar_month_outlined,
                      color:    const Color(0xFF7C3AED),
                      enabled:  u.hasEmployeeLink,
                      onTap: () =>
                          _open('Attendance', const AttendancePage()),
                    ),
                    _FeatureCard(
                      title:    'Leave',
                      subtitle: 'Request & track',
                      icon:     Icons.event_available_outlined,
                      color:    const Color(0xFF0EA5E9),
                      enabled:  u.hasEmployeeLink,
                      onTap: () => _open('Leave', const LeavePage()),
                    ),
                    _FeatureCard(
                      title:    'Wastage\nReport',
                      subtitle: 'Last 50 records',
                      icon:     Icons.delete_sweep_outlined,
                      color:    ErpColors.errorRed,
                      enabled:  u.hasEmployeeLink,
                      onTap: () => _open('Wastage', const WastagePage()),
                    ),
                    _FeatureCard(
                      title:    'Payroll',
                      subtitle: 'Slip & advances',
                      icon:     Icons.receipt_long_outlined,
                      color:    ErpColors.successGreen,
                      enabled:  u.hasEmployeeLink,
                      onTap: () => _open('Payroll', const PayrollPage()),
                    ),
                    _FeatureCard(
                      title:    'Yearly\nBonus',
                      subtitle: 'View & download',
                      icon:     Icons.workspace_premium_outlined,
                      color:    ErpColors.warningAmber,
                      enabled:  u.hasEmployeeLink,
                      onTap: () =>
                          _open('Yearly Bonus', const BonusPage()),
                    ),
                    _FeatureCard(
                      title:    'Current\nJob',
                      subtitle: 'Machine & elastics',
                      icon:     Icons.assignment_turned_in_outlined,
                      color:    const Color(0xFF14B8A6),
                      enabled:  u.hasEmployeeLink,
                      onTap: () =>
                          _open('Current Job', const ActiveJobPage()),
                    ),
                    _FeatureCard(
                      title:    'Machine\nIssues',
                      subtitle: 'Report breakdown',
                      icon:     Icons.build_circle_outlined,
                      color:    const Color(0xFFEA580C),
                      enabled:  u.hasEmployeeLink,
                      onTap: () =>
                          _open('Machine Issues', const MachineIssuePage()),
                    ),
                    _FeatureCard(
                      title:    'Notice\nBoard',
                      subtitle: 'Announcements',
                      icon:     Icons.campaign_outlined,
                      color:    const Color(0xFF6366F1),
                      enabled:  u.hasEmployeeLink,
                      onTap: () =>
                          _open('Notice Board', const NoticeBoardPage()),
                    ),
                    _FeatureCard(
                      title:    'Feedback',
                      subtitle: 'Complaints & ideas',
                      icon:     Icons.forum_outlined,
                      color:    const Color(0xFFDB2777),
                      enabled:  u.hasEmployeeLink,
                      onTap: () => _open('Feedback', const FeedbackPage()),
                    ),
                    _FeatureCard(
                      title:    'My\nProfile',
                      subtitle: 'Personal & shifts',
                      icon:     Icons.person_outline,
                      color:    const Color(0xFF475569),
                      enabled:  u.hasEmployeeLink,
                      onTap: () => _open('Profile', const ProfilePage()),
                    ),
                  ],
                ),
              ),
            ),
          ]);
        }),
      ),
    );
  }

  /// Navigates to [page] wrapped in an ErrorBoundary so a crash on
  /// that screen falls back to a recovery card instead of taking
  /// the home dashboard down with it.
  void _open(String label, Widget page) {
    Get.to(() => ErrorBoundary(label: label, child: page));
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            decoration: BoxDecoration(
              color: ErpColors.bgSurface,
              border: Border.all(color: ErpColors.borderLight),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ErpColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: ErpColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
