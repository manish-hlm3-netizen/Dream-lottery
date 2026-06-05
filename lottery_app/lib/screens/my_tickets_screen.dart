import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/lottery_provider.dart';
import '../providers/language_provider.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => context.read<LotteryProvider>().loadMyTickets());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final lang = Provider.of<LanguageProvider>(context);

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!canPop) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Tickets 🎫',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
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
                ),
                const SizedBox(height: 16),
              ],
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primaryColor,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textMuted,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerHeight: 0,
                  onTap: (index) {
                    final statuses = [null, 'won', 'lost'];
                    context.read<LotteryProvider>().loadMyTickets(status: statuses[index]);
                  },
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Won'),
                    Tab(text: 'Lost'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Consumer<LotteryProvider>(
            builder: (context, prov, _) {
              if (prov.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                );
              }

              if (prov.myTickets.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🎫', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('No tickets yet',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => prov.loadMyTickets(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: prov.myTickets.length,
                  itemBuilder: (context, index) {
                    final ticket = prov.myTickets[index];
                    final lottery = ticket['lotteryId'];
                    final status = ticket['status'] ?? 'active';
                    final numbers = (ticket['selectedNumbers'] as List?)?.cast<int>() ?? [];
                    final matched = (ticket['matchedNumbers'] as List?)?.cast<int>() ?? [];
                    final prizeWon = ticket['prizeWon'] ?? 0;

                    final String ticketId = ticket['_id']?.toString() ?? '12345678';
                    final String serial = ticketId.length >= 8
                        ? ticketId.substring(0, 8).toUpperCase()
                        : ticketId.toUpperCase();

                    Color statusColor;
                    IconData statusIcon;
                    String statusLabel;
                    LinearGradient headerGradient;

                    switch (status) {
                      case 'won':
                        statusColor = AppTheme.successColor;
                        statusIcon = Icons.emoji_events_rounded;
                        statusLabel = lang.isHindi ? 'विजेता' : 'WON';
                        headerGradient = const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        );
                        break;
                      case 'lost':
                        statusColor = AppTheme.dangerColor;
                        statusIcon = Icons.cancel_rounded;
                        statusLabel = lang.isHindi ? 'खोया' : 'LOST';
                        headerGradient = const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        );
                        break;
                      default:
                        statusColor = AppTheme.infoColor;
                        statusIcon = Icons.schedule_rounded;
                        statusLabel = lang.isHindi ? 'सक्रिय' : 'ACTIVE';
                        headerGradient = const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        );
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Stack(
                        children: [
                          // 1. Shadowed and Clipped Card Body
                          PhysicalShape(
                            clipper: MyTicketsClipper(),
                            color: AppTheme.bgCard,
                            shadowColor: Colors.black.withOpacity(0.06),
                            elevation: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row (Name + Status Badge)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          lottery?['name'] ?? 'Dream Lottery',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            color: AppTheme.textPrimary,
                                            letterSpacing: 0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          gradient: headerGradient,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: statusColor.withOpacity(0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(statusIcon, size: 12, color: Colors.white),
                                            const SizedBox(width: 4),
                                            Text(
                                              statusLabel,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Draw date + Price + Matches
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_month_rounded, size: 14, color: AppTheme.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${lang.isHindi ? "ड्रॉ" : "Draw"}: ${_formatDate(lottery?['drawDate'])}',
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.local_activity_rounded, size: 14, color: AppTheme.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            '₹${lottery?['ticketPrice'] ?? 50}',
                                            style: const TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (status != 'active')
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (status == 'won' ? AppTheme.successColor : AppTheme.textSecondary).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${lang.isHindi ? "मैच" : "Match"}: ${matched.length}/${numbers.length}',
                                            style: TextStyle(
                                              color: status == 'won' ? AppTheme.successColor : AppTheme.textSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // Tear-off dashed divider at the notch line (50%)
                                  Row(
                                    children: List.generate(
                                      40,
                                      (index) => Expanded(
                                        child: Container(
                                          height: 1.5,
                                          color: index % 2 == 0
                                              ? Colors.transparent
                                              : AppTheme.textMuted.withOpacity(0.3),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Selected numbers / Balls Section
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: numbers.map((number) {
                                      final isMatched = matched.contains(number);
                                      return Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          gradient: isMatched
                                              ? const LinearGradient(
                                                  colors: [Color(0xFF10B981), Color(0xFF047857)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : const LinearGradient(
                                                  colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: isMatched
                                                  ? AppTheme.successColor.withOpacity(0.3)
                                                  : Colors.black.withOpacity(0.06),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                          border: isMatched
                                              ? null
                                              : Border.all(color: AppTheme.textMuted.withOpacity(0.3)),
                                        ),
                                        child: Center(
                                          child: Text(
                                            number.toString().padLeft(2, '0'),
                                            style: TextStyle(
                                              color: isMatched
                                                  ? Colors.white
                                                  : AppTheme.textPrimary,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 14),

                                  // Tear-off dashed divider
                                  Row(
                                    children: List.generate(
                                      40,
                                      (index) => Expanded(
                                        child: Container(
                                          height: 1.5,
                                          color: index % 2 == 0
                                              ? Colors.transparent
                                              : AppTheme.textMuted.withOpacity(0.3),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Barcode & Purchase Info Footer
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'SERIAL: TKT-$serial',
                                              style: const TextStyle(
                                                color: AppTheme.textPrimary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                fontFamily: 'monospace',
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '🎟️ ${lang.isHindi ? "खरीदा गया" : "Purchased"}: ${_formatDate(ticket['purchasedAt'])}',
                                              style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (prizeWon > 0) ...[
                                              const SizedBox(height: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  gradient: AppTheme.goldGradient,
                                                  borderRadius: BorderRadius.circular(6),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppTheme.warningColor.withOpacity(0.2),
                                                      blurRadius: 4,
                                                    )
                                                  ]
                                                ),
                                                child: Text(
                                                  '🏆 ${lang.isHindi ? "जीता" : "Won"} ₹$prizeWon',
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // High-fidelity Barcode (Always visible)
                                      Column(
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: List.generate(
                                              20,
                                              (idx) => Container(
                                                width: idx % 3 == 0 ? 3.0 : (idx % 5 == 0 ? 1.0 : 1.8),
                                                height: 26,
                                                margin: const EdgeInsets.only(right: 1.5),
                                                color: AppTheme.textPrimary.withOpacity(0.85),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          const Text(
                                            'SCAN ENTRY',
                                            style: TextStyle(
                                              color: AppTheme.textMuted,
                                              fontSize: 7.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // Compact Action TextButton for Won/Lost state
                                  if (status == 'won' || status == 'lost') ...[
                                    const SizedBox(height: 8),
                                    const Divider(color: AppTheme.borderColor, height: 1),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 28,
                                      width: double.infinity,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          if (lottery != null && lottery['_id'] != null) {
                                            Navigator.pushNamed(
                                              context,
                                              '/lottery-participants',
                                              arguments: {
                                                'lotteryId': lottery['_id'],
                                                'lotteryName': lottery['name'] ?? 'Result',
                                              },
                                            );
                                          }
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          foregroundColor: AppTheme.primaryColor,
                                        ),
                                        icon: const Icon(Icons.emoji_events, size: 14),
                                        label: Text(
                                          Provider.of<LanguageProvider>(context, listen: false)
                                              .translate('view_winners_results'),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // 2. Custom Painted Border to follow the clipped shape perfectly
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: TicketBorderPainter(
                                  color: status == 'won'
                                      ? AppTheme.successColor.withOpacity(0.8)
                                      : AppTheme.textMuted.withOpacity(0.5),
                                  strokeWidth: status == 'won' ? 3.0 : 2.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );

    if (canPop) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Tickets 🎫'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppTheme.borderColor),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/logo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(child: content),
      );
    }

    return Material(
      color: Colors.transparent,
      child: SafeArea(child: content),
    );
  }
}

// Custom Clipper for premium physical ticket cutout notches centered perfectly
class MyTicketsClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    // Left notch centered perfectly
    path.lineTo(0, size.height * 0.50 - 6);
    path.arcToPoint(
      Offset(0, size.height * 0.50 + 6),
      radius: const Radius.circular(6),
      clockwise: true,
    );
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    // Right notch centered perfectly
    path.lineTo(size.width, size.height * 0.50 + 6);
    path.arcToPoint(
      Offset(size.width, size.height * 0.50 - 6),
      radius: const Radius.circular(6),
      clockwise: true,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Custom Painter to draw a clean border on the ticket shape
class TicketBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const TicketBorderPainter({required this.color, this.strokeWidth = 2.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path();
    path.lineTo(0, 0);
    // Left notch
    path.lineTo(0, size.height * 0.50 - 6);
    path.arcToPoint(
      Offset(0, size.height * 0.50 + 6),
      radius: const Radius.circular(6),
      clockwise: true,
    );
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    // Right notch
    path.lineTo(size.width, size.height * 0.50 + 6);
    path.arcToPoint(
      Offset(size.width, size.height * 0.50 - 6),
      radius: const Radius.circular(6),
      clockwise: true,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TicketBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
