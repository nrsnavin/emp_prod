import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api_client.dart';
import '../../../core/safe_json.dart';
import '../../auth/controllers/storage_keys.dart';

// ═════════════════════════════════════════════════════════════
//  PACKING ENTRY CONTROLLER (worker)
//
//  GET  /packing/jobs-packing                    → active packing-ready jobs
//  GET  /packing/employees-by-department/:dept   → dept teammates
//  POST /packing/create-packing                  → submit a packing batch
// ═════════════════════════════════════════════════════════════
class PackingEntryController extends GetxController {
  Dio get _dio => ApiClient.instance.dio;

  // ── Jobs list state ─────────────────────────────────────────────
  final jobs       = <Map<String, dynamic>>[].obs;
  final isLoading  = true.obs;
  final errorMsg   = Rxn<String>();

  // ── Employee dropdown state ──────────────────────────────────────
  final employees  = <Map<String, dynamic>>[].obs;
  final isEmpLoading = false.obs;

  // ── Form state ──────────────────────────────────────────────────────
  final isSubmitting = false.obs;
  final qtyCtrl     = TextEditingController();
  final weightCtrl  = TextEditingController();
  final notesCtrl   = TextEditingController();
  final selectedEmployeeId = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    fetchJobs();
  }

  @override
  void onClose() {
    qtyCtrl.dispose();
    weightCtrl.dispose();
    notesCtrl.dispose();
    super.onClose();
  }

  // ── Jobs ─────────────────────────────────────────────────────────────
  Future<void> fetchJobs() async {
    isLoading.value = true;
    errorMsg.value  = null;
    try {
      final res  = await _dio.get('/packing/jobs-packing');
      final body = SafeJson.asMap(res.data);
      // Endpoint may shape response as { jobs: [...] } or as raw list.
      final raw  = body['jobs'] is List
          ? SafeJson.asMapList(body['jobs'])
          : (res.data is List
              ? SafeJson.asMapList(res.data)
              : SafeJson.asMapList(body['data']));
      jobs.assignAll(raw);
    } on DioException catch (e) {
      errorMsg.value = SafeJson.apiErrorMessage(e.response?.data) ??
          'Failed to load packing jobs';
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // ── Employees by dept (cached after first call) ──────────────────
  Future<void> loadEmployees({String dept = 'packing'}) async {
    if (employees.isNotEmpty) return;
    isEmpLoading.value = true;
    try {
      final res  = await _dio.get('/packing/employees-by-department/$dept');
      final body = SafeJson.asMap(res.data);
      final raw  = body['employees'] is List
          ? SafeJson.asMapList(body['employees'])
          : (res.data is List
              ? SafeJson.asMapList(res.data)
              : SafeJson.asMapList(body['data']));
      employees.assignAll(raw);
    } on DioException catch (e) {
      Get.snackbar(
        'Error',
        SafeJson.apiErrorMessage(e.response?.data) ??
            'Failed to load teammates',
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isEmpLoading.value = false;
    }
  }

  // ── Resolve logged-in employeeId for the form ───────────────────
  Future<String?> _myEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(StorageKeys.employeeId);
    return (id != null && id.isNotEmpty) ? id : null;
  }

  // ── Submit packing batch ────────────────────────────────────────────
  Future<bool> submit({required String jobId}) async {
    final qty   = int.tryParse(qtyCtrl.text.trim());
    final wt    = double.tryParse(weightCtrl.text.trim());
    final notes = notesCtrl.text.trim();

    if (jobId.isEmpty) {
      _snack('Validation', 'No job selected', isError: true);
      return false;
    }
    if (qty == null || qty < 1) {
      _snack('Validation', 'Enter a valid quantity', isError: true);
      return false;
    }
    if (wt == null || wt <= 0) {
      _snack('Validation', 'Enter a valid weight (kg)', isError: true);
      return false;
    }

    final myEmpId = await _myEmployeeId();
    final teammateId = selectedEmployeeId.value;

    isSubmitting.value = true;
    try {
      await _dio.post('/packing/create-packing', data: {
        'job':      jobId,
        'quantity': qty,
        'weight':   wt,
        if (notes.isNotEmpty) 'notes': notes,
        if (myEmpId != null) 'enteredBy': myEmpId,
        if (teammateId != null && teammateId.isNotEmpty)
          'teammate': teammateId,
      });
      qtyCtrl.clear();
      weightCtrl.clear();
      notesCtrl.clear();
      selectedEmployeeId.value = null;
      _snack('Packing Saved',
          'Recorded $qty pcs (${wt.toStringAsFixed(2)} kg)',
          isError: false);
      await fetchJobs();
      return true;
    } on DioException catch (e) {
      _snack(
        'Error',
        SafeJson.apiErrorMessage(e.response?.data) ??
            'Failed to save packing entry',
        isError: true,
      );
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
