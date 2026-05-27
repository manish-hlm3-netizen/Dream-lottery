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
      try {
        final res = await _api.getMe();
        if (res['success'] == true) {
          _user = res['data'];
          _isLoggedIn = true;
          notifyListeners();
          return;
        }
      } catch (_) {
        await StorageService.deleteToken();
      }
    }
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
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
      );
      if (res['success'] == true) {
        await StorageService.saveToken(res['data']['token']);
        _user = res['data']['user'];
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
        notifyListeners();
      }
    } catch (_) {}
  }

  void updateBalance(double newBalance) {
    if (_user != null) {
      _user!['walletBalance'] = newBalance;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await StorageService.clearAll();
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
