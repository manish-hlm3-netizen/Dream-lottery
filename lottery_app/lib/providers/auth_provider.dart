import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  String get userName => _user?['name'] ?? '';
  String get userEmail => _user?['email'] ?? '';
  double get walletBalance => (_user?['walletBalance'] ?? 0).toDouble();

  Future<void> checkAuth() async {
    final token = await StorageService.getToken();
    if (token != null) {
      // 1. Immediately restore cached user details if available to avoid popups or delays
      final cachedUser = await StorageService.getUserData();
      if (cachedUser != null) {
        _user = cachedUser;
        _isLoggedIn = true;
        notifyListeners();
      }

      try {
        final res = await _api.getMe();
        if (res['success'] == true) {
          _user = res['data'];
          _isLoggedIn = true;
          // Cache fresh user profile data locally
          await StorageService.saveUserData(res['data']);
          notifyListeners();
          return;
        }
      } catch (err) {
        // ONLY log out and wipe token if the backend explicitly reports unauthorized (401)
        // If it is a momentary network timeout, offline state, etc., DO NOT delete the token!
        final errStr = err.toString().toLowerCase();
        if (errStr.contains('401') || errStr.contains('unauthorized')) {
          await StorageService.deleteToken();
          await StorageService.deleteUserData();
          _user = null;
          _isLoggedIn = false;
          notifyListeners();
        }
      }
    } else {
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? referralCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        referralCode: referralCode,
      );
      if (res['success'] == true) {
        await StorageService.saveToken(res['data']['token']);
        _user = res['data']['user'];
        // Cache user details locally
        await StorageService.saveUserData(res['data']['user']);
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Registration failed';
      }
    } catch (e) {
      _error = _extractError(e);
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.login(email: email, password: password);
      if (res['success'] == true) {
        await StorageService.saveToken(res['data']['token']);
        _user = res['data']['user'];
        // Cache user details locally
        await StorageService.saveUserData(res['data']['user']);
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Login failed';
      }
    } catch (e) {
      _error = _extractError(e);
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> refreshUser() async {
    try {
      final res = await _api.getMe();
      if (res['success'] == true) {
        _user = res['data'];
        // Cache refreshed user profile data locally
        await StorageService.saveUserData(res['data']);
        notifyListeners();
      }
    } catch (_) {}
  }

  void updateBalance(double newBalance) {
    if (_user != null) {
      _user!['walletBalance'] = newBalance;
      // Update local secure cache as well
      StorageService.saveUserData(_user!);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await StorageService.clearAll();
    } catch (e) {
      debugPrint('Error during StorageService.clearAll: $e');
    }
    _user = null;
    _isLoggedIn = false;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _extractError(dynamic e) {
    if (e is Exception) {
      try {
        final dioError = e as dynamic;
        if (dioError.response?.data != null) {
          return dioError.response.data['message'] ?? 'Something went wrong';
        }
      } catch (_) {}
    }
    return 'Network error. Please try again.';
  }
}
