import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../core/api_client.dart';
import '../../auth/controllers/login_controller.dart';

/// Loads the worker's currently OPEN shift with full machine +
/// orderRunning + elastics populate. Backed by
/// `GET /shift/active-job/:empId`. Returns null when there's no
/// open shift for this worker.
class ActiveJobController extends GetxController {
  Dio get _dio => ApiClient.instance.dio;

  final shift     = Rxn<Map<String, dynamic>>();
  final isLoading = true.obs;
  final errorMsg  = Rxn<String>();

  String get _empId => LoginController.find.user.value.employeeId ?? '';

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    if (_empId.isEmpty) {
      errorMsg.value = 'No employee record linked.';
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    errorMsg.value  = null;
    try {
      final res = await _dio.get('/shift/active-job/$_empId');
      shift.value = (res.data['shift'] as Map?)?.cast<String, dynamic>();
    } on DioException catch (e) {
      errorMsg.value = e.response?.data?['message']?.toString() ??
          'Failed to load active job';
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
