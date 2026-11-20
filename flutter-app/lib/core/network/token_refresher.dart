import 'package:dio/dio.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/storage/token_storage.dart';

class TokenRefresher {
  TokenRefresher({
    required Future<void> Function(String token) onTokenRefreshed,
  }) : _onTokenRefreshed = onTokenRefreshed;

  final Future<void> Function(String token) _onTokenRefreshed;

  static const Duration _cooldown = Duration(seconds: 45);
  DateTime? _lastFailure;

  Future<String?> attempt() async {
    final now = DateTime.now();
    if (_lastFailure != null && now.difference(_lastFailure!) < _cooldown) {
      return null;
    }
    final email = await TokenStorage.readEmail();
    final password = await TokenStorage.readPassword();
    if (email == null || password == null) return null;

    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.timeout,
        receiveTimeout: ApiConfig.timeout,
        headers: ApiConfig.baseHeaders,
      ),
    );

    try {
      final resp = await dio.post<dynamic>(ApiConfig.loginEndpoint, data: {
        'email': email,
        'password': password,
      });
      final data = resp.data;
      final token = data is Map ? (data['token'] as String?) : null;
      if (token == null || token.isEmpty) return null;
      _lastFailure = null;
      await _onTokenRefreshed(token);
      return token;
    } catch (_) {
      _lastFailure = DateTime.now();
      return null;
    }
  }
}