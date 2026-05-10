import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../core/api_client.dart';
import '../../auth/controllers/login_controller.dart';

/// Loads the logged-in employee's monthly attendance grid from
/// `GET /attendance/monthly/:empId?year=&month=`. Each calendar
/// entry has shape:
///   { date, day, dayOfWeek, dayShift, nightShift, summary }
/// where `summary` is one of: present, late, half_day, absent,
/// on_leave, mixed, untracked.
class AttendanceController extends GetxController {
  Dio get _dio => ApiClient.instance.dio;

  final selectedYear  = DateTime.now().year.obs;
  final selectedMonth = DateTime.now().month.obs;

  final calendar    = <Map<String, dynamic>>[].obs;
  final stats       = Rxn<Map<String, dynamic>>();
  final daysInMonth = 0.obs;
  final isLoading   = true.obs;
  final errorMsg    = Rxn<String>();

  String get _empId => LoginController.find.user.value.employeeId ?? '';

  @override
  void onInit() {
    super.onInit();
    fetchMonth();
  }

  Future<void> fetchMonth() async {
    if (_empId.isEmpty) {
      errorMsg.value = 'No employee record linked.';
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    errorMsg.value  = null;
    try {
      final res = await _dio.get(
        '/attendance/monthly/$_empId',
        queryParameters: {
          'year':  selectedYear.value,
          'month': selectedMonth.value,
        },
      );
      final body = (res.data as Map).cast<String, dynamic>();
      stats.value       = (body['stats'] as Map?)?.cast<String, dynamic>();
      daysInMonth.value = (body['daysInMonth'] as num?)?.toInt() ?? 0;
      calendar.assignAll(((body['calendar'] as List?) ?? const [])
          .map((e) => (e as Map).cast<String, dynamic>()));
    } on DioException catch (e) {
      errorMsg.value = e.response?.data?['message']?.toString() ??
          'Failed to load attendance';
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void changeMonth(int year, int month) {
    selectedYear.value  = year;
    selectedMonth.value = month;
    fetchMonth();
  }

  /// Lookup helper used by the calendar widget.
  Map<String, dynamic>? entryFor(DateTime day) {
    final key = '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    for (final e in calendar) {
      if (e['date'] == key) return e;
    }
    return null;
  }

  /// Attendance % (present + late + half_day*0.5) / total × 100.
  int get attendancePct {
    final s = stats.value;
    if (s == null) return 0;
    final total = (s['total'] as num?)?.toInt() ?? 0;
    if (total == 0) return 0;
    final present  = (s['present']  as num?)?.toDouble() ?? 0;
    final late     = (s['late']     as num?)?.toDouble() ?? 0;
    final halfDay  = (s['halfDay']  as num?)?.toDouble() ?? 0;
    return ((present + late + halfDay * 0.5) / total * 100).round();
  }
}
