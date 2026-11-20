import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'auth_email';
  static const String _passwordKey = 'auth_password';

  static Future<String?> readToken() async {
    try {
      final token = await _secure.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> writeToken(String token) async {
    try {
      await _secure.write(key: _tokenKey, value: token);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> deleteToken() async {
    try {
      await _secure.delete(key: _tokenKey);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<void> saveCredentials(String email, String password) async {
    try {
      await _secure.write(key: _emailKey, value: email);
      await _secure.write(key: _passwordKey, value: password);
    } catch (_) {}
  }

  static Future<String?> readEmail() async {
    try {
      return await _secure.read(key: _emailKey);
    } catch (_) {}
    return null;
  }

  static Future<String?> readPassword() async {
    try {
      return await _secure.read(key: _passwordKey);
    } catch (_) {}
    return null;
  }

  static Future<void> clearCredentials() async {
    try {
      await _secure.delete(key: _emailKey);
      await _secure.delete(key: _passwordKey);
    } catch (_) {}
  }
}