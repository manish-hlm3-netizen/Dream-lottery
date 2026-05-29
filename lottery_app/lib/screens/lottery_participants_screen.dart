import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';

class LotteryParticipantsScreen extends StatefulWidget {
  final String lotteryId;
  final String lotteryName;

  const LotteryParticipantsScreen({
    super.key,
    required this.lotteryId,
    required this.lotteryName,
  });

  @override
  State<LotteryParticipantsScreen> createState() => _LotteryParticipantsScreenState();
}

class _LotteryParticipantsScreenState extends State<LotteryParticipantsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _winners = [];
  List<dynamic> _lost = [];
  List<int> _winningNumbers = [];
  List<List<int>> _rankWinningNumbers = [];
  String _drawDate = '';
  String _lotteryName = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _api.getLotteryWinnersLost(widget.lotteryId);
      if (res['success'] == true) {
        final data = res['data'];
        setState(() {
          _winningNumbers = (data['winningNumbers'] as List?)?.cast<int>() ?? [];
          final rankList = data['rankWinningNumbers'] as List?;
          if (rankList != null && rankList.isNotEmpty) {
            _rankWinningNumbers = rankList
                .map((item) => (item as List).cast<int>().toList())
                .toList();
          } else {
            _rankWinningNumbers = [];
          }
          _winners = data['winners'] ?? [];
          _lost = data['lost'] ?? [];
          _drawDate = data['drawDate'] ?? '';
          _lotteryName = data['name'] ?? widget.lotteryName;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = res['message'] ?? 'Failed to load winners roster';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lotteryName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadParticipants,
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 56, color: AppTheme.dangerColor),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadParticipants,
                          child: const Text('Retry'),
                        )
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Winning Numbers banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 18, bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: AppTheme.borderColor),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              lang.translate('winning_numbers').toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          
                          if (_rankWinningNumbers.isNotEmpty) ...[
                            // Scrollable rank winning numbers carousel
                            SizedBox(
                              height: 104,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _rankWinningNumbers.length,
                                itemBuilder: (context, idx) {
                                  final numbers = _rankWinningNumbers[idx];
                                  final rankNum = idx + 1;
                                  final emoji = rankNum == 1 
                                      ? '👑' 
                                      : rankNum == 2 
                                          ? '🥈' 
                                          : rankNum == 3 
                                              ? '🥉' 
                                              : '🏆';
                                  
                                  return Container(
                                    width: 275,
                                    margin: const EdgeInsets.only(right: 14),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppTheme.borderColor),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              emoji,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Rank $rankNum Combination',
                                              style: TextStyle(
                                                color: AppTheme.primaryColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: numbers.map((num) {
                                            return Container(
                                              width: 32,
                                              height: 32,
                                              margin: const EdgeInsets.symmetric(horizontal: 3),
                                              decoration: BoxDecoration(
                                                gradient: AppTheme.primaryGradient,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme.primaryColor.withOpacity(0.25),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 1.5),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  num.toString().padLeft(2, '0'),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ] else ...[
                            // Standard single row fallback
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: _winningNumbers.map((num) {
                                  return Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryColor.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        num.toString().padLeft(2, '0'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // List Header
                    Container(
                      color: Colors.white,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      child: Row(
                        children: [
                          const Icon(Icons.people_outline, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            lang.translate('winners_and_participants'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Combined Roster List
                    Expanded(
                      child: _buildCombinedList(
                        [..._winners, ..._lost],
                        lang.translate('no_participants'),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$minute';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildCombinedList(List<dynamic> items, String emptyMessage) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👥', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final ticket = items[index];
        final name = ticket['userName'] ?? 'User';
        final prizeWon = ticket['prizeWon'] ?? 0;
        final selectedNumbers = (ticket['selectedNumbers'] as List?)?.cast<int>() ?? [];
        final matchedNumbers = (ticket['matchedNumbers'] as List?)?.cast<int>() ?? [];
        final isWinner = ticket['status'] == 'won' || prizeWon > 0;
        final rank = ticket['rank'] ?? 0;
        final currentLang = Provider.of<LanguageProvider>(context, listen: false);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: isWinner ? const Color(0xFFF0FDF4) : Colors.white, // Very soft green tint for winners
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isWinner 
                  ? AppTheme.successColor.withOpacity(0.4) 
                  : AppTheme.borderColor,
              width: isWinner ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isWinner 
                    ? AppTheme.successColor.withOpacity(0.08) 
                    : Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Container(
              // Draw the vertical left color accent bar
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isWinner ? AppTheme.successColor : AppTheme.borderColor,
                    width: 6,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (isWinner) ...[
                                Text(
                                  rank > 0 
                                      ? (rank == 1 ? '👑 ' : rank == 2 ? '🥈 ' : rank == 3 ? '🥉 ' : '🏆 ')
                                      : '🏆 ', 
                                  style: const TextStyle(fontSize: 18)
                                ),
                              ],
                              Flexible(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: isWinner ? AppTheme.successColor : AppTheme.textPrimary,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isWinner 
                                ? AppTheme.successColor.withOpacity(0.1) 
                                : AppTheme.bgSurface,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isWinner 
                                  ? AppTheme.successColor.withOpacity(0.3) 
                                  : AppTheme.borderColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isWinner ? Icons.emoji_events : Icons.person_outline,
                                size: 12,
                                color: isWinner ? AppTheme.successColor : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isWinner 
                                    ? (rank > 0 ? 'RANK $rank WINNER' : currentLang.translate('status_winner').toUpperCase())
                                    : currentLang.translate('status_participant').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: isWinner ? AppTheme.successColor : AppTheme.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 14),
                    Divider(color: isWinner ? AppTheme.successColor.withOpacity(0.15) : AppTheme.borderColor, height: 1),
                    const SizedBox(height: 14),

                    // Metadata Details Grid (Premium 2-column layout)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Col 1: Lottery & Draw Date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Lottery
                              _buildMetadataItem(
                                currentLang.translate('lottery_name_label'),
                                _lotteryName.isNotEmpty ? _lotteryName : widget.lotteryName,
                                Icons.casino_outlined,
                                isWinner,
                              ),
                              const SizedBox(height: 14),
                              // Draw Date
                              _buildMetadataItem(
                                currentLang.translate('draw_date_label'),
                                _formatDate(_drawDate),
                                Icons.calendar_month_outlined,
                                isWinner,
                              ),
                            ],
                          ),
                        ),
                        
                        // Col 2: Numbers & Winnings
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Winnings
                              _buildMetadataItem(
                                currentLang.translate('winnings_label'),
                                isWinner ? '₹$prizeWon' : '₹0',
                                Icons.monetization_on_outlined,
                                isWinner,
                                isHighlight: isWinner,
                              ),
                              const SizedBox(height: 14),
                              // Numbers Label
                              Text(
                                currentLang.translate('selected_numbers_label').toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Wrap numbers here
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: selectedNumbers.map((num) {
                                  final isMatched = matchedNumbers.contains(num);
                                  return Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      gradient: isMatched 
                                          ? AppTheme.successGradient 
                                          : const LinearGradient(
                                              colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: isMatched 
                                              ? AppTheme.successColor.withOpacity(0.3) 
                                              : Colors.black.withOpacity(0.04),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                      border: isMatched ? null : Border.all(color: AppTheme.borderColor),
                                    ),
                                    child: Center(
                                      child: Text(
                                        num.toString().padLeft(2, '0'),
                                        style: TextStyle(
                                          color: isMatched ? Colors.white : AppTheme.textPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetadataItem(String label, String value, IconData icon, bool isWinner, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isWinner 
                ? AppTheme.successColor.withOpacity(0.08) 
                : AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 14,
            color: isHighlight 
                ? AppTheme.successColor 
                : (isWinner ? AppTheme.successColor.withOpacity(0.8) : AppTheme.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w800,
                  color: isHighlight 
                      ? AppTheme.successColor 
                      : AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
