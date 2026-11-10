import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/controllers/storage_keys.dart';

// Singleton Dio instance for the employee app. Mirrors the admin
// app's ApiClient so the JWT cookie set at login flows with every
// request — the backend reads `req.cookies.token`, populates
// `req.user`, and the audit-fields plugin records who did what.
class ApiClient {
  // Read the backend root from --dart-define=BASE_URL=... at build
  // time so dev/staging/prod APKs can ship the same code with
  // different backends.
  //
  // The default is the production API over HTTPS, the same address the
  // admin app uses. It used to be plain http:// to the server's IP, so
  // every worker's session token, PIN sign-in and payslip crossed the
  // network unencrypted. A local backend is a flag away:
  //   flutter run --dart-define=BASE_URL=http://10.0.2.2:2701/api/v2
  static const _defaultBaseUrl = 'https://api.baluelastics.com/api/v2';
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  /// Called when the server refuses the session this app holds (a 401
  /// on a request that carried the token): signed out elsewhere, the
  /// password changed, or the login closed because the employee has
  /// left. The login controller sets this, so the app goes back to the
  /// sign-in screen instead of showing screens whose every request
  /// fails.
  static void Function()? onSessionEnded;

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl:        baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(StorageKeys.token) ?? '';
          if (token.isNotEmpty) {
            options.headers['Cookie'] = 'token=$token';
          }
          handler.next(options);
        },
        onError: (e, handler) {
          // Only a request that sent a token: a wrong password on the
          // sign-in screen is a 401 too, and ends nothing.
          final refused = e.response?.statusCode == 401 &&
              e.requestOptions.headers.containsKey('Cookie');
          if (refused) onSessionEnded?.call();
          handler.next(e);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio dio;
}
