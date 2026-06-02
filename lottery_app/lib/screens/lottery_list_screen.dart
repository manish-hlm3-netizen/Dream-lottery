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
                      final int maxTickets = 100000; // Total ticket cap per lottery
                      final int ticketsLeft = (maxTickets - totalSold).clamp(0, maxTickets);
                      final double progress = (totalSold / maxTickets).clamp(0.0, 1.0);

                      final jackpot = (lottery['prizes'] as List?)
                          ?.firstWhere((p) => p['match'] == lottery['pickCount'],
                              orElse: () => {'amount': 0})['amount'] ?? 0;

                      final cardTheme = AppTheme.getLotteryTheme(lottery['name']);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
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
                                    height: 85,
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
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                                                            lottery['name'] ?? '',
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: const TextStyle(
                                                              fontSize: 18,
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
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                                    fontSize: 15,
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

                                  // Urgency Progress Bar (Left Tickets)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.confirmation_number_outlined,
                                                  size: 13,
                                                  color: ticketsLeft < 5000
                                                      ? Colors.red.shade400
                                                      : AppTheme.textMuted,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$totalSold ${lang.translate('tickets_sold')}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: ticketsLeft < 5000
                                                        ? Colors.red.shade400
                                                        : AppTheme.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '${(progress * 100).toInt()}% ${lang.translate('filled')}',
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
                                            value: progress,
                                            minHeight: 6,
                                            backgroundColor: AppTheme.borderColor,
                                            color: ticketsLeft < 5000
                                                ? Colors.red.shade400
                                                : cardTheme.primaryColor,
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
                                                  color: isTop ? null : cardTheme.primaryColor.withOpacity(0.05),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: isTop 
                                                        ? AppTheme.warningColor.withOpacity(0.4) 
                                                        : cardTheme.primaryColor.withOpacity(0.15),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (isTop) ...[
                                                      const Icon(Icons.stars, color: Colors.black87, size: 12),
                                                      const SizedBox(width: 4),
                                                    ],
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
                                          const SizedBox(height: 16),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // Footer stub with framed barcode coupon layout matching reference image!
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0F172A),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                lang.translate('jackpot_pool').toUpperCase(),
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.6),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '₹${jackpot.toString()}',
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFFFBBF24), // Gold Pool
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration: const BoxDecoration(
                                                      color: Color(0xFF34D399), // Fluorescent Green
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    _formatCountdown(timeLeft, lang),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w800,
                                                      color: Color(0xFF34D399), // Fluorescent Digital Green
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Framed Barcode Box with corner stars from the reference image!
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.04),
                                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                left: 2,
                                                top: 2,
                                                child: Icon(Icons.star, size: 6, color: Colors.white.withOpacity(0.5)),
                                              ),
                                              Positioned(
                                                right: 2,
                                                top: 2,
                                                child: Icon(Icons.star, size: 6, color: Colors.white.withOpacity(0.5)),
                                              ),
                                              Positioned(
                                                left: 2,
                                                bottom: 2,
                                                child: Icon(Icons.star, size: 6, color: Colors.white.withOpacity(0.5)),
                                              ),
                                              Positioned(
                                                right: 2,
                                                bottom: 2,
                                                child: Icon(Icons.star, size: 6, color: Colors.white.withOpacity(0.5)),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(6),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    // Barcode lines
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: List.generate(14, (idx) {
                                                        return Container(
                                                          width: idx % 3 == 0 ? 3 : 1.5,
                                                          height: 18,
                                                          margin: const EdgeInsets.only(right: 1.5),
                                                          color: Colors.white.withOpacity(0.85),
                                                        );
                                                      }),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'TKT-${lottery['_id'].toString().substring(0, 6).toUpperCase()}',
                                                      style: TextStyle(
                                                        color: Colors.white.withOpacity(0.5),
                                                        fontSize: 8,
                                                        fontWeight: FontWeight.w700,
                                                        fontFamily: 'monospace',
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
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
