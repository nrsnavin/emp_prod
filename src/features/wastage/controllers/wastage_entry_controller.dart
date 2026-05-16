import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/api_client.dart';
import '../../../core/safe_json.dart';
import '../../auth/controllers/login_controller.dart';

// ═════════════════════════════════════════════════════════════
//  WASTAGE ENTRY CONTROLLER (worker)
//
//  GET  /wastage/jobs-for-wastage  → weaving/finishing/checking jobs
//  POST /wastage/add-wastage       → record a wastage entry
//
//  Backend contract (matches api/wastage.js):
//    Required: job, elastic, employee, quantity (positive number), reason
//    Optional: penalty
//
//  `employee` is auto-filled from the logged-in operator's linked
//  Employee id — the worker recording the wastage is the worker the
//  wastage is attributed to. No picker (admin uses a picker because
//  admins record on behalf of others).
// ═════════════════════════════════════════════════════════════
class WastageEntryController extends GetxController {
  Dio get _dio => ApiClient.instance.dio;

  // ── Jobs list state ──────────────────────────────────
  final jobs      = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final errorMsg  = Rxn<String>();

  // ── Form state ───────────────────────────────────────
  final selectedElasticId = Rxn<String>();
  final quantityCtrl = TextEditingController();
  final penaltyCtrl  = TextEditingController();
  final reasonCtrl   = TextEditingController();

  final isSubmitting = false.obs;

  String get _empId =>
      LoginController.find.user.value.employeeId ?? '';

  @override
  void onInit() {
    super.onInit();
    fetchJobs();
  }

  @override
  void onClose() {
    quantityCtrl.dispose();
    penaltyCtrl.dispose();
    reasonCtrl.dispose();
    super.onClose();
  }

  void _clearForm() {
    quantityCtrl.clear();
    penaltyCtrl.clear();
    reasonCtrl.clear();
    selectedElasticId.value = null;
  }

  // ── Jobs ───────────────────────────────────────────────
  Future<void> fetchJobs() async {
    isLoading.value = true;
    errorMsg.value  = null;
    try {
      final res  = await _dio.get('/wastage/jobs-for-wastage');
      final body = SafeJson.asMap(res.data);
      jobs.assignAll(SafeJson.asMapList(body['jobs']));
    } on DioException catch (e) {
      errorMsg.value = SafeJson.apiErrorMessage(e.response?.data) ??
          'Failed to load jobs';
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // ── Submit ─────────────────────────────────────────────
  Future<bool> submit({required String jobId}) async {
    if (jobId.isEmpty) {
      _snack('Validation', 'No job selected', isError: true);
      return false;
    }
    if (_empId.isEmpty) {
      _snack('Validation',
          'No employee record linked to your login', isError: true);
      return false;
    }
    if (selectedElasticId.value == null) {
      _snack('Validation', 'Pick the elastic', isError: true);
      return false;
    }
    final qty = double.tryParse(quantityCtrl.text.trim());
    if (qty == null || qty <= 0) {
      _snack('Validation', 'Enter a valid quantity', isError: true);
      return false;
    }
    final reason = reasonCtrl.text.trim();
    if (reason.isEmpty) {
      _snack('Validation', 'Reason is required', isError: true);
      return false;
    }
    final penalty = double.tryParse(penaltyCtrl.text.trim()) ?? 0.0;

    isSubmitting.value = true;
    try {
      await _dio.post('/wastage/add-wastage', data: {
        'job':      jobId,
        'elastic':  selectedElasticId.value,
        'employee': _empId,
        'quantity': qty,
        'penalty':  penalty,
        'reason':   reason,
      });
      _clearForm();
      _snack(
        'Wastage Recorded',
        '${qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 2)} m',
        isError: false,
      );
      await fetchJobs();
      return true;
    } on DioException catch (e) {
      _snack(
        'Error',
        SafeJson.apiErrorMessage(e.response?.data) ??
            'Failed to save wastage',
        isError: true,
      );
      return false;
    } catch (e) {
      _snack('Error', e.toString(), isError: true);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  void _snack(String title, String msg, {required bool isError}) {
    Get.snackbar(
      title, msg,
      backgroundColor: isError
          ? const Color(0xFFDC2626)
          : const Color(0xFF16A34A),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }
}
