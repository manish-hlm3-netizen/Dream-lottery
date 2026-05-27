import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/lottery_provider.dart';

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
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Tickets 🎫',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
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
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: status == 'won'
                                ? AppTheme.successColor.withOpacity(0.3)
                                : AppTheme.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    lottery?['name'] ?? 'Lottery',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 15),
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
                                      Icon(statusIcon, size: 14, color: statusColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Numbers
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: numbers.map((num) {
                                final isMatched = matched.contains(num);
                                return Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: isMatched
                                        ? AppTheme.successGradient
                                        : null,
                                    color: isMatched ? null : AppTheme.bgSurface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isMatched
                                        ? null
                                        : Border.all(color: AppTheme.borderColor),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$num',
                                      style: TextStyle(
                                        color: isMatched
                                            ? Colors.white
                                            : AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            if (prizeWon > 0) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.goldGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '🏆 Won ₹$prizeWon',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
