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
                const Text(
                  'My Tickets 🎫',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
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
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ClipPath(
                        clipper: MyTicketsClipper(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            border: Border.all(
                              color: status == 'won'
                                  ? AppTheme.successColor.withOpacity(0.4)
                                  : AppTheme.borderColor,
                              width: status == 'won' ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      lottery?['name'] ?? 'Dream Lottery',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusIcon, size: 13, color: statusColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Dashed divider
                              Row(
                                children: List.generate(
                                  28,
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
                              const SizedBox(height: 16),

                              // Dynamic 3D Lottery Balls for numbers
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: numbers.map((number) {
                                  final isMatched = matched.contains(number);
                                  return Container(
                                    width: 42,
                                    height: 42,
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
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
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
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),

                              // Dashed divider
                              Row(
                                children: List.generate(
                                  28,
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
                              const SizedBox(height: 14),

                              // Barcode & Serial Footer
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (prizeWon > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.goldGradient,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.warningColor.withOpacity(0.3),
                                            blurRadius: 8,
                                          )
                                        ]
                                      ),
                                      child: Text(
                                        '🏆 Won ₹$prizeWon',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  else
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SERIAL: TKT-${ticket['_id'].toString().substring(0, 8).toUpperCase()}',
                                          style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'DREAM LOTTERY PREMIUM TICKET',
                                          style: TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),

                                  // Visual Barcode
                                  Row(
                                    children: [
                                      ...List.generate(
                                        12,
                                        (idx) => Container(
                                          width: idx % 3 == 0 ? 3 : 1.5,
                                          height: 24,
                                          margin: const EdgeInsets.only(right: 2),
                                          color: AppTheme.textSecondary.withOpacity(0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (status == 'won' || status == 'lost') ...[
                                const SizedBox(height: 14),
                                const Divider(color: AppTheme.borderColor, height: 1),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
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
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.emoji_events, size: 16),
                                    label: Text(
                                      Provider.of<LanguageProvider>(context, listen: false)
                                          .translate('view_winners_results'),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
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
        appBar: AppBar(title: const Text('My Tickets 🎫')),
        body: SafeArea(child: content),
      );
    }

    return Material(
      color: Colors.transparent,
      child: SafeArea(child: content),
    );
  }
}

// Custom Clipper for premium physical ticket cutout notches
class MyTicketsClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    // Left notch
    path.lineTo(0, size.height * 0.40 - 8);
    path.arcToPoint(
      Offset(0, size.height * 0.40 + 8),
      radius: const Radius.circular(8),
      clockwise: true,
    );
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    // Right notch
    path.lineTo(size.width, size.height * 0.40 + 8);
    path.arcToPoint(
      Offset(size.width, size.height * 0.40 - 8),
      radius: const Radius.circular(8),
      clockwise: true,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
