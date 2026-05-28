import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

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

  // Dynamic UPI settings
  String _upiId = 'lottery@upi';
  Uint8List? _qrBytes;
  bool _fetchingSettings = true;

  final List<int> _quickAmounts = [100, 500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    _loadUPISettings();
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

  Future<void> _handleDeposit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _loading = true; _message = null; });

    try {
      final res = await ApiService().deposit(
        amount: double.parse(_amountController.text),
        upiTransactionId: _upiTxnController.text.trim(),
      );

      setState(() {
        _success = res['success'] == true;
        _message = res['message'] ?? 'Request submitted';
      });

      if (_success) {
        _amountController.clear();
        _upiTxnController.clear();
      }
    } catch (e) {
      setState(() {
        _success = false;
        _message = 'Failed to submit deposit';
      });
    }

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _upiTxnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposit Money'),
      ),
      body: _fetchingSettings
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // UPI Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('💳', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 12),
                        const Text(
                          'Pay via UPI',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Scan the QR code or pay on the UPI ID below,\nthen paste your transaction ID here',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                        if (_qrBytes != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.memory(
                              _qrBytes!,
                              width: 140,
                              height: 140,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          _upiId,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

            // Message
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
                  border: Border.all(
                    color: _success
                        ? AppTheme.successColor.withOpacity(0.3)
                        : AppTheme.dangerColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _success ? AppTheme.successColor : AppTheme.dangerColor,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Quick amounts
            const Text(
              'Quick Amount',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _quickAmounts.map((amt) {
                return GestureDetector(
                  onTap: () => _amountController.text = amt.toString(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Text(
                      '₹$amt',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (₹)',
                      prefixIcon: Icon(Icons.currency_rupee, color: AppTheme.textMuted),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter amount';
                      final amount = double.tryParse(val);
                      if (amount == null || amount < 10) return 'Minimum ₹10';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _upiTxnController,
                    decoration: const InputDecoration(
                      labelText: 'UPI Transaction ID',
                      prefixIcon: Icon(Icons.receipt_long, color: AppTheme.textMuted),
                      hintText: 'Paste your UPI txn ID here',
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter UPI transaction ID';
                      if (val.length < 5) return 'Invalid transaction ID';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleDeposit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                          : const Text('Submit Deposit Request',
                              style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '⏳ Your deposit will be credited after admin verification',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
