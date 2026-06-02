import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../providers/lottery_provider.dart';
import '../providers/language_provider.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<LotteryProvider>().loadResults());
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text('${lang.translate('results')} 🏆'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      ),
      body: Consumer<LotteryProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (prov.results.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 54)),
                  const SizedBox(height: 16),
                  Text(
                    lang.translate('no_winners'),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => prov.loadResults(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: prov.results.length,
              itemBuilder: (context, index) {
                final lottery = prov.results[index];
                return _ResultCard(lottery: lottery, lang: lang);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatefulWidget {
  final Map<String, dynamic> lottery;
  final LanguageProvider lang;

  const _ResultCard({required this.lottery, required this.lang});

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  bool _isExpanded = false;

  String _formatRank1Winner(String? winnerName, LanguageProvider lang) {
    if (winnerName == null || winnerName.trim().isEmpty || winnerName == 'No Winner' || winnerName == 'कोई विजेता नहीं') {
      return lang.isHindi ? 'कोई विजेता नहीं' : 'No Winner';
    }
    final names = winnerName.split(', ').map((n) => n.trim()).where((n) => n.isNotEmpty).toList();
    if (names.isEmpty) {
      return lang.isHindi ? 'कोई विजेता नहीं' : 'No Winner';
    }
    if (names.length > 1) {
      final others = names.length - 1;
      return lang.isHindi ? '${names[0]} + $others अन्य' : '${names[0]} + $others others';
    }
    return names[0];
  }

  int _getPrizeForRank(int rank, List<dynamic>? prizes) {
    if (prizes == null) return 0;
    int targetMatch = 4;
    if (rank == 1) targetMatch = 1;
    else if (rank == 2) targetMatch = 2;
    else if (rank == 3) targetMatch = 3;
    
    final tier = prizes.firstWhere(
      (p) => p['match'] == targetMatch,
      orElse: () => null,
    );
    return tier != null ? (tier['amount'] as num).toInt() : 0;
  }

  @override
  Widget build(BuildContext context) {
    final cardTheme = AppTheme.getLotteryTheme(widget.lottery['name']);
    final winningNumbers = (widget.lottery['winningNumbers'] as List?)?.cast<int>() ?? [];
    
    DateTime drawDate = DateTime.now();
    if (widget.lottery['drawDate'] != null) {
      drawDate = DateTime.tryParse(widget.lottery['drawDate']) ?? DateTime.now();
    }
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(drawDate);

    final prizes = widget.lottery['prizes'] as List?;
    final pickCount = widget.lottery['pickCount'] ?? 6;
    
    final jackpot = prizes?.firstWhere(
      (p) => p['match'] == pickCount,
      orElse: () => null,
    )?['amount'] ?? 0;

    final revenue = widget.lottery['totalRevenue'] ?? 0;
    final prizesPaid = widget.lottery['totalPrizesPaid'] ?? 0;
    final netProfit = revenue - prizesPaid;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: PhysicalShape(
        clipper: const TicketClipper(),
        color: AppTheme.bgCard,
        shadowColor: cardTheme.primaryColor.withOpacity(0.15),
        elevation: 6.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with premium gradient, safety pattern & vintage inner border
            Container(
              height: 76,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: cardTheme.gradient,
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: TicketPatternPainter(
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: TicketInnerBorderPainter(
                        color: Colors.white.withOpacity(0.2),
                        padding: 6,
                        cornerIndent: 10,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.lottery['name'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.lang.isHindi ? "ड्रॉ हुआ:" : "Drawn:"} $formattedDate',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 10),
                              const SizedBox(width: 4),
                              Text(
                                widget.lang.isHindi ? 'पूर्ण' : 'COMPLETED',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 8.5,
                                  letterSpacing: 0.3,
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

            // Perforation Punches
            Container(
              height: 10,
              width: double.infinity,
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                          color: AppTheme.bgPrimary,
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Winning Numbers Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.lang.translate('winning_numbers').toUpperCase(),
                        style: TextStyle(
                          color: cardTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '1-${widget.lottery['maxNumber']} (Pick ${widget.lottery['pickCount']})',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: winningNumbers.map((n) {
                      return Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.warningColor.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2.5),
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            n.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              shadows: [
                                Shadow(
                                  color: Colors.black38,
                                  offset: Offset(0, 1),
                                  blurRadius: 1.5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: AppTheme.borderColor, height: 1),
                  const SizedBox(height: 16),

                  // Redesigned simplified info: Rank 1 Winner & Ticket Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (widget.lang.isHindi ? 'रैंक 1 विजेता' : 'RANK 1 WINNER').toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatRank1Winner(widget.lottery['rank1WinnerName'], widget.lang),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: AppTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            (widget.lang.isHindi ? 'टिकट मूल्य' : 'TICKET PRICE').toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${widget.lottery['ticketPrice']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Expandable Ranks Section Toggle
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: cardTheme.primaryColor.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cardTheme.primaryColor.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.layers_outlined, size: 14, color: cardTheme.primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                widget.lang.isHindi 
                                    ? (_isExpanded ? 'रैंक छिपाएं' : 'सभी 10 रैंक संयोजन देखें')
                                    : (_isExpanded ? 'Hide Ranks' : 'View All 10 Ranks Drawn'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: cardTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 16,
                            color: cardTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Collapsible ranks list
                  if (_isExpanded) ...[
                    const SizedBox(height: 12),
                    ...List.generate(10, (idx) {
                      final rank = idx + 1; // Rank 1 to 10
                      final rankNumbers = (widget.lottery['rankWinningNumbers'] as List?)?[idx] as List?;
                      final prize = _getPrizeForRank(rank, prizes);
                      
                      if (rankNumbers == null || rankNumbers.isEmpty) return const SizedBox.shrink();
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${widget.lang.isHindi ? "रैंक" : "Rank"} $rank',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                alignment: WrapAlignment.start,
                                children: rankNumbers.map<Widget>((number) {
                                  return Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: AppTheme.borderColor),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$number',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            if (prize > 0)
                              Text(
                                '₹$prize',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.successColor,
                                ),
                              )
                            else
                              Text(
                                widget.lang.isHindi ? 'कोई इनाम नहीं' : 'No Prize',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 18),
                  const Divider(color: AppTheme.borderColor, height: 1),
                  const SizedBox(height: 16),

                  // Bottom Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/lottery-participants',
                          arguments: {
                            'lotteryId': widget.lottery['_id'],
                            'lotteryName': widget.lottery['name'] ?? 'Result',
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cardTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shadowColor: cardTheme.primaryColor.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.people_outline, size: 16),
                      label: Text(
                        widget.lang.translate('view_winners_results'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
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
  }
}
