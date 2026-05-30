import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';

class SecurityPinScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const SecurityPinScreen({super.key, this.arguments});

  @override
  State<SecurityPinScreen> createState() => _SecurityPinScreenState();
}

class _SecurityPinScreenState extends State<SecurityPinScreen> {
  String _enteredPin = '';
  String _firstEnteredPin = ''; // Used for setup mode confirmation
  String _mode = 'unlock'; // 'unlock', 'setup', 'change'
  String _setupStep = 'enter_new'; // 'enter_new', 'confirm_new'
  String _changeStep = 'enter_current'; // 'enter_current', 'enter_new', 'confirm_new'
  String _statusMessage = '';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    // Safely extract mode from route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = widget.arguments ?? ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('mode')) {
        setState(() {
          _mode = args['mode'];
          _updateStatusMessage();
        });
      } else {
        _updateStatusMessage();
      }
    });
  }

  void _updateStatusMessage() {
    setState(() {
      _isError = false;
      if (_mode == 'unlock') {
        _statusMessage = 'Enter your 4-digit Security PIN';
      } else if (_mode == 'setup') {
        if (_setupStep == 'enter_new') {
          _statusMessage = 'Create a 4-digit Security PIN';
        } else {
          _statusMessage = 'Confirm your Security PIN';
        }
      } else if (_mode == 'change') {
        if (_changeStep == 'enter_current') {
          _statusMessage = 'Enter your current Security PIN';
        } else if (_changeStep == 'enter_new') {
          _statusMessage = 'Enter your new 4-digit PIN';
        } else {
          _statusMessage = 'Confirm your new PIN';
        }
      }
    });
  }

  void _onKeyPress(String value) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += value;
        _isError = false;
      });

      if (_enteredPin.length == 4) {
        // Wait a split second to let the last indicator fill up, then process
        Future.delayed(const Duration(milliseconds: 250), _processPin);
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _isError = false;
      });
    }
  }

  Future<void> _processPin() async {
    final entered = _enteredPin;
    setState(() {
      _enteredPin = ''; // Reset input immediately
    });

    if (_mode == 'unlock') {
      final savedPin = await StorageService.getPin();
      if (entered == savedPin) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        setState(() {
          _isError = true;
          _statusMessage = 'Incorrect Security PIN. Please try again.';
        });
      }
    } else if (_mode == 'setup') {
      if (_setupStep == 'enter_new') {
        setState(() {
          _firstEnteredPin = entered;
          _setupStep = 'confirm_new';
          _updateStatusMessage();
        });
      } else {
        if (entered == _firstEnteredPin) {
          await StorageService.savePin(entered);
          setState(() {
            _statusMessage = 'Security PIN successfully enabled!';
          });
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          setState(() {
            _isError = true;
            _setupStep = 'enter_new';
            _firstEnteredPin = '';
            _statusMessage = 'PINs did not match. Start over.';
          });
        }
      }
    } else if (_mode == 'change') {
      if (_changeStep == 'enter_current') {
        final savedPin = await StorageService.getPin();
        if (entered == savedPin) {
          setState(() {
            _changeStep = 'enter_new';
            _updateStatusMessage();
          });
        } else {
          setState(() {
            _isError = true;
            _statusMessage = 'Incorrect current PIN. Please try again.';
          });
        }
      } else if (_changeStep == 'enter_new') {
        setState(() {
          _firstEnteredPin = entered;
          _changeStep = 'confirm_new';
          _updateStatusMessage();
        });
      } else {
        if (entered == _firstEnteredPin) {
          await StorageService.savePin(entered);
          setState(() {
            _statusMessage = 'Security PIN successfully updated!';
          });
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          setState(() {
            _isError = true;
            _changeStep = 'enter_new';
            _firstEnteredPin = '';
            _updateStatusMessage();
            _statusMessage = 'PINs did not match. Try setting new PIN again.';
          });
        }
      }
    }
  }

  Future<void> _handleForgottenPin() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Forgot Security PIN?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'For your security, if you forget your PIN you must log out of your account and log back in to reset it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final auth = context.read<AuthProvider>();
              await auth.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout & Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Top spacing and optional close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _mode != 'unlock'
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary, size: 20),
                          onPressed: () => Navigator.pop(context),
                        )
                      : const SizedBox(width: 40),
                  Text(
                    _mode == 'unlock'
                        ? 'App Locked'
                        : _mode == 'setup'
                            ? 'Setup PIN'
                            : 'Change PIN',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const Spacer(flex: 1),

            // Icon lock illustration
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isError 
                    ? AppTheme.dangerColor.withOpacity(0.1) 
                    : AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isError ? Icons.lock_open : Icons.lock_outline,
                size: 40,
                color: _isError ? AppTheme.dangerColor : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),

            // Instruction Message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _isError ? AppTheme.dangerColor : AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 4-Digit Display Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isError 
                          ? AppTheme.dangerColor 
                          : AppTheme.primaryColor, 
                      width: 2
                    ),
                    color: isFilled 
                        ? (_isError ? AppTheme.dangerColor : AppTheme.primaryColor) 
                        : Colors.transparent,
                  ),
                );
              }),
            ),
            const Spacer(flex: 2),

            // Custom Keypad Matrix
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildKeypadRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildKeypadRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Action left key
                      _mode == 'unlock'
                          ? TextButton(
                              onPressed: _handleForgottenPin,
                              child: const Text(
                                'Forgot PIN',
                                style: TextStyle(
                                  color: AppTheme.dangerColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : const SizedBox(width: 70),

                      _buildKeypadButton('0'),

                      // Action right backspace key
                      GestureDetector(
                        onTap: _onBackspace,
                        child: Container(
                          width: 70,
                          height: 70,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.backspace_outlined,
                            size: 24,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: values.map((val) => _buildKeypadButton(val)).toList(),
    );
  }

  Widget _buildKeypadButton(String value) {
    return GestureDetector(
      onTap: () => _onKeyPress(value),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppTheme.borderColor),
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
