import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    } else {
      return 'http://localhost:5000/api';
    }
  }


  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String profile = '/auth/profile';

  // Wallet endpoints
  static const String walletBalance = '/wallet/balance';
  static const String walletDeposit = '/wallet/deposit';
  static const String walletWithdraw = '/wallet/withdraw';
  static const String walletTransactions = '/wallet/transactions';
  static const String walletWithdrawals = '/wallet/withdrawals';

  // Lottery endpoints
  static const String lotteries = '/lotteries';
  static const String lotteryResults = '/lotteries/results';
  static String lotteryDetail(String id) => '/lotteries/$id';
  static String buyTicket(String id) => '/lotteries/$id/buy';
  static String myTicketsForLottery(String id) => '/lotteries/$id/my-tickets';

  // Tickets
  static const String allMyTickets = '/tickets/my-tickets';
}
