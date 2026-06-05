import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../providers/lottery_provider.dart';
import '../providers/language_provider.dart';

class RecentWinnersScreen extends StatefulWidget {
  const RecentWinnersScreen({super.key});

  @override
  State<RecentWinnersScreen> createState() => _RecentWinnersScreenState();
}

class _RecentWinnersScreenState extends State<RecentWinnersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<LotteryProvider>().loadRecentWinners();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final lotteryProv = Provider.of<LotteryProvider>(context);
    final winners = lotteryProv.recentWinners;

    // Dynamically build the tab categories from the current list of winners
    final uniqueLotteries = ['All'];
    for (var w in winners) {
      final name = w['lotteryName'] as String?;
      if (name != null && !uniqueLotteries.contains(name)) {
        uniqueLotteries.add(name);
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text(lang.isHindi ? 'विजेता गैलरी 🏆' : 'Winner Gallery 🏆'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      ),
      body: winners.isEmpty
          ? _buildEmptyState(lang)
          : DefaultTabController(
              length: uniqueLotteries.length,
              child: Column(
                children: [
                  // Sleek Custom TabBar with white pill design
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 40,
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppTheme.textSecondary,
                      indicator: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      tabs: uniqueLotteries.map((name) {
                        return Tab(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              name == 'All'
                                  ? (lang.isHindi ? 'सभी' : 'All')
                                  : name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Tab View
                  Expanded(
                    child: TabBarView(
                      children: uniqueLotteries.map((filterName) {
                        // Filter the winners dynamically based on the active tab
                        final filteredWinners = filterName == 'All'
                            ? winners
                            : winners.where((w) => w['lotteryName'] == filterName).toList();

                        if (filteredWinners.isEmpty) {
                          return _buildEmptyState(lang);
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: filteredWinners.length,
                          itemBuilder: (context, idx) {
                            final w = filteredWinners[idx];
                            return _buildWinnerCard(context, w, lang);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(LanguageProvider lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👑', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            lang.isHindi ? 'कोई विजेता रिकॉर्ड नहीं मिला' : 'No winner records found',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerCard(BuildContext context, Map<String, dynamic> w, LanguageProvider lang) {
    final name = w['userName'] ?? 'Player';
    final lotteryName = w['lotteryName'] ?? 'Lottery';
    final prizeWon = w['prizeWon'] ?? 0;
    
    // Parse Draw Date
    DateTime drawDate = DateTime.now();
    if (w['drawDate'] != null) {
      drawDate = DateTime.tryParse(w['drawDate']) ?? DateTime.now();
    }
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(drawDate);

    final selected = w['selectedNumbers'] as List<dynamic>? ?? [];
    final matched = w['matchedNumbers'] as List<dynamic>? ?? [];
    final theme = AppTheme.getLotteryTheme(lotteryName);
    final rank = w['rank'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Column(
          children: [
            // Winner Card Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              color: theme.primaryColor.withOpacity(0.06),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.warningColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (rank > 0) ...[
                                Text(
                                  rank == 1 ? '👑 ' : rank == 2 ? '🥈 ' : rank == 3 ? '🥉 ' : '🏆 ',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            rank > 0
                                ? (lang.isHindi ? 'रैंक $rank विजेता' : 'Rank $rank Winner')
                                : (lang.isHindi ? 'भाग्यशाली विजेता' : 'Lucky Winner'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      lotteryName,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Body with rich information
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prize highlight block
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.isHindi ? 'जीती गई राशि' : 'Amount Won',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${prizeWon.toString()}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.successColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.successColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          rank == 1
                              ? (lang.isHindi ? 'जैकपॉट! 🎉' : 'JACKPOT! 🎉')
                              : rank == 2
                                  ? (lang.isHindi ? 'दूसरा पुरस्कार! 🥈' : '2ND PRIZE! 🥈')
                                  : rank == 3
                                      ? (lang.isHindi ? 'तीसरा पुरस्कार! 🥉' : '3RD PRIZE! 🥉')
                                      : (lang.isHindi ? 'विजेता! 🏆' : 'WINNER! 🏆'),
                          style: const TextStyle(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.borderColor, height: 1),
                  const SizedBox(height: 16),

                  // Selected Numbers (Lottery Balls Layout)
                  Text(
                    lang.isHindi ? 'टिकट नंबर (मैच किए गए नंबर हाइलाइट हैं):' : 'Ticket Numbers (Highlights are Matched):',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: selected.map((number) {
                      final isMatched = matched.contains(number);
                      return _buildNumberBall(number, isMatched, theme.primaryColor);
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 18),
                  const Divider(color: AppTheme.borderColor, height: 1),
                  const SizedBox(height: 14),

                  // Draw Date row
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${lang.isHindi ? "ड्रॉ की तारीख:" : "Draw Date:"} $formattedDate',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
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
  }

  Widget _buildNumberBall(int number, bool isMatched, Color themeColor) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isMatched
            ? LinearGradient(
                colors: [themeColor.withOpacity(0.85), themeColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: (isMatched ? themeColor : Colors.black).withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(
          color: isMatched ? Colors.transparent : AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: TextStyle(
            color: isMatched ? Colors.white : AppTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
