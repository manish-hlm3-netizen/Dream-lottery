import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/lottery_provider.dart';
import '../providers/language_provider.dart';


import 'wallet_screen.dart';
import 'lottery_list_screen.dart';
import 'my_tickets_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    LotteryListScreen(),
    MyTicketsScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.borderColor, width: 1),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: [
                const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
                const BottomNavigationBarItem(icon: Icon(Icons.casino_rounded), label: 'Lotteries'),
                const BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_rounded), label: 'Tickets'),
                const BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Wallet'),
                BottomNavigationBarItem(
                  icon: Stack(
                    children: [
                      const Icon(Icons.person_rounded),
                      if (auth.hasNewAnnouncement)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  late ScrollController _winnerScrollController;
  Timer? _winnerScrollTimer;



  @override
  void initState() {
    super.initState();
    _winnerScrollController = ScrollController();
    Future.microtask(() async {
      context.read<LotteryProvider>().loadActiveLotteries();
      context.read<LotteryProvider>().loadRecentWinners();
      await context.read<AuthProvider>().refreshUser();
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _winnerScrollTimer?.cancel();
    _winnerScrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _winnerScrollTimer?.cancel();
    _winnerScrollTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) return;
      if (!_winnerScrollController.hasClients) return;
      
      final maxScroll = _winnerScrollController.position.maxScrollExtent;
      if (maxScroll <= 0) return;
      
      final currentScroll = _winnerScrollController.offset;
      if (currentScroll >= maxScroll) {
        _winnerScrollController.jumpTo(0);
      } else {
        _winnerScrollController.jumpTo(currentScroll + 0.6);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await context.read<LotteryProvider>().loadActiveLotteries();
          await context.read<LotteryProvider>().loadRecentWinners();
          await context.read<AuthProvider>().refreshUser();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Row with Logo
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.isHindi ? "नमस्ते, ${auth.userName} 👋" : "Hello, ${auth.userName} 👋",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lang.translate('ready_try_luck'),
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: AppTheme.borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          image: const DecorationImage(
                            image: AssetImage('assets/images/logo.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Wallet Card
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.translate('wallet_balance'),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '₹${(auth.walletBalance + auth.referralBalance + auth.winningBalance).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _SmallWalletButton(
                              icon: Icons.add,
                              label: lang.translate('deposit'),
                              onTap: () => Navigator.pushNamed(context, '/deposit'),
                            ),
                            const SizedBox(width: 8),
                            _SmallWalletButton(
                              icon: Icons.arrow_upward,
                              label: lang.translate('withdraw'),
                              onTap: () => Navigator.pushNamed(context, '/withdraw'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Quick Actions
              Text(
                lang.translate('quick_actions'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _QuickAction(
                    icon: Icons.casino,
                    label: lang.translate('play_lottery_action'),
                    color: AppTheme.primaryColor,
                    onTap: () {
                      final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                      if (homeState != null) {
                        homeState.setState(() {
                          homeState._currentIndex = 1;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  _QuickAction(
                    icon: Icons.emoji_events,
                    label: lang.translate('view_results_action'),
                    color: AppTheme.warningColor,
                    onTap: () => Navigator.pushNamed(context, '/results'),
                  ),
                  const SizedBox(width: 10),
                  _QuickAction(
                    icon: Icons.confirmation_number,
                    label: lang.translate('my_tickets_action'),
                    color: AppTheme.successColor,
                    onTap: () => Navigator.pushNamed(context, '/my-tickets'),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Recent Winners (Modern Miniature Infinite-Scroll Ticker)
              Consumer<LotteryProvider>(
                builder: (context, lotteryProv, _) {
                  final winners = lotteryProv.recentWinners;
                  if (winners.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const _PulsingDot(),
                          const SizedBox(width: 8),
                          Text(
                            lang.isHindi ? "लाइव विजेता 🏆" : "Live Winners 🏆",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 38,
                        child: ListView.builder(
                          controller: _winnerScrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: winners.length * 100, // Endless loop repetition
                          itemBuilder: (context, idx) {
                            final w = winners[idx % winners.length];
                            final name = w['userName'] ?? 'Player';
                            final lotteryName = w['lotteryName'] ?? 'Lottery';
                            final prizeWon = w['prizeWon'] ?? 0;
                            final theme = AppTheme.getLotteryTheme(lotteryName);

                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: AppTheme.borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primaryColor.withOpacity(0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    lang.isHindi ? 'ने' : 'won',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '₹$prizeWon',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.successColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    lang.isHindi ? 'जीते' : 'in',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    lotteryName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),

              // Active Lotteries
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.translate('active_lotteries'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      lang.translate('see_all'),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Consumer<LotteryProvider>(
                builder: (context, lotteryProv, _) {
                  if (lotteryProv.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: AppTheme.primaryColor),
                      ),
                    );
                  }

                  if (lotteryProv.activeLotteries.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        children: [
                          const Text('🎰', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text(
                            lang.translate('no_active_lotteries'),
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: lotteryProv.activeLotteries.map((lottery) {
                      return _LotteryCard(lottery: lottery);
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallWalletButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SmallWalletButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LotteryCard extends StatelessWidget {
  final Map<String, dynamic> lottery;

  const _LotteryCard({required this.lottery});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final drawDate = DateTime.tryParse(lottery['drawDate'] ?? '') ?? DateTime.now();
    final timeLeft = drawDate.difference(DateTime.now());
    final cardTheme = AppTheme.getLotteryTheme(lottery['name']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: PhysicalShape(
        clipper: const TicketClipper(),
        color: AppTheme.bgCard,
        shadowColor: cardTheme.primaryColor.withOpacity(0.2),
        elevation: 7.0,
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/buy-ticket', arguments: lottery),
          child: Container(
            width: double.infinity,
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with premium gradient, safety pattern, vintage border & corner stars
                Container(
                  height: 72,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: cardTheme.gradient,
                  ),
                  child: Stack(
                    children: [
                      // Diagonal pattern
                      Positioned.fill(
                        child: CustomPaint(
                          painter: TicketPatternPainter(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                      ),
                      // Vintage inner border outline with indented corners!
                      Positioned.fill(
                        child: CustomPaint(
                          painter: TicketInnerBorderPainter(
                            color: Colors.white.withOpacity(0.25),
                            padding: 8,
                            cornerIndent: 12,
                          ),
                        ),
                      ),
                      // 4 Corner Stars inside the indented outline corners!
                      Positioned(
                        left: 11,
                        top: 11,
                        child: Icon(Icons.star, size: 8, color: Colors.white.withOpacity(0.9)),
                      ),
                      Positioned(
                        right: 11,
                        top: 11,
                        child: Icon(Icons.star, size: 8, color: Colors.white.withOpacity(0.9)),
                      ),
                      Positioned(
                        left: 11,
                        bottom: 11,
                        child: Icon(Icons.star, size: 8, color: Colors.white.withOpacity(0.9)),
                      ),
                      Positioned(
                        right: 11,
                        bottom: 11,
                        child: Icon(Icons.star, size: 8, color: Colors.white.withOpacity(0.9)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          lottery['name'] ?? 'Lottery',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lang.isHindi 
                                         ? '1-${lottery['maxNumber']} में से ${lottery['pickCount']} चुनें' 
                                         : 'Pick ${lottery['pickCount']} from 1-${lottery['maxNumber']}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                              ),
                              child: Text(
                                '₹${lottery['ticketPrice']}',
                                style: TextStyle(
                                  color: cardTheme.primaryColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Row of circular perforation punches (like the reference image!)
                Container(
                  height: 10,
                  width: double.infinity,
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const double holeRadius = 3.5;
                      const double spacing = 6.0;
                      final count = (constraints.maxWidth / (holeRadius * 2 + spacing)).floor();
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          count,
                          (index) => Container(
                            width: holeRadius * 2,
                            height: holeRadius * 2,
                            decoration: const BoxDecoration(
                              color: AppTheme.bgPrimary, // cuts through card to back color!
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Card Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _InfoChip(
                            icon: Icons.confirmation_number_outlined,
                            iconColor: cardTheme.textIconColor,
                            text: '${(lottery['totalTicketsSold'] ?? 0) * (lottery['ticketsSoldMultiplier'] ?? 67)} ${lang.translate('tickets_sold')}',
                          ),
                          _InfoChip(
                            icon: Icons.timer_outlined,
                            iconColor: cardTheme.textIconColor,
                            text: timeLeft.isNegative
                                ? lang.translate('draw_soon')
                                : (lang.isHindi 
                                    ? '${timeLeft.inDays} दिन ${timeLeft.inHours % 24} घंटे' 
                                    : '${timeLeft.inDays}d ${timeLeft.inHours % 24}h left'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: AppTheme.borderColor, height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lang.translate('ready_try_luck'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: cardTheme.gradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: cardTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Text(
                              lang.translate('play_now'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const _InfoChip({
    required this.icon, 
    required this.text,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor ?? AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent,
              blurRadius: 4,
              spreadRadius: 1,
            )
          ],
        ),
      ),
    );
  }
}
