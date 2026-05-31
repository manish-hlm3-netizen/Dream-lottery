import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );
  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: _userKey, value: jsonEncode(userData));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: _userKey);
    if (data != null) {
      try {
        return jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  static Future<void> deleteUserData() async {
    await _storage.delete(key: _userKey);
  }

  static const _pinKey = 'security_pin';

  static Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  static Future<String?> getPin() async {
    return await _storage.read(key: _pinKey);
  }

  static Future<void> deletePin() async {
    await _storage.delete(key: _pinKey);
  }

  static Future<void> clearAll() async {
    // Retain PIN even if clearAll is called during session clear, except if specifically logging out or reset.
    // Wait, to keep PIN active even if user session refreshes, but clear it on complete logout.
    // If they click "Logout", secure tokens are cleared. Wiping the PIN on logout is good so next login is fresh.
    try {
      await _storage.deleteAll();
    } catch (e) {
      try {
        await _storage.delete(key: _tokenKey);
        await _storage.delete(key: _userKey);
        await _storage.delete(key: _pinKey);
      } catch (_) {}
    }
  }
}
