import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:medcin_app/core/storage/token_storage.dart';
import 'package:medcin_app/data/services/chat_service.dart';
import 'package:medcin_app/domain/models/user.dart';

enum AuthStatus { unknown, checking, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider._();
  static final AuthProvider instance = AuthProvider._();

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _token;
  bool _loading = false;
  String? _error;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get token => _token;
  String? get error => _error;
  bool get loading => _loading;
  bool get isChecking => _status == AuthStatus.checking;
  bool get isLoggedIn => _status == AuthStatus.authenticated && ApiService.isLoggedIn;
  bool get isVerified => _user?.isVerified ?? true;
  bool get isDoctor => _user?.isMedecin ?? ApiService.isDoctor;
  String get displayName =>
      _user?.name ?? (ApiService.meName.isEmpty ? 'Mon profil' : ApiService.meName);
  String get displayEmail => _user?.email ?? '';
  bool get emailVerified => _user?.isVerified ?? false;

  User? _userFromResponse(dynamic data) {
    if (data is Map && data['id'] != null) {
      return User.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<void> _syncOneSignal() async {
    if (kIsWeb) return;
    final id = _user?.id;
    if (id == null) return;
    try {
      await OneSignal.login(id.toString());
    } catch (_) {}
  }

  Future<void> checkAuthStatus() async {
    _status = AuthStatus.checking;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiService.init();
      if (!ApiService.isLoggedIn) {
        _status = AuthStatus.unauthenticated;
        return;
      }
      try {
        await ApiService.refreshUser();
        _user = _userFromResponse(await ApiService.get(ApiConfig.userEndpoint));
        await _syncOneSignal();
      } on ApiException catch (e) {
        if (e.statusCode == 401) {
          await ApiService.clearToken();
          _status = AuthStatus.unauthenticated;
          return;
        }
      }
      _token = ApiService.token;
      _status = AuthStatus.authenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final r = await ApiService.post(
        ApiConfig.loginEndpoint,
        body: {'email': email.trim(), 'password': password},
      );
      _applySession(r['token'] as String, r['user'], email.trim(), password);
    } on ApiException catch (e) {
      _error = e.message == 'CSRF token mismatch.' ? 'Identifiants invalides' : e.message;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String confirmation,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final r = await ApiService.post(
        ApiConfig.registerEndpoint,
        body: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'password_confirmation': confirmation,
          'role': 'parent',
        },
      );
      final token = r is Map ? r['token'] : null;
      _user = _userFromResponse(r is Map ? r['user'] : r);
      if (token is String && token.isNotEmpty) {
        await _applySession(token, r is Map ? r['user'] : null, email.trim());
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _applySession(String token, dynamic userData, String email,
    [String? password = '']) async {
    await ApiService.setToken(token);
    await ApiService.cacheCredentials(email, password ?? '');
    ApiService.setRoleFromUser(userData);
    _user = _userFromResponse(userData);
    await _syncOneSignal();
    _token = token;
    _status = AuthStatus.authenticated;
  }

  Future<bool> refreshUser() async {
    try {
      final data = await ApiService.get(ApiConfig.userEndpoint);
      final u = _userFromResponse(data);
      if (u != null) {
        _user = u;
        await _syncOneSignal();
        notifyListeners();
        return u.isVerified;
      }
      return _user?.isVerified ?? false;
    } on ApiException catch (e) {
      if (e.statusCode == 401) await forceLogout();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.post(ApiConfig.logoutEndpoint);
    } catch (_) {}
    ChatService.instance.dispose();
    await ApiService.clearToken();
    await TokenStorage.clearCredentials();
    if (!kIsWeb) await OneSignal.logout();
    _user = null;
    _token = null;
    _status = AuthStatus.unauthenticated;
    _loading = false;
    notifyListeners();
  }

  Future<void> forceLogout() async {
    ChatService.instance.dispose();
    await ApiService.clearToken();
    await TokenStorage.clearCredentials();
    if (!kIsWeb) await OneSignal.logout();
    _user = null;
    _token = null;
    _status = AuthStatus.unauthenticated;
    _loading = false;
    notifyListeners();
  }
}