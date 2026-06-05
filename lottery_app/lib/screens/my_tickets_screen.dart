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

                    Color statusColor;
                    IconData statusIcon;
                    switch (status) {
                      case 'won':
                        statusColor = AppTheme.successColor;
                        statusIcon = Icons.emoji_events;
                        break;
                      case 'lost':
                        statusColor = AppTheme.dangerColor;
                        statusIcon = Icons.close;
                        break;
                      default:
                        statusColor = AppTheme.infoColor;
                        statusIcon = Icons.hourglass_empty;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ClipPath(
                        clipper: MyTicketsClipper(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            border: Border.all(
                              color: status == 'won'
                                  ? AppTheme.successColor.withOpacity(0.7)
                                  : AppTheme.textMuted.withOpacity(0.5),
                              width: status == 'won' ? 3.0 : 2.0,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.01),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Title + Status Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      lottery?['name'] ?? 'Dream Lottery',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: AppTheme.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusIcon, size: 11, color: statusColor),
                                        const SizedBox(width: 3),
                                        Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // 2. Ticket Metadata (Draw Date + Price + Matches)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '📅 Draw: ${_formatDate(lottery?['drawDate'])}',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '💰 Price: ₹${lottery?['ticketPrice'] ?? 50}',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (status != 'active')
                                    Text(
                                      '🎯 Match: ${matched.length}/${numbers.length}',
                                      style: TextStyle(
                                        color: status == 'won' ? AppTheme.successColor : AppTheme.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Tear-off dashed divider at 50% notch line
                              Row(
                                children: List.generate(
                                  36,
                                  (index) => Expanded(
                                    child: Container(
                                      height: 1,
                                      color: index % 2 == 0
                                          ? Colors.transparent
                                          : AppTheme.borderColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // 3. Compact Dynamic 3D Lottery Balls
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: numbers.map((number) {
                                  final isMatched = matched.contains(number);
                                  return Container(
                                    width: 32,
                                    height: 32,
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
                                              ? AppTheme.successColor.withOpacity(0.2)
                                              : Colors.black.withOpacity(0.04),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1.5),
                                        ),
                                      ],
                                      border: isMatched
                                          ? null
                                          : Border.all(color: AppTheme.borderColor),
                                    ),
                                    child: Center(
                                      child: Text(
                                        number.toString().padLeft(2, '0'),
                                        style: TextStyle(
                                          color: isMatched
                                              ? Colors.white
                                              : AppTheme.textPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 10),

                              // Tear-off dashed divider
                              Row(
                                children: List.generate(
                                  36,
                                  (index) => Expanded(
                                    child: Container(
                                      height: 1,
                                      color: index % 2 == 0
                                          ? Colors.transparent
                                          : AppTheme.borderColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // 4. Barcode & Purchase Info Footer
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (prizeWon > 0)
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
                                              '🏆 Won ₹$prizeWon',
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 12,
                                              ),
                                            ),
                                          )
                                        else ...[
                                          Text(
                                            'SERIAL: TKT-${ticket['_id'].toString().substring(0, 8).toUpperCase()}',
                                            style: const TextStyle(
                                              color: AppTheme.textMuted,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            '🎟️ Purchased: ${_formatDate(ticket['purchasedAt'])}',
                                            style: const TextStyle(
                                              color: AppTheme.textMuted,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Visual Barcode (Sleek Compact Version)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ...List.generate(
                                        10,
                                        (idx) => Container(
                                          width: idx % 3 == 0 ? 2.5 : 1.2,
                                          height: 18,
                                          margin: const EdgeInsets.only(right: 1.5),
                                          color: AppTheme.textSecondary.withOpacity(0.35),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // Compact Action TextButton for Won/Lost state
                              if (status == 'won' || status == 'lost') ...[
                                const SizedBox(height: 6),
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
