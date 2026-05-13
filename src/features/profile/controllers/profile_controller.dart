import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../core/api_client.dart';
import '../../../core/safe_json.dart';
import '../../auth/controllers/login_controller.dart';

/// Loads the full Employee detail + last 10 shifts using
/// `GET /employee/get-employee-detail?id=`.
class ProfileController extends GetxController {
  Dio get _dio => ApiClient.instance.dio;

  final profile   = Rxn<Map<String, dynamic>>();
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
      final res = await _dio.get(
        '/employee/get-employee-detail',
        queryParameters: {'id': _empId},
      );
      profile.value =
          SafeJson.asMapOrNull(SafeJson.asMap(res.data)['employee']);
    } on DioException catch (e) {
      errorMsg.value = SafeJson.apiErrorMessage(e.response?.data) ??
          'Failed to load profile';
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
