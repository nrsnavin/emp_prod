import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/api_client.dart';
import '../../../core/safe_json.dart';
import '../../../theme/erp_theme.dart';
import '../../auth/controllers/login_controller.dart';

/// Lets the worker file a machine breakdown / maintenance request
/// and track its status. Backed by /machine-issue endpoints.
class MachineIssueController extends GetxController {
  Dio get _dio => ApiClient.instance.dio;

  final issues       = <Map<String, dynamic>>[].obs;
  final activeMachineId = Rxn<String>(); // populated from active-job
  final activeMachineLabel = ''.obs;
  final isLoading    = true.obs;
  final isSubmitting = false.obs;
  final errorMsg     = Rxn<String>();

  String get _empId => LoginController.find.user.value.employeeId ?? '';

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    if (_empId.isEmpty) {
      errorMsg.value = 'No employee record linked.';
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    errorMsg.value  = null;
    try {
      // Issues history.
      final histFut = _dio.get('/machine-issue/employee/$_empId');

      // Active machine (so the form can default-fill it).
      final activeFut = _dio.get('/shift/active-job/$_empId');

      final results = await Future.wait([histFut, activeFut]);
      issues.assignAll(
          SafeJson.asMapList(SafeJson.asMap(results[0].data)['data']));

      final activeShift = SafeJson.asMap(results[1].data)['shift'];
      final m = SafeJson.asMap(SafeJson.asMap(activeShift)['machine']);
      activeMachineId.value    = SafeJson.asStringOrNull(m['_id']);
      activeMachineLabel.value = SafeJson.asString(m['ID']);
    } on DioException catch (e) {
      errorMsg.value = SafeJson.apiErrorMessage(e.response?.data) ??
          'Failed to load issues';
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> submit({
    required String machineId,
    required String title,
    required String description,
    required String severity,
  }) async {
    if (machineId.isEmpty) {
      _snack('Validation', 'No machine to report against', error: true);
      return false;
    }
    if (title.trim().isEmpty || description.trim().isEmpty) {
      _snack('Validation', 'Title and description are required',
          error: true);
      return false;
    }
    isSubmitting.value = true;
    try {
      await _dio.post('/machine-issue', data: {
        'machineId':   machineId,
        'employeeId':  _empId,
        'title':       title.trim(),
        'description': description.trim(),
        'severity':    severity,
      });
      _snack('Reported', 'Maintenance team has been notified',
          error: false);
      await fetchAll();
      return true;
    } on DioException catch (e) {
      _snack('Error',
          SafeJson.apiErrorMessage(e.response?.data) ?? 'Submit failed',
          error: true);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> withdraw(String id) async {
    try {
      await _dio.delete('/machine-issue/$id');
      _snack('Withdrawn', 'Issue removed', error: false);
      await fetchAll();
      return true;
    } on DioException catch (e) {
      _snack('Error',
          SafeJson.apiErrorMessage(e.response?.data) ?? 'Cancel failed',
          error: true);
      return false;
    }
  }

  void _snack(String title, String msg, {required bool error}) {
    Get.snackbar(title, msg,
        backgroundColor:
            error ? ErpColors.errorRed : ErpColors.successGreen,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM);
  }
}
