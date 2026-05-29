import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/lottery_provider.dart';
import '../providers/language_provider.dart';

class LotteryListScreen extends StatefulWidget {
  const LotteryListScreen({super.key});

  @override
  State<LotteryListScreen> createState() => _LotteryListScreenState();
}

class _LotteryListScreenState extends State<LotteryListScreen> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<LotteryProvider>().loadActiveLotteries());
    // Start periodic timer to refresh countdown live every second!
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatCountdown(Duration duration, LanguageProvider lang) {
    if (duration.isNegative) return lang.translate('draw_closed');
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return lang.isHindi 
          ? '${days}दि ${hours}घं ${minutes}मि ${seconds}से'
          : '${days}d ${hours}h ${minutes}m ${seconds}s';
    } else {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

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
                  Row(
                    children: [
                      Text(
                        lang.translate('lotteries'),
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lang.translate('pick_numbers_luck'),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
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
                        child: Column(
                          children: [
                            const Text('🎰', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            Text(lang.translate('no_active_lotteries'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary)),
                            const SizedBox(height: 4),
                            Text(lang.translate('check_back_soon'),
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...prov.activeLotteries.map((lottery) {
                      final drawDate = DateTime.tryParse(lottery['drawDate'] ?? '') ?? DateTime.now();
                      final timeLeft = drawDate.difference(DateTime.now());

                      // Urgency metrics (Left Ticket)
                      final int totalSold = lottery['totalTicketsSold'] ?? 0;
                      final int maxTickets = 100; // Premium draw limit of 100 tickets
                      final int ticketsLeft = (maxTickets - totalSold).clamp(0, maxTickets);
                      final double progress = (ticketsLeft / maxTickets).clamp(0.0, 1.0);

                      final jackpot = (lottery['prizes'] as List?)
                          ?.firstWhere((p) => p['match'] == lottery['pickCount'],
                              orElse: () => {'amount': 0})['amount'] ?? 0;

                      final cardTheme = AppTheme.getLotteryTheme(lottery['name']);

                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/buy-ticket', arguments: lottery),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: cardTheme.primaryColor.withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              )
                            ]
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with gradient
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      cardTheme.primaryColor.withOpacity(0.12),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            lang.isHindi 
                                                 ? '1-${lottery['maxNumber']} में से ${lottery['pickCount']} चुनें' 
                                                 : 'Pick ${lottery['pickCount']} from 1-${lottery['maxNumber']}',
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: cardTheme.gradient,
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: cardTheme.primaryColor.withOpacity(0.3),
                                            blurRadius: 10,
                                          )
                                        ],
                                      ),
                                      child: Text(
                                        '₹${lottery['ticketPrice']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Urgency Progress Bar (Left Ticket)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.confirmation_number_outlined, 
                                                size: 14, color: cardTheme.textIconColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$ticketsLeft ${lang.translate('tickets_left')}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: cardTheme.textIconColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${((1 - progress) * 100).toInt()}% ${lang.translate('filled')}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: 1 - progress,
                                        minHeight: 6,
                                        backgroundColor: AppTheme.borderColor,
                                        color: cardTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Winners Pricing matching tiers
                              if (lottery['prizes'] != null && (lottery['prizes'] as List).isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Divider(color: AppTheme.borderColor, height: 1),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(Icons.emoji_events, 
                                              color: AppTheme.warningColor.withOpacity(0.9), size: 15),
                                          const SizedBox(width: 6),
                                          Text(
                                            lang.translate('winners_pricing'),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textSecondary,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: (lottery['prizes'] as List).map<Widget>((p) {
                                          final isTop = p['match'] == lottery['pickCount'];
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              gradient: isTop ? AppTheme.goldGradient : null,
                                              color: isTop ? null : AppTheme.bgSurface,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: isTop 
                                                    ? AppTheme.warningColor.withOpacity(0.3) 
                                                    : AppTheme.borderColor,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '${p['label']}: ',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: isTop ? Colors.black87 : AppTheme.textSecondary,
                                                  ),
                                                ),
                                                Text(
                                                  '₹${p['amount']}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    color: isTop ? Colors.black87 : cardTheme.textIconColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 14),
                                    ],
                                  ),
                                ),
                              ],

                              // Footer (Jackpot & Live Countdown Timer)
                              Container(
                                decoration: const BoxDecoration(
                                  color: AppTheme.bgPrimary,
                                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(lang.translate('jackpot_pool'),
                                            style: const TextStyle(
                                                color: AppTheme.textMuted,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '₹${jackpot.toString()}',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: cardTheme.textIconColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(lang.translate('live_timer'),
                                                style: const TextStyle(
                                                    color: AppTheme.textMuted,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatCountdown(timeLeft, lang),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                            fontFamily: 'monospace',
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
