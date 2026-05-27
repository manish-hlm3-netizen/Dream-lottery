import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/lottery_provider.dart';

class LotteryListScreen extends StatefulWidget {
  const LotteryListScreen({super.key});

  @override
  State<LotteryListScreen> createState() => _LotteryListScreenState();
}

class _LotteryListScreenState extends State<LotteryListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<LotteryProvider>().loadActiveLotteries());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => context.read<LotteryProvider>().loadActiveLotteries(),
        child: Consumer<LotteryProvider>(
          builder: (context, prov, _) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lotteries 🎰',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pick your numbers and try your luck!',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  if (prov.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(60),
                        child: CircularProgressIndicator(color: AppTheme.primaryColor),
                      ),
                    )
                  else if (prov.activeLotteries.isEmpty)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        child: const Column(
                          children: [
                            Text('🎰', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 16),
                            Text('No active lotteries',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary)),
                            SizedBox(height: 4),
                            Text('Check back soon for new draws!',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...prov.activeLotteries.map((lottery) {
                      final drawDate = DateTime.tryParse(lottery['drawDate'] ?? '') ?? DateTime.now();
                      final timeLeft = drawDate.difference(DateTime.now());
                      final jackpot = (lottery['prizes'] as List?)
                          ?.firstWhere((p) => p['match'] == lottery['pickCount'],
                              orElse: () => {'amount': 0})['amount'] ?? 0;

                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/buy-ticket', arguments: lottery),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Column(
                            children: [
                              // Header with gradient
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor.withOpacity(0.15),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lottery['name'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Pick ${lottery['pickCount']} from 1-${lottery['maxNumber']}',
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.goldGradient,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '₹${lottery['ticketPrice']}',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Body
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Jackpot',
                                            style: TextStyle(
                                              color: AppTheme.textMuted,
                                              fontSize: 11)),
                                        Text(
                                          '₹${jackpot.toString()}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.warningColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const Text('Time Left',
                                            style: TextStyle(
                                              color: AppTheme.textMuted,
                                              fontSize: 11)),
                                        Text(
                                          timeLeft.isNegative
                                              ? 'Draw soon'
                                              : '${timeLeft.inDays}d ${timeLeft.inHours % 24}h',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.infoColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryColor.withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'Play Now',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
