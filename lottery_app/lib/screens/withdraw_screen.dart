import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../providers/language_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY: Withdraw Screen — choose Deposit or Winning balance
// ─────────────────────────────────────────────────────────────────────────────
class WithdrawScreen extends StatelessWidget {
  const WithdrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(lang.isHindi ? 'पैसे निकालें' : 'Withdraw Money')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              lang.isHindi ? 'निकासी का प्रकार चुनें' : 'Choose Withdrawal Type',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              lang.isHindi
                  ? 'आप किस बैलेंस से पैसे निकालना चाहते हैं?'
                  : 'Which balance would you like to withdraw from?',
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 28),

            // ── Option 1: Deposit Balance ──
            _WithdrawTypeCard(
              icon: Icons.account_balance_wallet_rounded,
              iconBgColor: const Color(0xFF3B82F6),
              title: lang.isHindi ? 'डिपॉजिट राशि निकालें' : 'Withdraw Deposit Amount',
              subtitle: lang.isHindi
                  ? 'केवल आपके जमा किए गए पैसे'
                  : 'Only your deposited funds',
              badgeText: lang.isHindi
                  ? '₹${auth.walletBalance.toStringAsFixed(0)} उपलब्ध'
                  : '₹${auth.walletBalance.toStringAsFixed(0)} available',
              badgeColor: const Color(0xFF3B82F6),
              tags: [
                lang.isHindi ? '✅ UPI ट्रांसफर' : '✅ UPI Transfer',
                lang.isHindi ? '✅ बैंक ट्रांसफर' : '✅ Bank Transfer',
                lang.isHindi ? '✅ कोई TDS नहीं' : '✅ No TDS',
              ],
              onTap: auth.walletBalance <= 0
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const _DepositWithdrawScreen(),
                        ),
                      ),
              disabled: auth.walletBalance <= 0,
            ),

            const SizedBox(height: 16),

            // ── Option 2: Winning Balance ──
            _WithdrawTypeCard(
              icon: Icons.emoji_events_rounded,
              iconBgColor: const Color(0xFFD97706),
              title: lang.isHindi ? 'जीत की राशि निकालें' : 'Withdraw Winning Amount',
              subtitle: lang.isHindi
                  ? 'लॉटरी पुरस्कार से अर्जित राशि'
                  : 'Amount earned from lottery prizes',
              badgeText: lang.isHindi
                  ? '₹${auth.winningBalance.toStringAsFixed(0)} उपलब्ध'
                  : '₹${auth.winningBalance.toStringAsFixed(0)} available',
              badgeColor: const Color(0xFFD97706),
              tags: [
                lang.isHindi ? '⚠️ TDS लागू होगा' : '⚠️ TDS Applicable',
                lang.isHindi ? '📋 नियम देखें' : '📋 View Tax Rules',
              ],
              onTap: auth.winningBalance <= 0
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WinningWithdrawInfoScreen(),
                        ),
                      ),
              disabled: auth.winningBalance <= 0,
              isGold: true,
            ),

            const SizedBox(height: 32),

            // Info note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.infoColor.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppTheme.infoColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lang.isHindi
                          ? 'रेफरल बैलेंस केवल टिकट खरीदने के लिए उपयोग किया जा सकता है और निकाला नहीं जा सकता।'
                          : 'Referral balance can only be used to buy tickets and cannot be withdrawn.',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
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

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE: Withdraw Type Option Card
// ─────────────────────────────────────────────────────────────────────────────
class _WithdrawTypeCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final List<String> tags;
  final VoidCallback? onTap;
  final bool disabled;
  final bool isGold;

  const _WithdrawTypeCard({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.tags,
    required this.onTap,
    this.disabled = false,
    this.isGold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isGold
                    ? const Color(0xFFD97706).withOpacity(0.35)
                    : AppTheme.borderColor,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: iconBgColor.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: iconBgColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: iconBgColor, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Arrow
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconBgColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: iconBgColor),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Available balance badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: badgeColor.withOpacity(0.25)),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Tags row
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: tags
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.bgSurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(t,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary)),
                          ))
                      .toList(),
                ),
                if (disabled) ...[
                  const SizedBox(height: 10),
                  Text(
                    Provider.of<LanguageProvider>(context, listen: false).isHindi
                        ? 'बैलेंस उपलब्ध नहीं'
                        : 'No balance available',
                    style: const TextStyle(
                        color: AppTheme.dangerColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 2A: Deposit Withdrawal Form (UPI / Bank)
// ─────────────────────────────────────────────────────────────────────────────
class _DepositWithdrawScreen extends StatefulWidget {
  const _DepositWithdrawScreen();

  @override
  State<_DepositWithdrawScreen> createState() => _DepositWithdrawScreenState();
}

class _DepositWithdrawScreenState extends State<_DepositWithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _accountHolderNameController = TextEditingController();

  String _selectedMethod = 'upi';
  bool _loading = false;
  String? _message;
  bool _success = false;

  Future<void> _handleWithdraw() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final amount = double.parse(_amountController.text);

    if (amount > auth.walletBalance) {
      setState(() {
        _success = false;
        _message = lang.isHindi
            ? 'अपर्याप्त डिपॉजिट बैलेंस। उपलब्ध: ₹${auth.walletBalance.toStringAsFixed(0)}'
            : 'Insufficient deposit balance. Available: ₹${auth.walletBalance.toStringAsFixed(0)}';
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final res = await ApiService().withdraw(
        amount: amount,
        method: _selectedMethod,
        upiId: _selectedMethod == 'upi' ? _upiIdController.text.trim() : null,
        bankName:
            _selectedMethod == 'bank' ? _bankNameController.text.trim() : null,
        accountNumber: _selectedMethod == 'bank'
            ? _accountNumberController.text.trim()
            : null,
        ifscCode: _selectedMethod == 'bank'
            ? _ifscCodeController.text.trim().toUpperCase()
            : null,
        accountHolderName: _selectedMethod == 'bank'
            ? _accountHolderNameController.text.trim()
            : null,
      );

      setState(() {
        _success = res['success'] == true;
        _message = res['message'] ??
            (lang.isHindi ? 'अनुरोध सबमिट किया गया' : 'Request submitted');
      });

      if (_success) {
        auth.refreshUser();
        _amountController.clear();
        _upiIdController.clear();
        _bankNameController.clear();
        _accountNumberController.clear();
        _ifscCodeController.clear();
        _accountHolderNameController.clear();
      }
    } catch (_) {
      final lang2 = Provider.of<LanguageProvider>(context, listen: false);
      setState(() {
        _success = false;
        _message = lang2.isHindi
            ? 'निकासी सबमिट करने में विफल'
            : 'Failed to submit withdrawal';
      });
    }

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _upiIdController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _accountHolderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
          title: Text(lang.isHindi ? 'डिपॉजिट निकासी' : 'Withdraw Deposit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance display
            Consumer<AuthProvider>(
              builder: (context, auth, _) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: Color(0xFF3B82F6)),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.isHindi
                              ? 'डिपॉजिट बैलेंस (निकासी योग्य)'
                              : 'Deposit Balance (Withdrawable)',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12),
                        ),
                        Text(
                          '₹${auth.walletBalance.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Method toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  _MethodTab(
                    icon: Icons.payment,
                    label: lang.isHindi ? 'UPI ट्रांसफर' : 'UPI Transfer',
                    selected: _selectedMethod == 'upi',
                    onTap: () => setState(() => _selectedMethod = 'upi'),
                  ),
                  _MethodTab(
                    icon: Icons.account_balance,
                    label: lang.isHindi ? 'बैंक ट्रांसफर' : 'Bank Transfer',
                    selected: _selectedMethod == 'bank',
                    onTap: () => setState(() => _selectedMethod = 'bank'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_message != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _success
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.dangerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                      color:
                          _success ? AppTheme.successColor : AppTheme.dangerColor,
                      fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: lang.isHindi ? 'राशि (₹)' : 'Amount (₹)',
                      prefixIcon:
                          const Icon(Icons.currency_rupee, color: AppTheme.textMuted),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty)
                        return lang.isHindi ? 'राशि दर्ज करें' : 'Enter amount';
                      final amt = double.tryParse(val);
                      if (amt == null || amt < 100)
                        return lang.isHindi ? 'न्यूनतम ₹100' : 'Minimum ₹100';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AnimatedCrossFade(
                    firstChild: Column(
                      children: [
                        TextFormField(
                          controller: _upiIdController,
                          decoration: InputDecoration(
                            labelText:
                                lang.isHindi ? 'आपका UPI ID' : 'Your UPI ID',
                            prefixIcon: const Icon(Icons.payment,
                                color: AppTheme.textMuted),
                            hintText: lang.isHindi
                                ? 'जैसे, yourname@upi'
                                : 'e.g., yourname@upi',
                          ),
                          validator: (val) {
                            if (_selectedMethod == 'upi') {
                              if (val == null || val.isEmpty)
                                return lang.isHindi
                                    ? 'UPI ID दर्ज करें'
                                    : 'Enter UPI ID';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    secondChild: Column(
                      children: [
                        TextFormField(
                          controller: _accountHolderNameController,
                          decoration: InputDecoration(
                            labelText: lang.isHindi
                                ? 'खाताधारक का नाम'
                                : 'Account Holder Name',
                            prefixIcon:
                                const Icon(Icons.person, color: AppTheme.textMuted),
                          ),
                          validator: (val) {
                            if (_selectedMethod == 'bank' &&
                                (val == null || val.isEmpty))
                              return lang.isHindi
                                  ? 'नाम दर्ज करें'
                                  : 'Enter name';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bankNameController,
                          decoration: InputDecoration(
                            labelText:
                                lang.isHindi ? 'बैंक का नाम' : 'Bank Name',
                            prefixIcon: const Icon(Icons.business,
                                color: AppTheme.textMuted),
                          ),
                          validator: (val) {
                            if (_selectedMethod == 'bank' &&
                                (val == null || val.isEmpty))
                              return lang.isHindi
                                  ? 'बैंक नाम दर्ज करें'
                                  : 'Enter bank name';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _accountNumberController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText:
                                lang.isHindi ? 'खाता संख्या' : 'Account Number',
                            prefixIcon: const Icon(Icons.numbers,
                                color: AppTheme.textMuted),
                          ),
                          validator: (val) {
                            if (_selectedMethod == 'bank') {
                              if (val == null || val.isEmpty)
                                return lang.isHindi
                                    ? 'खाता संख्या दर्ज करें'
                                    : 'Enter account number';
                              if (val.length < 9)
                                return lang.isHindi
                                    ? 'अमान्य खाता संख्या'
                                    : 'Invalid account number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ifscCodeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText:
                                lang.isHindi ? 'IFSC कोड' : 'IFSC Code',
                            prefixIcon:
                                const Icon(Icons.code, color: AppTheme.textMuted),
                            hintText: 'e.g., SBIN0001234',
                          ),
                          validator: (val) {
                            if (_selectedMethod == 'bank') {
                              if (val == null || val.isEmpty)
                                return lang.isHindi
                                    ? 'IFSC कोड दर्ज करें'
                                    : 'Enter IFSC code';
                              if (val.length != 11)
                                return lang.isHindi
                                    ? 'IFSC 11 वर्णों का होना चाहिए'
                                    : 'IFSC must be 11 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    crossFadeState: _selectedMethod == 'upi'
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 300),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleWithdraw,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dangerColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              lang.isHindi
                                  ? 'निकासी अनुरोध सबमिट करें'
                                  : 'Submit Withdrawal Request',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              lang.isHindi
                  ? '⏳ व्यवस्थापक द्वारा अनुरोध संसाधित किए जाने तक राशि रोकी जाएगी'
                  : '⏳ Amount will be held until admin processes the request',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 2B: Winning Amount Tax Info Screen
// ─────────────────────────────────────────────────────────────────────────────
class WinningWithdrawInfoScreen extends StatelessWidget {
  const WinningWithdrawInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final winBal = auth.winningBalance;

    // TDS = 30% for winnings above ₹10,000 in India (as per Income Tax Act)
    const double tdsRate = 0.30;
    const double tdsThreshold = 10000.0;
    final bool tdsApplicable = winBal > tdsThreshold;
    final double tdsAmount = tdsApplicable ? winBal * tdsRate : 0.0;
    final double netPayable = winBal - tdsAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.isHindi ? 'जीत की राशि — नियम' : 'Winning Withdrawal — Tax Rules'),
        backgroundColor: const Color(0xFFD97706),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Banner ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD97706).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: Colors.white, size: 44),
                  const SizedBox(height: 10),
                  Text(
                    lang.isHindi ? 'आपका जीत बैलेंस' : 'Your Winning Balance',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${winBal.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      lang.isHindi ? '🏆 लॉटरी पुरस्कार से अर्जित' : '🏆 Earned from lottery prizes',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── TDS Calculation Card ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calculate_rounded,
                            color: AppTheme.warningColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        lang.isHindi ? 'TDS गणना' : 'TDS Calculation',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _CalcRow(
                    label: lang.isHindi ? 'जीत की कुल राशि' : 'Total Winning Amount',
                    value: '₹${winBal.toStringAsFixed(2)}',
                    valueColor: AppTheme.textPrimary,
                  ),
                  const Divider(height: 20, color: AppTheme.borderColor),
                  _CalcRow(
                    label: lang.isHindi
                        ? 'TDS (30%) — धारा 194B'
                        : 'TDS Deduction (30%) — Sec 194B',
                    value: tdsApplicable
                        ? '- ₹${tdsAmount.toStringAsFixed(2)}'
                        : lang.isHindi
                            ? 'लागू नहीं'
                            : 'Not Applicable',
                    valueColor: tdsApplicable
                        ? AppTheme.dangerColor
                        : AppTheme.successColor,
                  ),
                  const Divider(height: 20, color: AppTheme.borderColor),
                  _CalcRow(
                    label: lang.isHindi ? 'आपको मिलने वाली राशि' : 'Net Amount Payable to You',
                    value: '₹${netPayable.toStringAsFixed(2)}',
                    valueColor: AppTheme.successColor,
                    bold: true,
                    large: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Tax Rules Section ──
            Text(
              lang.isHindi ? '📋 कर नियम एवं जानकारी' : '📋 Tax Rules & Information',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),

            _TaxRuleCard(
              icon: Icons.gavel_rounded,
              iconColor: const Color(0xFF7C3AED),
              title: lang.isHindi
                  ? 'धारा 194B — TDS 30%'
                  : 'Section 194B — 30% TDS',
              body: lang.isHindi
                  ? 'भारतीय आयकर अधिनियम की धारा 194B के अनुसार, ₹10,000 से अधिक की लॉटरी जीत पर 30% TDS काटा जाता है।'
                  : 'As per Section 194B of the Indian Income Tax Act, any lottery winnings exceeding ₹10,000 are subject to a flat 30% TDS deduction at source.',
            ),
            const SizedBox(height: 10),
            _TaxRuleCard(
              icon: Icons.receipt_long_rounded,
              iconColor: const Color(0xFF0EA5E9),
              title: lang.isHindi ? 'TDS प्रमाण पत्र' : 'TDS Certificate (Form 16A)',
              body: lang.isHindi
                  ? 'काटा गया TDS सरकार को जमा किया जाएगा। आप अपने Form 26AS में इसे देख सकते हैं और ITR में इसका क्रेडिट ले सकते हैं।'
                  : 'The deducted TDS will be deposited with the government. You can view it in Form 26AS and claim credit while filing your ITR.',
            ),
            const SizedBox(height: 10),
            _TaxRuleCard(
              icon: Icons.info_outline_rounded,
              iconColor: const Color(0xFF10B981),
              title: lang.isHindi
                  ? '₹10,000 से कम — कोई TDS नहीं'
                  : 'Below ₹10,000 — No TDS',
              body: lang.isHindi
                  ? 'यदि आपकी जीत ₹10,000 या उससे कम है, तो कोई TDS नहीं काटा जाएगा। पूरी राशि आपके बैंक खाते में ट्रांसफर की जाएगी।'
                  : 'If your total winning amount is ₹10,000 or less, no TDS will be deducted. The full amount will be transferred to your account.',
            ),
            const SizedBox(height: 10),
            _TaxRuleCard(
              icon: Icons.security_rounded,
              iconColor: const Color(0xFFE52D27),
              title: lang.isHindi ? 'PAN कार्ड अनिवार्य' : 'PAN Card Mandatory',
              body: lang.isHindi
                  ? 'TDS कटौती के लिए आपका PAN कार्ड अनिवार्य है। बिना PAN के TDS की दर 30% से बढ़कर 34.608% हो सकती है।'
                  : 'PAN card is mandatory for TDS deduction. Without a valid PAN, the effective TDS rate may increase to 34.608%.',
            ),
            const SizedBox(height: 24),

            // ── Proceed Button ──
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _WinningWithdrawFormScreen(),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: Text(
                  lang.isHindi
                      ? 'समझ गया — निकासी जारी रखें'
                      : 'I Understand — Proceed to Withdraw',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              lang.isHindi
                  ? '* उपरोक्त जानकारी भारतीय कर कानूनों पर आधारित है। कृपया अपने CA से सलाह लें।'
                  : '* The above information is based on Indian tax laws. Please consult your CA for personalised advice.',
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 2B-FORM: Winning Amount Withdrawal Form
// ─────────────────────────────────────────────────────────────────────────────
class _WinningWithdrawFormScreen extends StatefulWidget {
  const _WinningWithdrawFormScreen();

  @override
  State<_WinningWithdrawFormScreen> createState() =>
      _WinningWithdrawFormScreenState();
}

class _WinningWithdrawFormScreenState
    extends State<_WinningWithdrawFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _upiIdController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  final _cessTxnController = TextEditingController();

  String _selectedMethod = 'upi';
  bool _loading = false;
  String? _message;
  bool _success = false;

  // Dynamic UPI settings for Cess payment
  String _upiId = 'lottery@upi';
  Uint8List? _qrBytes;
  bool _fetchingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadUPISettings();
    _upiIdController.addListener(_onFieldChanged);
    _bankNameController.addListener(_onFieldChanged);
    _accountNumberController.addListener(_onFieldChanged);
    _ifscCodeController.addListener(_onFieldChanged);
    _accountHolderNameController.addListener(_onFieldChanged);
    _cessTxnController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {});
  }

  Future<void> _loadUPISettings() async {
    try {
      final res = await ApiService().getUPISettings();
      if (res['success'] == true && res['data'] != null) {
        setState(() {
          _upiId = res['data']['upiId'] ?? 'lottery@upi';
          final String? qr = res['data']['qrCodeUrl'];
          if (qr != null && qr.startsWith('data:image')) {
            final base64String = qr.split(',').last;
            _qrBytes = base64Decode(base64String);
          }
        });
      }
    } catch (e) {
      debugPrint('Load UPI Settings error: $e');
    } finally {
      if (mounted) {
        setState(() => _fetchingSettings = false);
      }
    }
  }

  bool _isStep1Valid() {
    if (_selectedMethod == 'upi') {
      return _upiIdController.text.trim().isNotEmpty;
    } else {
      return _bankNameController.text.trim().isNotEmpty &&
          _accountNumberController.text.trim().length >= 9 &&
          _ifscCodeController.text.trim().length == 11 &&
          _accountHolderNameController.text.trim().isNotEmpty;
    }
  }

  int get _currentStep {
    if (!_isStep1Valid()) return 1;
    final txnId = _cessTxnController.text.trim();
    if (txnId.isEmpty || txnId.length < 5) return 2;
    return 3;
  }

  bool _isStepUnlocked(int stepNum) {
    if (stepNum == 1) return true;
    return _isStep1Valid();
  }

  Future<void> _handleWithdraw() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final amount = auth.winningBalance;

    if (amount < 100) {
      setState(() {
        _success = false;
        _message = lang.isHindi
            ? 'न्यूनतम निकासी राशि ₹100 है।'
            : 'Minimum withdrawal amount is ₹100.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final res = await ApiService().withdraw(
        amount: amount,
        method: _selectedMethod,
        isWinnings: true,
        upiId: _selectedMethod == 'upi' ? _upiIdController.text.trim() : null,
        bankName:
            _selectedMethod == 'bank' ? _bankNameController.text.trim() : null,
        accountNumber: _selectedMethod == 'bank'
            ? _accountNumberController.text.trim()
            : null,
        ifscCode: _selectedMethod == 'bank'
            ? _ifscCodeController.text.trim().toUpperCase()
            : null,
        accountHolderName: _selectedMethod == 'bank'
            ? _accountHolderNameController.text.trim()
            : null,
        cessTransactionId: _cessTxnController.text.trim(),
      );

      setState(() {
        _success = res['success'] == true;
        _message = res['message'] ??
            (lang.isHindi ? 'अनुरोध सबमिट किया गया' : 'Request submitted');
      });

      if (_success) {
        auth.refreshUser();
        _upiIdController.clear();
        _bankNameController.clear();
        _accountNumberController.clear();
        _ifscCodeController.clear();
        _accountHolderNameController.clear();
        _cessTxnController.clear();
      }
    } catch (_) {
      final lang2 = Provider.of<LanguageProvider>(context, listen: false);
      setState(() {
        _success = false;
        _message = lang2.isHindi
            ? 'निकासी सबमिट करने में विफल'
            : 'Failed to submit withdrawal';
      });
    }

    setState(() => _loading = false);
  }

  Future<void> _launchUPIApp(double cessAmount) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final Uri uri = Uri.parse(
        'upi://pay?pa=$_upiId&pn=Lottery%20Cess&am=${cessAmount.toStringAsFixed(2)}&cu=INR&tn=4%25%20Cess%20Winnings%20Withdrawal');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        setState(() {
          _message = lang.isHindi
              ? 'कृपया भुगतान के बाद UTR/ट्रांजैक्शन ID कॉपी करें और सबमिट करने के लिए नीचे पेस्ट करें!'
              : 'Please copy the UTR/Transaction ID after payment and paste it below to submit!';
          _success = true;
        });
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      setState(() {
        _success = false;
        _message = lang.isHindi
            ? 'UPI भुगतान शुरू करने में विफल। कृपया पुन: प्रयास करें।'
            : 'Failed to initiate UPI payment. Please try again.';
      });
    }
  }

  void _copyToClipboard(String text, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showZoomedQR(BuildContext context) {
    if (_qrBytes == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Provider.of<LanguageProvider>(context, listen: false).isHindi
                        ? 'स्कैन करके सेस भुगतान करें'
                        : 'Scan to Pay Cess',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _qrBytes!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _upiId,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFFD97706),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCircle(int stepNum) {
    final step = _currentStep;
    final isCompleted = stepNum < step;
    final isActive = stepNum == step;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isCompleted
            ? AppTheme.successGradient
            : (isActive ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]) : null),
        color: !isCompleted && !isActive ? Colors.white : null,
        border: !isCompleted && !isActive ? Border.all(color: AppTheme.borderColor, width: 2) : null,
        boxShadow: isCompleted || isActive
            ? [
                BoxShadow(
                  color: (isCompleted ? AppTheme.successColor : const Color(0xFFD97706)).withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : [],
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                stepNum.toString(),
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }

  Widget _buildStep({
    required int stepNum,
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    final step = _currentStep;
    final isActive = stepNum == step;
    final isCompleted = stepNum < step;
    final isUnlocked = _isStepUnlocked(stepNum);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left timeline indicator
          Column(
            children: [
              _buildStepCircle(stepNum),
              if (stepNum < 3)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: isCompleted ? AppTheme.successColor : AppTheme.borderColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Right content card block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isUnlocked ? AppTheme.textPrimary : AppTheme.textMuted,
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          Provider.of<LanguageProvider>(context, listen: false).isHindi ? 'पूर्ण' : 'Done',
                          style: const TextStyle(
                            color: AppTheme.successColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isUnlocked ? AppTheme.textSecondary : AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Opacity(
                  opacity: isUnlocked ? 1.0 : 0.45,
                  child: AbsorbPointer(
                    absorbing: !isUnlocked,
                    child: Card(
                      elevation: isActive ? 4 : 0,
                      shadowColor: const Color(0xFFD97706).withOpacity(0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isActive
                              ? const Color(0xFFD97706).withOpacity(0.2)
                              : AppTheme.borderColor,
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: content,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationCard(LanguageProvider lang, double winBal, double tds, double netPayable, double cessAmount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: Opacity(
              opacity: 0.12,
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 130,
                color: Colors.white,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (lang.isHindi ? 'जीत निकासी गणना' : 'Winnings Withdrawal Summary').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildCalculationRow(lang.isHindi ? 'जीत बैलेंस' : 'Winning Balance', '₹${winBal.toStringAsFixed(2)}'),
              const Divider(color: Colors.white24, height: 16),
              _buildCalculationRow(
                lang.isHindi ? 'TDS कटौती (30%)' : 'TDS Deduction (30%)',
                tds > 0 ? '- ₹${tds.toStringAsFixed(2)}' : (lang.isHindi ? 'लागू नहीं' : 'Not Applicable'),
              ),
              const Divider(color: Colors.white24, height: 16),
              _buildCalculationRow(
                lang.isHindi ? 'निकासी देय राशि (TDS के बाद)' : 'Net Withdrawal Payout',
                '₹${netPayable.toStringAsFixed(2)}',
                bold: true,
              ),
              const Divider(color: Colors.white38, height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.isHindi ? 'सेस राशि (4%):' : 'Cess Amount (4%):',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lang.isHindi ? '*निकासी अनुरोध से पहले भुगतान आवश्यक' : '*Must be paid before withdrawal',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${cessAmount.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: bold ? Colors.white : Colors.white70,
            fontSize: bold ? 13 : 12,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: _success
            ? AppTheme.successColor.withOpacity(0.08)
            : AppTheme.dangerColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (_success ? AppTheme.successColor : AppTheme.dangerColor).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _success ? Icons.check_circle_outline : Icons.error_outline,
            color: _success ? AppTheme.successColor : AppTheme.dangerColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _message!,
              style: TextStyle(
                color: _success ? AppTheme.successColor : AppTheme.dangerColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _upiIdController.removeListener(_onFieldChanged);
    _bankNameController.removeListener(_onFieldChanged);
    _accountNumberController.removeListener(_onFieldChanged);
    _ifscCodeController.removeListener(_onFieldChanged);
    _accountHolderNameController.removeListener(_onFieldChanged);
    _cessTxnController.removeListener(_onFieldChanged);

    _upiIdController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _accountHolderNameController.dispose();
    _cessTxnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final double winBal = auth.winningBalance;
    final double tds = winBal > 10000 ? winBal * 0.30 : 0.0;
    final double netPayable = winBal - tds;
    final double cessAmount = winBal * 0.04;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text(lang.isHindi ? 'जीत राशि निकासी' : 'Withdraw Winnings'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _fetchingSettings
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD97706)),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Calculation Header Card
                  _buildCalculationCard(lang, winBal, tds, netPayable, cessAmount),
                  const SizedBox(height: 24),

                  // Notification alert box
                  if (_message != null) _buildAlertBox(),

                  // Interactive Vertical Stepper Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Step 1: Choose Payout Method & Details
                        _buildStep(
                          stepNum: 1,
                          title: lang.isHindi ? '1. भुगतान विवरण दर्ज करें' : '1. Enter Payout Details',
                          subtitle: lang.isHindi ? 'UPI या बैंक ट्रांसफर विवरण चुनें' : 'Choose UPI or bank transfer details',
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Method toggle inside step
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgCard,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.borderColor),
                                ),
                                child: Row(
                                  children: [
                                    _MethodTab(
                                      icon: Icons.payment,
                                      label: lang.isHindi ? 'UPI ट्रांसफर' : 'UPI Transfer',
                                      selected: _selectedMethod == 'upi',
                                      onTap: () => setState(() => _selectedMethod = 'upi'),
                                      activeColor: const Color(0xFFD97706),
                                    ),
                                    _MethodTab(
                                      icon: Icons.account_balance,
                                      label: lang.isHindi ? 'बैंक ट्रांसफर' : 'Bank Transfer',
                                      selected: _selectedMethod == 'bank',
                                      onTap: () => setState(() => _selectedMethod = 'bank'),
                                      activeColor: const Color(0xFFD97706),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              AnimatedCrossFade(
                                firstChild: Column(
                                  children: [
                                    TextFormField(
                                      controller: _upiIdController,
                                      decoration: InputDecoration(
                                        labelText: lang.isHindi ? 'आपका UPI ID' : 'Your UPI ID',
                                        prefixIcon: const Icon(Icons.payment, color: AppTheme.textMuted),
                                        hintText: 'e.g., yourname@upi',
                                      ),
                                      validator: (val) {
                                        if (_selectedMethod == 'upi' && (val == null || val.isEmpty)) {
                                          return lang.isHindi ? 'UPI ID दर्ज करें' : 'Enter UPI ID';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                                secondChild: Column(
                                  children: [
                                    TextFormField(
                                      controller: _accountHolderNameController,
                                      decoration: InputDecoration(
                                        labelText: lang.isHindi ? 'खाताधारक का नाम' : 'Account Holder Name',
                                        prefixIcon: const Icon(Icons.person, color: AppTheme.textMuted),
                                      ),
                                      validator: (val) {
                                        if (_selectedMethod == 'bank' && (val == null || val.isEmpty)) {
                                          return lang.isHindi ? 'नाम दर्ज करें' : 'Enter name';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _bankNameController,
                                      decoration: InputDecoration(
                                        labelText: lang.isHindi ? 'बैंक का नाम' : 'Bank Name',
                                        prefixIcon: const Icon(Icons.business, color: AppTheme.textMuted),
                                      ),
                                      validator: (val) {
                                        if (_selectedMethod == 'bank' && (val == null || val.isEmpty)) {
                                          return lang.isHindi ? 'बैंक नाम दर्ज करें' : 'Enter bank name';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _accountNumberController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: lang.isHindi ? 'खाता संख्या' : 'Account Number',
                                        prefixIcon: const Icon(Icons.numbers, color: AppTheme.textMuted),
                                      ),
                                      validator: (val) {
                                        if (_selectedMethod == 'bank') {
                                          if (val == null || val.isEmpty) {
                                            return lang.isHindi ? 'खाता संख्या दर्ज करें' : 'Enter account number';
                                          }
                                          if (val.length < 9) {
                                            return lang.isHindi ? 'अमान्य खाता संख्या' : 'Invalid account number';
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _ifscCodeController,
                                      textCapitalization: TextCapitalization.characters,
                                      decoration: InputDecoration(
                                        labelText: lang.isHindi ? 'IFSC कोड' : 'IFSC Code',
                                        prefixIcon: const Icon(Icons.code, color: AppTheme.textMuted),
                                        hintText: 'e.g., SBIN0001234',
                                      ),
                                      validator: (val) {
                                        if (_selectedMethod == 'bank') {
                                          if (val == null || val.isEmpty) {
                                            return lang.isHindi ? 'IFSC कोड दर्ज करें' : 'Enter IFSC code';
                                          }
                                          if (val.length != 11) {
                                            return lang.isHindi ? 'IFSC 11 वर्णों का होना चाहिए' : 'IFSC must be 11 characters';
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                                crossFadeState: _selectedMethod == 'upi'
                                    ? CrossFadeState.showFirst
                                    : CrossFadeState.showSecond,
                                duration: const Duration(milliseconds: 300),
                              ),
                            ],
                          ),
                        ),

                        // Step 2: Pay 4% Cess
                        _buildStep(
                          stepNum: 2,
                          title: lang.isHindi ? '2. 4% सेस भुगतान करें' : '2. Pay 4% Cess Amount',
                          subtitle: lang.isHindi
                              ? '₹${cessAmount.toStringAsFixed(2)} का सेस एडमिन UPI/QR पर भेजें'
                              : 'Transfer ₹${cessAmount.toStringAsFixed(2)} cess to Admin UPI/QR',
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Scan QR box if loaded
                              if (_qrBytes != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.borderColor),
                                  ),
                                  child: Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _showZoomedQR(context),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.memory(
                                                _qrBytes!,
                                                width: 130,
                                                height: 130,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.75),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.zoom_in, color: Colors.white, size: 10),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      lang.isHindi ? 'बड़ा करें' : 'Tap to Zoom',
                                                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        lang.isHindi
                                          ? '4% सेस राशि ₹${cessAmount.toStringAsFixed(2)} के लिए QR कोड स्कैन करें'
                                          : 'Scan this QR code to pay 4% cess of ₹${cessAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Display UPI ID with copy row
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgPrimary,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lang.isHindi ? 'एडमिन UPI ID (सेस भुगतान के लिए)' : 'ADMIN UPI ID (FOR CESS)',
                                            style: const TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _upiId,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy_rounded, color: Color(0xFFD97706), size: 20),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: _upiId));
                                        _copyToClipboard(_upiId, lang.isHindi ? 'UPI ID कॉपी हो गई!' : 'UPI ID Copied!');
                                      },
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Launch UPI App direct trigger button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _launchUPIApp(cessAmount),
                                  icon: const Icon(Icons.flash_on, color: Colors.white, size: 16),
                                  label: Text(
                                    lang.isHindi ? '⚡ UPI ऐप से सेस भुगतान करें' : '⚡ Pay Cess with UPI App',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black87,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Step 3: Cess Reference Transaction ID & Submit
                        _buildStep(
                          stepNum: 3,
                          title: lang.isHindi ? '3. सेस ट्रांजैक्शन ID दर्ज करें' : '3. Reference ID & Submit',
                          subtitle: lang.isHindi ? 'सेस भुगतान रसीद से 12 अंकों की ID दर्ज करें' : 'Enter 12-digit cess payment ref ID',
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _cessTxnController,
                                decoration: InputDecoration(
                                  labelText: lang.isHindi ? 'सेस UPI ट्रांजैक्शन / UTR ID' : 'Cess UPI Transaction / UTR ID',
                                  prefixIcon: const Icon(Icons.receipt_long, color: AppTheme.textMuted),
                                  hintText: lang.isHindi ? '12 अंकों की txn ID यहां पेस्ट करें' : 'Paste 12-digit txn ID here',
                                ),
                                style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return lang.isHindi ? 'सेस UPI ट्रांजैक्शन ID दर्ज करें' : 'Enter Cess UPI transaction ID';
                                  }
                                  if (val.length < 5) {
                                    return lang.isHindi ? 'अमान्य ट्रांजैक्शन ID' : 'Invalid transaction ID';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 12, color: AppTheme.textMuted),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      lang.isHindi
                                          ? 'GPay में UTR नंबर या PhonePe/Paytm में UPI Ref No. पेस्ट करें।'
                                          : 'Locate 12-digit UTR/Ref No. in payment details screen.',
                                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Submission Trigger
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _handleWithdraw,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD97706),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    shadowColor: const Color(0xFFD97706).withOpacity(0.3),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          lang.isHindi ? 'निकासी अनुरोध सबमिट करें' : 'Submit Withdrawal Request',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      lang.isHindi
                          ? '⏳ एडमिन सत्यापन और TDS कटौती के बाद शेष राशि ट्रांसफर की जाएगी'
                          : '⏳ Net amount will be processed after admin verifies cess payment & TDS',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _MethodTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color activeColor;

  const _MethodTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.activeColor = AppTheme.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? activeColor.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? activeColor : AppTheme.textMuted, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? activeColor : AppTheme.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaxRuleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _TaxRuleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 5),
                Text(body,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalcRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;
  final bool large;

  const _CalcRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.bold = false,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: large ? 13 : 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: large ? 18 : 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
