import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../providers/language_provider.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _accountHolderNameController = TextEditingController();

  String _selectedMethod = 'upi'; // 'upi' or 'bank'
  bool _loading = false;
  String? _message;
  bool _success = false;

  Future<void> _handleWithdraw() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final amount = double.parse(_amountController.text);

    final lang = Provider.of<LanguageProvider>(context, listen: false);
    if (amount > auth.walletBalance) {
      setState(() {
        _success = false;
        _message = lang.isHindi 
            ? 'अपर्याप्त बैलेंस। उपलब्ध: ₹${auth.walletBalance.toStringAsFixed(0)}'
            : 'Insufficient balance. Available: ₹${auth.walletBalance.toStringAsFixed(0)}';
      });
      return;
    }

    setState(() { _loading = true; _message = null; });

    try {
      final res = await ApiService().withdraw(
        amount: amount,
        method: _selectedMethod,
        upiId: _selectedMethod == 'upi' ? _upiIdController.text.trim() : null,
        bankName: _selectedMethod == 'bank' ? _bankNameController.text.trim() : null,
        accountNumber: _selectedMethod == 'bank' ? _accountNumberController.text.trim() : null,
        ifscCode: _selectedMethod == 'bank' ? _ifscCodeController.text.trim().toUpperCase() : null,
        accountHolderName: _selectedMethod == 'bank' ? _accountHolderNameController.text.trim() : null,
      );

      setState(() {
        _success = res['success'] == true;
        _message = res['message'] ?? (lang.isHindi ? 'अनुरोध सबमिट किया गया' : 'Request submitted');
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
    } catch (e) {
      setState(() {
        _success = false;
        _message = lang.isHindi ? 'निकासी सबमिट करने में विफल' : 'Failed to submit withdrawal';
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
      appBar: AppBar(title: Text(lang.isHindi ? 'पैसे निकालें' : 'Withdraw Money')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance display
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return Container(
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
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.account_balance_wallet,
                            color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lang.isHindi ? 'निकासी योग्य बैलेंस' : 'Withdrawable Balance',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          Text(
                            '₹${auth.walletBalance.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Premium Payout Method Toggle Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedMethod = 'upi'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedMethod == 'upi'
                              ? AppTheme.primaryColor.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payment,
                              color: _selectedMethod == 'upi' ? AppTheme.primaryColor : AppTheme.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              lang.isHindi ? 'UPI ट्रांसफर' : 'UPI Transfer',
                              style: TextStyle(
                                color: _selectedMethod == 'upi' ? AppTheme.primaryColor : AppTheme.textMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedMethod = 'bank'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedMethod == 'bank'
                              ? AppTheme.primaryColor.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance,
                              color: _selectedMethod == 'bank' ? AppTheme.primaryColor : AppTheme.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              lang.isHindi ? 'बैंक ट्रांसफर' : 'Bank Transfer',
                              style: TextStyle(
                                color: _selectedMethod == 'bank' ? AppTheme.primaryColor : AppTheme.textMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                    color: _success ? AppTheme.successColor : AppTheme.dangerColor,
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
                      prefixIcon: const Icon(Icons.currency_rupee, color: AppTheme.textMuted),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return lang.isHindi ? 'राशि दर्ज करें' : 'Enter amount';
                      final amount = double.tryParse(val);
                      if (amount == null || amount < 100) return lang.isHindi ? 'न्यूनतम ₹100' : 'Minimum ₹100';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Dynamic forms with clean animation transitions
                  AnimatedCrossFade(
                    firstChild: Column(
                      children: [
                        TextFormField(
                          controller: _upiIdController,
                          decoration: InputDecoration(
                            labelText: lang.isHindi ? 'आपका UPI ID' : 'Your UPI ID',
                            prefixIcon: const Icon(Icons.payment, color: AppTheme.textMuted),
                            hintText: lang.isHindi ? 'जैसे, yourname@upi' : 'e.g., yourname@upi',
                          ),
                          validator: (val) {
                            if (_selectedMethod == 'upi') {
                              if (val == null || val.isEmpty) return lang.isHindi ? 'अपनी UPI ID दर्ज करें' : 'Enter your UPI ID';
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
                            if (_selectedMethod == 'bank') {
                              if (val == null || val.isEmpty) return lang.isHindi ? 'खाताधारक का नाम दर्ज करें' : 'Enter account holder name';
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
                            if (_selectedMethod == 'bank') {
                              if (val == null || val.isEmpty) return lang.isHindi ? 'बैंक का नाम दर्ज करें' : 'Enter bank name';
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
                              if (val == null || val.isEmpty) return lang.isHindi ? 'खाता संख्या दर्ज करें' : 'Enter account number';
                              if (val.length < 9) return lang.isHindi ? 'अमान्य खाता संख्या' : 'Invalid account number';
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
                              if (val == null || val.isEmpty) return lang.isHindi ? 'IFSC कोड दर्ज करें' : 'Enter IFSC code';
                              if (val.length != 11) return lang.isHindi ? 'IFSC कोड 11 वर्णों का होना चाहिए' : 'IFSC code must be 11 characters';
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
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                          : Text(
                              lang.isHindi ? 'निकासी अनुरोध सबमिट करें' : 'Submit Withdrawal Request',
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
                  ? '⏳ व्यवस्थापक द्वारा अनुरोध संसाधित किए जाने तक राशि आपके वॉलेट से रोकी जाएगी' 
                  : '⏳ Amount will be held from your wallet until admin processes the request',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
