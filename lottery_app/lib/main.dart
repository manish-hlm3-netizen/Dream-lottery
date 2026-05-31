import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/lottery_provider.dart';
import 'providers/language_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/deposit_screen.dart';
import 'screens/withdraw_screen.dart';
import 'screens/buy_ticket_screen.dart';
import 'screens/results_screen.dart';
import 'screens/my_tickets_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/recent_winners_screen.dart';
import 'screens/announcements_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/referrals_screen.dart';
import 'screens/lottery_participants_screen.dart';
import 'screens/support_chat_screen.dart';
import 'screens/security_pin_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LotteryApp());
}

class LotteryApp extends StatelessWidget {
  const LotteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LotteryProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: MaterialApp(
        title: 'Dream Lottery',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
          '/deposit': (context) => const DepositScreen(),
          '/withdraw': (context) => const WithdrawScreen(),
          '/results': (context) => const ResultsScreen(),
          '/recent-winners': (context) => const RecentWinnersScreen(),
          '/my-tickets': (context) => const MyTicketsScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/announcements': (context) => const AnnouncementsScreen(),
          '/wallet': (context) => const WalletScreen(),
          '/referrals': (context) => const ReferralsScreen(),
          '/support-chat': (context) => const SupportChatScreen(),
          '/security-pin': (context) => const SecurityPinScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/buy-ticket') {
            final lottery = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => BuyTicketScreen(lottery: lottery),
            );
          }
          if (settings.name == '/lottery-participants') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => LotteryParticipantsScreen(
                lotteryId: args['lotteryId'],
                lotteryName: args['lotteryName'],
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
