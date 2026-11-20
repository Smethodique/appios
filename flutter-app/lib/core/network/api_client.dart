import 'package:dio/dio.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/network/token_refresher.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio dio;
  Future<String?> Function()? _tokenRefresher;
  Future<void> Function()? _onSessionExpired;
  String? Function()? _tokenReader;
  Future<String?>? _inflightRefresh;

  void init({
    required String? Function() tokenReader,
    required Future<void> Function(String token) onTokenRefreshed,
    required Future<void> Function() onSessionExpired,
  }) {
    _tokenReader = tokenReader;
    _onSessionExpired = onSessionExpired;

    final refresher = TokenRefresher(onTokenRefreshed: onTokenRefreshed);
    _tokenRefresher = refresher.attempt;

    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.timeout,
        receiveTimeout: ApiConfig.timeout,
        sendTimeout: ApiConfig.timeout,
        headers: ApiConfig.baseHeaders,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokenReader?.call();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final path = error.requestOptions.path;
          final isAuthRoute = path.contains(ApiConfig.loginEndpoint) ||
              path.contains('/set-password') ||
              path.contains('/register');
          final alreadyRetried = error.requestOptions.extra['_retried'] == true;
          if (status == 401 && !isAuthRoute && !alreadyRetried) {
            final newToken = await _refreshSingleFlight();
            if (newToken != null && newToken.isNotEmpty) {
              error.requestOptions.extra['_retried'] = true;
              error.requestOptions.headers['Authorization'] =
                  'Bearer $newToken';
              try {
                final retry = await dio.fetch(error.requestOptions);
                return handler.resolve(retry);
              } catch (retryError) {
                return handler.next(
                  retryError is DioException
                      ? retryError
                      : DioException(
                          requestOptions: error.requestOptions,
                          error: retryError,
                        ),
                );
              }
            }
            await _onSessionExpired?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<String?>? _refreshSingleFlight() {
    final inFlight = _inflightRefresh;
    if (inFlight != null) return inFlight;
    _inflightRefresh = _tokenRefresher
        ?.call()
        .whenComplete(() => _inflightRefresh = null);
    return _inflightRefresh;
  }
}