import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  String? _expandedTxnId;

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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
                  final totalBalance = auth.walletBalance + auth.referralBalance + auth.winningBalance;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.isHindi ? 'कुल बैलेंस' : 'TOTAL BALANCE',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${totalBalance.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _CompactActionButton(
                                  icon: Icons.add,
                                  label: lang.translate('deposit'),
                                  onPressed: () => Navigator.pushNamed(context, '/deposit')
                                      .then((_) => _loadTransactions()),
                                ),
                                const SizedBox(width: 8),
                                _CompactActionButton(
                                  icon: Icons.arrow_upward,
                                  label: lang.translate('withdraw'),
                                  onPressed: () => Navigator.pushNamed(context, '/withdraw')
                                      .then((_) => _loadTransactions()),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(color: Colors.white.withOpacity(0.15), height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _CompactBalanceItem(
                              label: lang.isHindi ? 'जमा' : 'Deposit',
                              amount: '₹${auth.walletBalance.toStringAsFixed(0)}',
                              color: Colors.white,
                            ),
                            _CompactBalanceItem(
                              label: lang.isHindi ? 'रेफरल' : 'Referral',
                              amount: '₹${auth.referralBalance.toStringAsFixed(0)}',
                              color: const Color(0xFF80FF80),
                            ),
                            _CompactBalanceItem(
                              label: lang.isHindi ? 'जीत' : 'Winnings',
                              amount: '₹${auth.winningBalance.toStringAsFixed(0)}',
                              color: const Color(0xFFFFD700),
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
                ),
                ...List.generate(_transactions.length, (i) {
                  final txn = _transactions[i];
                  final type = txn['type'] ?? '';
                  final isCredit = type == 'deposit' || type == 'winnings' || type == 'refund' || type == 'referral';
                  final isExpanded = _expandedTxnId == txn['_id'];
                  
                  String formattedDate = '';
                  if (txn['createdAt'] != null) {
                    final date = DateTime.tryParse(txn['createdAt'])?.toLocal();
                    if (date != null) {
                      formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _expandedTxnId = isExpanded ? null : txn['_id'];
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (txn['status'] == 'approved'
                                                  ? AppTheme.successColor
                                                  : txn['status'] == 'rejected'
                                                      ? AppTheme.dangerColor
                                                      : AppTheme.warningColor).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              (txn['status'] ?? 'pending').toUpperCase(),
                                              style: TextStyle(
                                                color: txn['status'] == 'approved'
                                                    ? AppTheme.successColor
                                                    : txn['status'] == 'rejected'
                                                        ? AppTheme.dangerColor
                                                        : AppTheme.warningColor,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (formattedDate.isNotEmpty)
                                            Expanded(
                                              child: Text(
                                                formattedDate,
                                                style: const TextStyle(
                                                  color: AppTheme.textMuted,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${isCredit ? '+' : '-'}₹${txn['amount']}',
                                      style: TextStyle(
                                        color: isCredit ? AppTheme.successColor : AppTheme.dangerColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                      size: 16,
                                      color: AppTheme.textMuted,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (isExpanded) ...[
                              const SizedBox(height: 14),
                              const Divider(color: AppTheme.borderColor, height: 1),
                              const SizedBox(height: 12),
                              _buildDetailRow(lang.isHindi ? 'लेनदेन आईडी' : 'Transaction ID', txn['_id'] ?? '-'),
                              if (txn['description'] != null && txn['description'].toString().isNotEmpty)
                                _buildDetailRow(lang.isHindi ? 'विवरण' : 'Description', txn['description']),
                              if (txn['upiTransactionId'] != null && txn['upiTransactionId'].toString().isNotEmpty)
                                _buildDetailRow(lang.isHindi ? 'UPI संदर्भ संख्या' : 'UPI Ref ID', txn['upiTransactionId']),
                              if (txn['adminNote'] != null && txn['adminNote'].toString().isNotEmpty)
                                _buildDetailRow(lang.isHindi ? 'एडमिन नोट' : 'Admin Note', txn['adminNote']),
                              if (txn['processedAt'] != null)
                                _buildDetailRow(
                                  lang.isHindi ? 'संसाधित समय' : 'Processed Time',
                                  DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(txn['processedAt']).toLocal()),
                                ),
                            ],
                          ],
                        ),
                      ),
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

/// A single balance breakdown row inside the wallet card.
class _BalanceRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sublabel;
  final String amount;
  final Color amountColor;

  const _BalanceRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
    required this.amount,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  sublabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: amountColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _CompactActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 12),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.18),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CompactBalanceItem extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _CompactBalanceItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
