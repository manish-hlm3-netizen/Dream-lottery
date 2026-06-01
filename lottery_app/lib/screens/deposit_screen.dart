import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../providers/language_provider.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _upiTxnController = TextEditingController();
  bool _loading = false;
  String? _message;
  bool _success = false;

  // Polling and verification states
  String? _initiatedTxnId;
  bool _isVerifying = false;
  Timer? _pollTimer;

  // Dynamic UPI settings
  String _upiId = 'lottery@upi';
  Uint8List? _qrBytes;
  bool _fetchingSettings = true;

  final List<int> _quickAmounts = [100, 500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    _loadUPISettings();
    _amountController.addListener(_onFieldChanged);
    _upiTxnController.addListener(_onFieldChanged);
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
      setState(() => _fetchingSettings = false);
    }
  }

  int get _currentStep {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return 1;
    final amount = double.tryParse(amountText);
    if (amount == null || amount < 10) return 1;

    if (_initiatedTxnId == null) return 2;

    return 3;
  }

  bool _isStepUnlocked(int stepNum) {
    if (stepNum == 1) return true;
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return false;
    final amount = double.tryParse(amountText);
    return amount != null && amount >= 10;
  }

  void _startPolling(String transactionId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      try {
        final res = await ApiService().getTransactions(page: 1, type: 'deposit');
        if (res['success'] == true && res['data'] != null && res['data']['transactions'] != null) {
          final List txns = res['data']['transactions'];
          
          final matchingTxn = txns.firstWhere(
            (txn) => txn['_id'] == transactionId,
            orElse: () => null,
          );
          
          if (matchingTxn != null) {
            final String status = matchingTxn['status'] ?? 'pending';
            
            if (status == 'approved') {
              _stopPolling();
              
              final lang = Provider.of<LanguageProvider>(context, listen: false);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              
              await auth.getMe();
              
              setState(() {
                _isVerifying = false;
                _success = true;
                _message = lang.isHindi
                    ? '🎉 भुगतान सत्यापित! ₹${matchingTxn['amount']} आपके वॉलेट में जमा कर दिया गया है।'
                    : '🎉 Payment Verified! ₹${matchingTxn['amount']} credited to your wallet.';
                _amountController.clear();
                _initiatedTxnId = null;
              });
            } else if (status == 'rejected') {
              _stopPolling();
              final lang = Provider.of<LanguageProvider>(context, listen: false);
              setState(() {
                _isVerifying = false;
                _success = false;
                _message = lang.isHindi
                    ? '❌ भुगतान अस्वीकार कर दिया गया।'
                    : '❌ Payment rejected by verification.';
                _initiatedTxnId = null;
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Polling transaction status error: $e');
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _handleDeposit() async {
    if (!_formKey.currentState!.validate()) return;
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final res = await ApiService().deposit(
        amount: double.parse(_amountController.text),
        upiTransactionId: _upiTxnController.text.trim(),
      );

      setState(() {
        _success = res['success'] == true;
        _message = res['message'] ??
            (lang.isHindi ? 'अनुरोध सबमिट किया गया' : 'Request submitted');
      });

      if (_success) {
        _amountController.clear();
        _upiTxnController.clear();
      }
    } catch (e) {
      setState(() {
        _success = false;
        _message = lang.isHindi
            ? 'जमा सबमिट करने में विफल'
            : 'Failed to submit deposit';
      });
    }

    setState(() => _loading = false);
  }

  Future<void> _launchUPIApp() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      setState(() {
        _success = false;
        _message = lang.isHindi
            ? 'कृपया पहले जमा राशि दर्ज करें'
            : 'Please enter the deposit amount first';
      });
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount < 10) {
      setState(() {
        _success = false;
        _message = lang.isHindi
            ? 'कृपया एक मान्य राशि दर्ज करें (न्यूनतम ₹10)'
            : 'Please enter a valid amount (minimum ₹10)';
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      // Step A: Initiate the transaction on backend first
      final initRes = await ApiService().initiateDeposit(amount: amount);
      if (initRes['success'] != true || initRes['data'] == null) {
        throw Exception('Initiation failed');
      }

      final String transactionId = initRes['data']['transactionId'];
      setState(() {
        _initiatedTxnId = transactionId;
        _isVerifying = true;
      });

      // Step B: Construct UPI link with the unique "tr" transaction ID parameter
      final Uri uri = Uri.parse(
          'upi://pay?pa=$_upiId&pn=Lottery&am=${amount.toStringAsFixed(2)}&tr=$transactionId&cu=INR&tn=Lottery%20Deposit');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      setState(() {
        _message = lang.isHindi
            ? 'भुगतान पूरा करें और ऑटो-सत्यापन के लिए वापस लौटें!'
            : 'Complete the payment and return here for automatic verification!';
        _success = true;
      });

      // Step C: Start polling for payment success
      _startPolling(transactionId);

    } catch (e) {
      setState(() {
        _success = false;
        _message = lang.isHindi
            ? 'UPI भुगतान शुरू करने में विफल। कृपया पुन: प्रयास करें।'
            : 'Failed to initiate UPI payment. Please try again.';
      });
    } finally {
      setState(() => _loading = false);
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
                        ? 'स्कैन करके भुगतान करें'
                        : 'Scan to Pay',
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
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopPolling();
    _amountController.removeListener(_onFieldChanged);
    _upiTxnController.removeListener(_onFieldChanged);
    _amountController.dispose();
    _upiTxnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text(lang.isHindi ? 'पैसे जमा करें' : 'Deposit Money'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      ),
      body: _fetchingSettings
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Available Balance Premium Card
                  _buildBalanceCard(lang, auth),
                  const SizedBox(height: 24),

                  // Notification alert box
                  if (_message != null) _buildAlertBox(),

                  // Interactive Vertical Stepper Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Step 1: Deposit Amount
                        _buildStep(
                          stepNum: 1,
                          title: lang.isHindi ? '1. जमा राशि दर्ज करें' : '1. Enter Deposit Amount',
                          subtitle: lang.isHindi ? 'न्यूनतम जमा राशि ₹10 है' : 'Minimum deposit amount is ₹10',
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: lang.isHindi ? 'जमा राशि (₹)' : 'Deposit Amount (₹)',
                                  prefixIcon: const Icon(Icons.currency_rupee, color: AppTheme.textMuted),
                                ),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return lang.isHindi ? 'राशि दर्ज करें' : 'Enter amount';
                                  }
                                  final amount = double.tryParse(val);
                                  if (amount == null || amount < 10) {
                                    return lang.isHindi ? 'न्यूनतम ₹10' : 'Minimum ₹10';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Text(
                                lang.isHindi ? "त्वरित राशि:" : "Quick Select Amount:",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildQuickAmounts(lang),
                            ],
                          ),
                        ),

                        // Step 2: Pay via UPI
                        _buildStep(
                          stepNum: 2,
                          title: lang.isHindi ? '2. UPI के माध्यम से भुगतान' : '2. Transfer via UPI',
                          subtitle: lang.isHindi ? 'UPI ऐप से भुगतान करें या QR स्कैन करें' : 'Launch UPI app or scan scanning QR',
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
                                        lang.isHindi ? 'QR कोड स्कैन करके भुगतान करें' : 'Scan this QR code to complete payment',
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
                                            lang.isHindi ? 'मर्चेंट UPI ID' : 'MERCHANT UPI ID',
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
                                      icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryColor, size: 20),
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
                                  onPressed: _launchUPIApp,
                                  icon: const Icon(Icons.flash_on, color: Colors.white, size: 16),
                                  label: Text(
                                    lang.isHindi ? '⚡ UPI ऐप से भुगतान करें' : '⚡ Pay with UPI App',
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

                        // Step 3: Automatic Verification with manual backup
                        _buildStep(
                          stepNum: 3,
                          title: lang.isHindi ? '3. ऑटो-सत्यापन स्थिति' : '3. Automatic Verification',
                          subtitle: lang.isHindi 
                              ? 'भुगतान के बाद आपका बैलेंस तुरंत अपडेट हो जाएगा' 
                              : 'Your balance will credit automatically after payment',
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_isVerifying)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    children: [
                                      const SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        lang.isHindi 
                                            ? '⏳ भुगतान सत्यापन की प्रतीक्षा कर रहे हैं...' 
                                            : '⏳ Waiting for payment verification...',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        lang.isHindi
                                            ? 'कृपया इस स्क्रीन को बंद न करें। भुगतान पूरा होने के बाद balance स्वतः अपडेट हो जाएगा।'
                                            : 'Please do not close this screen. Once the payment is complete, the balance will update automatically.',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textSecondary,
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              else if (_success && _initiatedTxnId == null && _amountController.text.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified_user_rounded, color: AppTheme.successColor, size: 24),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          lang.isHindi 
                                              ? 'भुगतान सफलतापूर्वक प्राप्त और सत्यापित हुआ!' 
                                              : 'Payment successfully received and verified!',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.successColor,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.borderColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    lang.isHindi 
                                        ? '⚡ भुगतान शुरू करने के बाद सत्यापन शुरू होगा।' 
                                        : '⚡ Verification starts automatically after pay app launches.',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              const SizedBox(height: 12),
                              
                              // Legacy manual fallback option (Expandable)
                              Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  title: Text(
                                    lang.isHindi 
                                        ? 'मैन्युअल रूप से UTR ID दर्ज करें (वैकल्पिक)' 
                                        : 'Submit UTR ID manually (Fallback)',
                                    style: const TextStyle(
                                      fontSize: 11, 
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  tilePadding: EdgeInsets.zero,
                                  children: [
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _upiTxnController,
                                      decoration: InputDecoration(
                                        labelText: lang.isHindi ? 'UPI ट्रांजैक्शन / UTR ID' : 'UPI Transaction / UTR ID',
                                        prefixIcon: const Icon(Icons.receipt_long, color: AppTheme.textMuted),
                                        hintText: lang.isHindi ? '12 अंकों की txn ID यहां पेस्ट करें' : 'Paste 12-digit txn ID here',
                                      ),
                                      style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 40,
                                      child: ElevatedButton(
                                        onPressed: _loading ? null : _handleDeposit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.successColor,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: _loading
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                lang.isHindi ? 'मैन्युअल अनुरोध सबमिट करें' : 'Submit Manual Request',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
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

                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      lang.isHindi
                          ? '⏳ व्यवस्थापक सत्यापन के बाद आपका जमा क्रेडिट किया जाएगा'
                          : '⏳ Your deposit will be credited after admin verification',
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

  Widget _buildBalanceCard(LanguageProvider lang, AuthProvider auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.15),
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
              child: Icon(
                Icons.account_balance_wallet_rounded,
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
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    lang.translate('available_balance').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '₹${auth.walletBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  lang.isHindi ? '⚡ सुरक्षित और त्वरित जमा' : '⚡ Secure & Instant Credit',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
            : (isActive ? AppTheme.primaryGradient : null),
        color: !isCompleted && !isActive ? Colors.white : null,
        border: !isCompleted && !isActive ? Border.all(color: AppTheme.borderColor, width: 2) : null,
        boxShadow: isCompleted || isActive
            ? [
                BoxShadow(
                  color: (isCompleted ? AppTheme.successColor : AppTheme.primaryColor).withOpacity(0.25),
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
                      shadowColor: AppTheme.primaryColor.withOpacity(0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isActive
                              ? AppTheme.primaryColor.withOpacity(0.2)
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

  Widget _buildQuickAmounts(LanguageProvider lang) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _quickAmounts.map((amt) {
        final isSelected = _amountController.text == amt.toString();
        return InkWell(
          onTap: () {
            _amountController.text = amt.toString();
            FocusScope.of(context).unfocus();
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected ? AppTheme.primaryGradient : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.transparent : AppTheme.borderColor,
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Text(
              '₹$amt',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
