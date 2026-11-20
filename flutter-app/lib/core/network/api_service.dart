import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/core/network/api_client.dart';
import 'package:medcin_app/core/storage/token_storage.dart';

class ApiService {
  static String? _token;
  static String? _roleSlug;
  static String? _meName;
  static int? _meId;
  static bool _initialized = false;
  static Future<void> Function()? _sessionExpiredHandler;

  static String? get token => _token;
  static String? get roleSlug => _roleSlug;
  static bool get isDoctor => _roleSlug == 'medecin';
  static String get meName => _meName ?? '';
  static int? get meId => _meId;
  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  static void setRoleFromUser(dynamic user) {
    if (user is Map) {
      _meName = user['name']?.toString();
      _meId = (user['id'] as num?)?.toInt();
      final role = user['role'];
      if (role is Map) _roleSlug = role['slug']?.toString();
    }
  }

  static Future<void> init() async {
    if (_initialized) return;
    _token = await TokenStorage.readToken();

    ApiClient.instance.init(
      tokenReader: () => _token,
      onTokenRefreshed: _applyToken,
      onSessionExpired: _expireSession,
    );
    _initialized = true;
  }

  static Future<void> _applyToken(String token) async {
    _token = token;
    await TokenStorage.writeToken(token);
  }

  static Future<void> setToken(String token) async {
    _token = token;
    await TokenStorage.writeToken(token);
  }

  static Future<void> clearToken() async {
    _token = null;
    await TokenStorage.deleteToken();
  }

  static Future<void> cacheCredentials(String email, String password) async {
    await TokenStorage.saveCredentials(email, password);
  }

  static Future<void> _expireSession() async {
    await clearToken();
    await TokenStorage.clearCredentials();
    final handler = _sessionExpiredHandler;
    if (handler != null) {
      try {
        await handler();
      } catch (_) {}
    }
  }

  static void setSessionExpiredHandler(Future<void> Function() handler) {
    _sessionExpiredHandler = handler;
  }

  static Future<void> refreshUser() async {
    final me = await get(ApiConfig.userEndpoint);
    setRoleFromUser(me);
  }

  static Future<dynamic> get(String endpoint,
      {Map<String, String>? queryParams}) {
    return _run(() => ApiClient.instance.dio.get<dynamic>(
          endpoint,
          queryParameters: queryParams,
        ));
  }

  static Future<dynamic> post(String endpoint,
      {Map<String, dynamic>? body, bool isForm = false}) {
    return _run(() => ApiClient.instance.dio.post<dynamic>(
          endpoint,
          data: body,
          options: Options(contentType: isForm ? Headers.formUrlEncodedContentType : Headers.jsonContentType),
        ));
  }

  static Future<dynamic> patch(String endpoint,
      {Map<String, dynamic>? body}) {
    return _run(() => ApiClient.instance.dio.patch<dynamic>(endpoint, data: body));
  }

  static Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) {
    return _run(() => ApiClient.instance.dio.put<dynamic>(endpoint, data: body));
  }

  static Future<dynamic> delete(String endpoint) {
    return _run(() => ApiClient.instance.dio.delete<dynamic>(endpoint));
  }

  static Future<Uint8List> downloadBytes(String endpoint) async {
    try {
      final response = await ApiClient.instance.dio.get<List<int>>(
        endpoint,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const []);
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data?.toString() ?? 'Téléchargement impossible',
        statusCode: e.response?.statusCode ?? 0,
      );
    }
  }

  static Future<dynamic> postMultipart(
    String endpoint, {
    required MultipartFile file,
    Map<String, dynamic>? fields,
  }) {
    final form = FormData();
    fields?.forEach((key, value) => form.fields.add(MapEntry(key, value.toString())));
    form.files.add(MapEntry('file', file));
    return _run(
      () => ApiClient.instance.dio.post<dynamic>(
        endpoint,
        data: form,
        options: Options(contentType: Headers.multipartFormDataContentType),
      ),
    );
  }

  static Future<dynamic> _run(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Une erreur est survenue';
      Map<String, List<String>> errors = {};
      if (data is Map) {
        final rawErrors = data['errors'];
        if (rawErrors is Map) {
          rawErrors.forEach((key, value) {
            final field = key.toString();
            errors[field] = value is List
                ? value.map((i) => i.toString()).toList()
                : [value.toString()];
          });
        }
        if (data['message'] is String && (data['message'] as String).isNotEmpty) {
          message = data['message'] as String;
        }
      } else if (data is String && data.isNotEmpty) {
        message = data;
      }
      if (errors.isNotEmpty && message == 'The given data was invalid.') {
        message = errors.values.expand((v) => v).first;
      }
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Le serveur met trop de temps à répondre.';
          break;
        case DioExceptionType.connectionError:
          message = 'Impossible de joindre le serveur.';
          break;
        default:
          break;
      }
      throw ApiException(message: message, statusCode: e.response?.statusCode ?? 0, errors: errors);
    } on TimeoutException {
      throw ApiException(
          message: 'Le serveur met trop de temps à répondre.', statusCode: 0);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Erreur inattendue ($e)', statusCode: 0);
    }
  }
}