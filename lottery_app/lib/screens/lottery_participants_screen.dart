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
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: AppTheme.borderColor),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            lang.translate('winning_numbers'),
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
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
        final currentLang = Provider.of<LanguageProvider>(context, listen: false);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isWinner 
                  ? AppTheme.successColor.withOpacity(0.4) 
                  : AppTheme.borderColor,
              width: isWinner ? 1.8 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (isWinner) ...[
                            const Text('🏆 ', style: TextStyle(fontSize: 16)),
                          ],
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: isWinner ? AppTheme.primaryColor : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isWinner && prizeWon > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹$prizeWon',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Numbers
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: selectedNumbers.map((num) {
                    final isMatched = matchedNumbers.contains(num);
                    return Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: isMatched ? AppTheme.successGradient : null,
                        color: isMatched ? null : AppTheme.bgSurface,
                        shape: BoxShape.circle,
                        border: isMatched ? null : Border.all(color: AppTheme.borderColor),
                      ),
                      child: Center(
                        child: Text(
                          num.toString().padLeft(2, '0'),
                          style: TextStyle(
                            color: isMatched ? Colors.white : AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 14),
                Divider(color: AppTheme.borderColor, height: 1),
                const SizedBox(height: 12),
                
                // Metadata Grid
                Row(
                  children: [
                    // Lottery Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentLang.translate('lottery_name_label'),
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _lotteryName.isNotEmpty ? _lotteryName : widget.lotteryName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Draw Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentLang.translate('draw_date_label'),
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatDate(_drawDate),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                Row(
                  children: [
                    // Status tag
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentLang.translate('status_label'),
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isWinner 
                                ? currentLang.translate('status_winner')
                                : currentLang.translate('status_participant'),
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.w800, 
                              color: isWinner ? AppTheme.successColor : AppTheme.textSecondary
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Winnings
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentLang.translate('winnings_label'),
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '₹$prizeWon',
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.w900, 
                              color: isWinner ? AppTheme.successColor : AppTheme.textPrimary
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
