import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LotteryProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<dynamic> _activeLotteries = [];
  List<dynamic> _results = [];
  List<dynamic> _myTickets = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get activeLotteries => _activeLotteries;
  List<dynamic> get results => _results;
  List<dynamic> get myTickets => _myTickets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadActiveLotteries() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.getLotteries(status: 'active');
      if (res['success'] == true) {
        _activeLotteries = res['data']['lotteries'] ?? [];
      }
    } catch (e) {
      _error = 'Failed to load lotteries';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadResults() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.getResults();
      if (res['success'] == true) {
        _results = res['data']['lotteries'] ?? [];
      }
    } catch (e) {
      _error = 'Failed to load results';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMyTickets({String? status}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.getAllMyTickets(status: status);
      if (res['success'] == true) {
        _myTickets = res['data']['tickets'] ?? [];
      }
    } catch (e) {
      _error = 'Failed to load tickets';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getLotteryDetail(String id) async {
    try {
      final res = await _api.getLotteryDetail(id);
      if (res['success'] == true) {
        return res['data']['lottery'];
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> buyTicket({
    required String lotteryId,
    required List<int> numbers,
  }) async {
    try {
      final res = await _api.buyTicket(
        lotteryId: lotteryId,
        selectedNumbers: numbers,
      );
      return res;
    } catch (e) {
      final dioError = e as dynamic;
      if (dioError.response?.data != null) {
        return dioError.response.data as Map<String, dynamic>;
      }
      return {'success': false, 'message': 'Network error'};
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
