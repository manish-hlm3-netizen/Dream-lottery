import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/lottery_provider.dart';
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
      ],
      child: MaterialApp(
        title: 'Lottery App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
          '/deposit': (context) => const DepositScreen(),
          '/withdraw': (context) => const WithdrawScreen(),
          '/results': (context) => const ResultsScreen(),
          '/my-tickets': (context) => const MyTicketsScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/buy-ticket') {
            final lottery = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => BuyTicketScreen(lottery: lottery),
            );
          }
          return null;
        },
      ),
    );
  }
}
