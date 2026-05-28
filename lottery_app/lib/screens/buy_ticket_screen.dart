import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/lottery_provider.dart';
import '../providers/language_provider.dart';

class BuyTicketScreen extends StatefulWidget {
  final Map<String, dynamic> lottery;

  const BuyTicketScreen({super.key, required this.lottery});

  @override
  State<BuyTicketScreen> createState() => _BuyTicketScreenState();
}

class _BuyTicketScreenState extends State<BuyTicketScreen> {
  final Set<int> _selectedNumbers = {};
  bool _loading = false;
  String? _message;
  bool _success = false;

  int get _pickCount => widget.lottery['pickCount'] ?? 6;
  int get _maxNumber => widget.lottery['maxNumber'] ?? 49;
  int get _ticketPrice => widget.lottery['ticketPrice'] ?? 50;

  Future<void> _buyTicket() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    if (_selectedNumbers.length != _pickCount) {
      setState(() {
        _message = lang.isHindi 
            ? 'कृपया ठीक $_pickCount नंबर चुनें' 
            : 'Please select exactly $_pickCount numbers';
        _success = false;
      });
      return;
    }

    setState(() { _loading = true; _message = null; });

    final prov = context.read<LotteryProvider>();
    final res = await prov.buyTicket(
      lotteryId: widget.lottery['_id'],
      numbers: _selectedNumbers.toList()..sort(),
    );

    setState(() {
      _success = res['success'] == true;
      _message = res['message'] ?? '';
      _loading = false;
    });

    if (_success && mounted) {
      context.read<AuthProvider>().refreshUser();
      // Show success and go back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.isHindi ? '🎫 टिकट सफलतापूर्वक खरीदा गया!' : '🎫 Ticket purchased successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  void _toggleNumber(int num) {
    setState(() {
      if (_selectedNumbers.contains(num)) {
        _selectedNumbers.remove(num);
      } else if (_selectedNumbers.length < _pickCount) {
        _selectedNumbers.add(num);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lottery['name'] ?? (lang.isHindi ? 'टिकट खरीदें' : 'Buy Ticket')),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.15),
                          AppTheme.bgCard,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          lang.isHindi 
                              ? '1 से $_maxNumber में से $_pickCount नंबर चुनें' 
                              : 'Pick $_pickCount numbers from 1 to $_maxNumber',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lang.isHindi ? 'टिकट की कीमत: ₹$_ticketPrice' : 'Ticket Price: ₹$_ticketPrice',
                          style: const TextStyle(
                            color: AppTheme.warningColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${lang.isHindi ? "चयनित" : "Selected"}: ${_selectedNumbers.length}/$_pickCount',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Selected numbers preview
                  if (_selectedNumbers.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: (_selectedNumbers.toList()..sort()).map((num) {
                          return Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '$num',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  if (_message != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _success
                            ? AppTheme.successColor.withOpacity(0.1)
                            : AppTheme.dangerColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _success ? AppTheme.successColor : AppTheme.dangerColor,
                          fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Number Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: _maxNumber,
                    itemBuilder: (context, index) {
                      final num = index + 1;
                      final isSelected = _selectedNumbers.contains(num);
                      final canSelect = _selectedNumbers.length < _pickCount || isSelected;

                      return GestureDetector(
                        onTap: canSelect ? () => _toggleNumber(num) : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppTheme.primaryGradient : null,
                            color: isSelected ? null : AppTheme.bgSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.borderColor,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '$num',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : canSelect
                                        ? AppTheme.textPrimary
                                        : AppTheme.textMuted,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Buy button fixed at bottom
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary,
              border: Border(
                top: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading || _selectedNumbers.length != _pickCount
                      ? null
                      : _buyTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.bgSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                      : Text(
                          _selectedNumbers.length == _pickCount
                              ? (lang.isHindi ? 'टिकट खरीदें — ₹$_ticketPrice' : 'Buy Ticket — ₹$_ticketPrice')
                              : (lang.isHindi ? '$_pickCount नंबर चुनें' : 'Select $_pickCount Numbers'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
