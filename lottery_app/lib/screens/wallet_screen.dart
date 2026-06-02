import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../providers/language_provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getTransactions();
      if (res['success'] == true) {
        setState(() => _transactions = res['data']['transactions'] ?? []);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'deposit': return Icons.arrow_downward;
      case 'withdraw': return Icons.arrow_upward;
      case 'ticket_purchase': return Icons.confirmation_number;
      case 'winnings': return Icons.emoji_events;
      default: return Icons.swap_horiz;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'deposit': return AppTheme.successColor;
      case 'withdraw': return AppTheme.dangerColor;
      case 'ticket_purchase': return AppTheme.primaryColor;
      case 'winnings': return AppTheme.warningColor;
      default: return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final lang = Provider.of<LanguageProvider>(context);

    Widget content = RefreshIndicator(
      onRefresh: () async {
        await _loadTransactions();
        if (mounted) context.read<AuthProvider>().refreshUser();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!canPop) ...[
              Text(
                lang.translate('wallet'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
            ],

              // Balance card
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Deposit Balance (Withdrawable)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.isHindi ? 'डिपॉजिट बैलेंस' : 'DEPOSIT BALANCE',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${auth.walletBalance.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lang.isHindi ? 'निकासी योग्य' : 'Withdrawable',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Vertical Divider
                            Container(
                              height: 45,
                              width: 1,
                              color: Colors.white.withOpacity(0.25),
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            // Referral Balance (Tickets Only)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.isHindi ? 'रेफरल बैलेंस' : 'REFERRAL BALANCE',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${auth.referralBalance.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lang.isHindi ? 'टिकट के लिए' : 'Tickets Only',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(context, '/deposit')
                                    .then((_) => _loadTransactions()),
                                icon: const Icon(Icons.add, size: 16),
                                label: Text(lang.translate('deposit')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(context, '/withdraw')
                                    .then((_) => _loadTransactions()),
                                icon: const Icon(Icons.arrow_upward, size: 16),
                                label: Text(lang.translate('withdraw')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Transaction history
              Text(
                lang.translate('transaction_history'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                )
              else if (_transactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    children: [
                      const Text('📭', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text(lang.translate('no_transactions'),
                          style: const TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              else
                ...List.generate(_transactions.length, (i) {
                  final txn = _transactions[i];
                  final type = txn['type'] ?? '';
                  final isCredit = type == 'deposit' || type == 'winnings' || type == 'refund';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _getColor(type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_getIcon(type), color: _getColor(type), size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                txn['status'] ?? '',
                                style: TextStyle(
                                  color: txn['status'] == 'approved'
                                      ? AppTheme.successColor
                                      : txn['status'] == 'rejected'
                                          ? AppTheme.dangerColor
                                          : AppTheme.warningColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${isCredit ? '+' : '-'}₹${txn['amount']}',
                          style: TextStyle(
                            color: isCredit ? AppTheme.successColor : AppTheme.dangerColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      );

      if (canPop) {
        return Scaffold(
          appBar: AppBar(title: Text(lang.translate('wallet'))),
          body: SafeArea(child: content),
        );
      }

      return SafeArea(child: content);
  }
}
