import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    if (amount > auth.winningBalance) {
      setState(() {
        _success = false;
        _message = lang.isHindi
            ? 'अपर्याप्त जीत बैलेंस। उपलब्ध: ₹${auth.winningBalance.toStringAsFixed(0)}'
            : 'Insufficient winning balance. Available: ₹${auth.winningBalance.toStringAsFixed(0)}';
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      // Winning withdrawal uses same API but admin handles TDS
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
        title: Text(lang.isHindi ? 'जीत राशि निकासी' : 'Withdraw Winnings'),
        backgroundColor: const Color(0xFFD97706),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Winning balance + TDS reminder
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final tds = auth.winningBalance > 10000
                    ? auth.winningBalance * 0.30
                    : 0.0;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lang.isHindi ? 'जीत बैलेंस' : 'Winning Balance',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12),
                          ),
                          Text(
                            '₹${auth.winningBalance.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      if (tds > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang.isHindi
                                    ? '⚠️ TDS (30%) काटा जाएगा'
                                    : '⚠️ TDS (30%) will be deducted',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11),
                              ),
                              Text(
                                '- ₹${tds.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
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
                      color: _success
                          ? AppTheme.successColor
                          : AppTheme.dangerColor,
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
                      prefixIcon: const Icon(Icons.currency_rupee,
                          color: AppTheme.textMuted),
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
                            hintText: 'e.g., yourname@upi',
                          ),
                          validator: (val) {
                            if (_selectedMethod == 'upi' &&
                                (val == null || val.isEmpty))
                              return lang.isHindi
                                  ? 'UPI ID दर्ज करें'
                                  : 'Enter UPI ID';
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
                            prefixIcon: const Icon(Icons.person,
                                color: AppTheme.textMuted),
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
                            prefixIcon: const Icon(Icons.code,
                                color: AppTheme.textMuted),
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
                        backgroundColor: const Color(0xFFD97706),
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
                  ? '⏳ एडमिन TDS काटकर शेष राशि आपके खाते में ट्रांसफर करेगा'
                  : '⏳ Admin will deduct TDS and transfer the net amount to your account',
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
