import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../core/api_client.dart';
import '../../auth/controllers/login_controller.dart';

/// Loads active announcements for the worker's department from
/// `GET /announcement/active?dept=`.
class NoticeBoardController extends GetxController {
  Dio get _dio => ApiClient.instance.dio;

  final notices   = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final errorMsg  = Rxn<String>();

  String get _dept => LoginController.find.user.value.department ?? '';

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    isLoading.value = true;
    errorMsg.value  = null;
    try {
      final res = await _dio.get(
        '/announcement/active',
        queryParameters: {'dept': _dept},
      );
      notices.assignAll(
          ((res.data['data'] as List?) ?? const [])
              .map((e) => (e as Map).cast<String, dynamic>())
              .toList());
    } on DioException catch (e) {
      errorMsg.value = e.response?.data?['message']?.toString() ??
          'Failed to load notices';
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
