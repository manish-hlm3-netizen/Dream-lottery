import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  // ──────────────────────────────────────
  // Auth
  // ──────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? referralCode,
  }) async {
    final response = await _dio.post(ApiConfig.register, data: {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      if (referralCode != null && referralCode.isNotEmpty) 'referralCode': referralCode,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(ApiConfig.login, data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get(ApiConfig.me);
    return response.data;
  }

  Future<Map<String, dynamic>> getAppVersion() async {
    final response = await _dio.get(ApiConfig.appVersionCheck);
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile({String? name, String? phone}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    final response = await _dio.put(ApiConfig.profile, data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await _dio.put(ApiConfig.changePassword, data: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
    return response.data;
  }

  // ──────────────────────────────────────
  // Wallet
  // ──────────────────────────────────────

  Future<Map<String, dynamic>> getBalance() async {
    final response = await _dio.get(ApiConfig.walletBalance);
    return response.data;
  }

  Future<Map<String, dynamic>> deposit({
    required double amount,
    required String upiTransactionId,
  }) async {
    final response = await _dio.post(ApiConfig.walletDeposit, data: {
      'amount': amount,
      'upiTransactionId': upiTransactionId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> initiateDeposit({
    required double amount,
  }) async {
    final response = await _dio.post(ApiConfig.walletDepositInitiate, data: {
      'amount': amount,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> withdraw({
    required double amount,
    required String method,
    String? upiId,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? accountHolderName,
    bool? isWinnings,
  }) async {
    final response = await _dio.post(ApiConfig.walletWithdraw, data: {
      'amount': amount,
      'method': method,
      if (upiId != null) 'upiId': upiId,
      if (bankName != null) 'bankName': bankName,
      if (accountNumber != null) 'accountNumber': accountNumber,
      if (ifscCode != null) 'ifscCode': ifscCode,
      if (accountHolderName != null) 'accountHolderName': accountHolderName,
      if (isWinnings != null) 'isWinnings': isWinnings,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getTransactions({int page = 1, String? type}) async {
    final params = <String, dynamic>{'page': page};
    if (type != null) params['type'] = type;
    final response = await _dio.get(ApiConfig.walletTransactions, queryParameters: params);
    return response.data;
  }

  Future<Map<String, dynamic>> getWithdrawals() async {
    final response = await _dio.get(ApiConfig.walletWithdrawals);
    return response.data;
  }

  // ──────────────────────────────────────
  // Lotteries
  // ──────────────────────────────────────

  Future<Map<String, dynamic>> getLotteries({String status = 'active'}) async {
    final response = await _dio.get(ApiConfig.lotteries, queryParameters: {'status': status});
    return response.data;
  }

  Future<Map<String, dynamic>> getLotteryDetail(String id) async {
    final response = await _dio.get(ApiConfig.lotteryDetail(id));
    return response.data;
  }

  Future<Map<String, dynamic>> buyTicket({
    required String lotteryId,
    required List<int> selectedNumbers,
  }) async {
    final response = await _dio.post(ApiConfig.buyTicket(lotteryId), data: {
      'selectedNumbers': selectedNumbers,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getMyTickets(String lotteryId) async {
    final response = await _dio.get(ApiConfig.myTicketsForLottery(lotteryId));
    return response.data;
  }

  Future<Map<String, dynamic>> getAllMyTickets({int page = 1, String? status}) async {
    final params = <String, dynamic>{'page': page};
    if (status != null) params['status'] = status;
    final response = await _dio.get(ApiConfig.allMyTickets, queryParameters: params);
    return response.data;
  }

  Future<Map<String, dynamic>> getResults() async {
    final response = await _dio.get(ApiConfig.lotteryResults);
    return response.data;
  }

  Future<Map<String, dynamic>> getAnnouncements() async {
    final response = await _dio.get(ApiConfig.announcements);
    return response.data;
  }

  Future<Map<String, dynamic>> getUPISettings() async {
    final response = await _dio.get(ApiConfig.upiSettings);
    return response.data;
  }

  Future<Map<String, dynamic>> getReferrals() async {
    final response = await _dio.get(ApiConfig.referrals);
    return response.data;
  }

  Future<Map<String, dynamic>> getLotteryWinnersLost(String id) async {
    final response = await _dio.get(ApiConfig.lotteryWinnersLost(id));
    return response.data;
  }

  Future<Map<String, dynamic>> getRecentWinners() async {
    final response = await _dio.get(ApiConfig.recentWinners);
    return response.data;
  }

  // Support Chat
  Future<Map<String, dynamic>> getChatMessages() async {
    final response = await _dio.get(ApiConfig.chatMessages);
    return response.data;
  }

  Future<Map<String, dynamic>> sendChatMessage(String text) async {
    final response = await _dio.post(ApiConfig.chatMessages, data: {
      'text': text,
    });
    return response.data;
  }
}
