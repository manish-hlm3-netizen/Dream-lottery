class ApiConfig {
  static const String baseUrl = 'https://lottery-api-vgk0.onrender.com/api';

  // Current client app version
  static const String appVersion = '1.4.13';

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String profile = '/auth/profile';
  static const String changePassword = '/auth/change-password';
  static const String appVersionCheck = '/auth/app-version';

  // Wallet endpoints
  static const String walletBalance = '/wallet/balance';
  static const String walletDeposit = '/wallet/deposit';
  static const String walletDepositInitiate = '/wallet/deposit/initiate';
  static const String walletWithdraw = '/wallet/withdraw';
  static const String walletTransactions = '/wallet/transactions';
  static const String walletWithdrawals = '/wallet/withdrawals';

  // Lottery endpoints
  static const String lotteries = '/lotteries';
  static const String lotteryResults = '/lotteries/results';
  static const String recentWinners = '/lotteries/recent-winners';
  static String lotteryDetail(String id) => '/lotteries/$id';
  static String buyTicket(String id) => '/lotteries/$id/buy';
  static String myTicketsForLottery(String id) => '/lotteries/$id/my-tickets';
  static String lotteryWinnersLost(String id) => '/lotteries/$id/winners-lost';

  // Tickets
  static const String allMyTickets = '/tickets/my-tickets';

  // Announcements
  static const String announcements = '/auth/announcements';

  // Settings
  static const String upiSettings = '/auth/settings/upi';

  // Referrals
  static const String referrals = '/auth/referrals';

  // Support Chat
  static const String chatMessages = '/chat';
}
