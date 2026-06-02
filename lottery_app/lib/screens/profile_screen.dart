import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isPinSet = false;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    final pin = await StorageService.getPin();
    if (mounted) {
      setState(() {
        _isPinSet = pin != null && pin.isNotEmpty;
      });
    }
  }

  void _showDisablePinDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Disable Security PIN', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your current 4-digit Security PIN to disable app locking:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(
                hintText: 'Enter 4-digit PIN',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = controller.text;
              final savedPin = await StorageService.getPin();
              if (pin == savedPin) {
                await StorageService.deletePin();
                if (mounted) {
                  Navigator.pop(dialogContext); // Close dialog
                  _checkPinStatus(); // Refresh state
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Security PIN successfully disabled.')),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Incorrect PIN. Security PIN remains enabled.'),
                      backgroundColor: AppTheme.dangerColor,
                    ),
                  );
                  Navigator.pop(dialogContext); // Close dialog
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Disable', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Stack(
        children: [
          // Premium Curved Background Banner with artistic design elements
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 240,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Glowing Accent Circle 1
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  // Glowing Accent Circle 2
                  Positioned(
                    bottom: -30,
                    left: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  // Diagonal Art Stripe
                  Positioned(
                    top: 60,
                    left: -30,
                    child: Transform.rotate(
                      angle: -0.3,
                      child: Container(
                        width: 250,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  // Decorative Stars
                  Positioned(
                    top: 40,
                    right: 80,
                    child: Icon(
                      Icons.star,
                      size: 20,
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    right: 40,
                    child: Icon(
                      Icons.circle,
                      size: 10,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Layout sitting on top of the banner canvas
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Consumer<AuthProvider>(
                builder: (ctx, auth, _) {
                  return Column(
                    children: [
                      const SizedBox(height: 50), // Padding to position the avatar card beautifully

                      // Overlapping Floating Profile Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Column(
                          children: [
                            // Avatar floating over the curved banner border line
                            Transform.translate(
                              offset: const Offset(0, -45),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  width: 85,
                                  height: 85,
                                  decoration: const BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      auth.userName.isNotEmpty
                                          ? auth.userName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Name and Email detail elements translated up
                            Transform.translate(
                              offset: const Offset(0, -25),
                              child: Column(
                                children: [
                                  Text(
                                    auth.userName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    auth.userEmail,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Wallet Balance & Profile Action List
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Wallet Balance
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.bgCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppTheme.successColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.account_balance_wallet,
                                        color: AppTheme.successColor),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lang.translate('wallet_balance'),
                                        style: const TextStyle(
                                            color: AppTheme.textMuted, fontSize: 12),
                                      ),
                                      Text(
                                        '₹${(auth.walletBalance + auth.referralBalance).toStringAsFixed(0)}',
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
                            ),
                            const SizedBox(height: 16),

                            // List of Action Items
                            _ProfileMenuItem(
                              icon: Icons.confirmation_number_outlined,
                              label: lang.translate('my_tickets'),
                              onTap: () => Navigator.pushNamed(context, '/my-tickets'),
                            ),
                            _ProfileMenuItem(
                              icon: Icons.emoji_events_outlined,
                              label: lang.translate('results'),
                              onTap: () => Navigator.pushNamed(context, '/results'),
                            ),
                            _ProfileMenuItem(
                              icon: Icons.stars_outlined,
                              label: lang.isHindi ? "हाल ही के विजेता 🏆" : "Recent Winners 🏆",
                              onTap: () => Navigator.pushNamed(context, '/recent-winners'),
                            ),
                            _ProfileMenuItem(
                              icon: Icons.history,
                              label: lang.translate('txn_history'),
                              onTap: () => Navigator.pushNamed(context, '/wallet'),
                            ),
                            _ProfileMenuItem(
                              icon: Icons.campaign_outlined,
                              label: lang.translate('announcements'),
                              onTap: () => Navigator.pushNamed(context, '/announcements'),
                            ),
                            _ProfileMenuItem(
                              icon: Icons.card_giftcard_outlined,
                              label: '${lang.translate('refer_earn')} 🎁',
                              onTap: () => Navigator.pushNamed(context, '/referrals'),
                            ),
                            
                            // NATIVE SECURITY PIN OPTIONS
                            !_isPinSet
                                ? _ProfileMenuItem(
                                    icon: Icons.lock_open_outlined,
                                    label: 'Set Security PIN 🔑',
                                    onTap: () async {
                                      final res = await Navigator.pushNamed(
                                        context, 
                                        '/security-pin', 
                                        arguments: {'mode': 'setup'}
                                      );
                                      if (res == true) {
                                        _checkPinStatus();
                                      }
                                    },
                                  )
                                : Column(
                                    children: [
                                      _ProfileMenuItem(
                                        icon: Icons.lock_outline,
                                        label: 'Change Security PIN 🔑',
                                        onTap: () async {
                                          final res = await Navigator.pushNamed(
                                            context, 
                                            '/security-pin', 
                                            arguments: {'mode': 'change'}
                                          );
                                          if (res == true) {
                                            _checkPinStatus();
                                          }
                                        },
                                      ),
                                      _ProfileMenuItem(
                                        icon: Icons.lock_reset_outlined,
                                        label: 'Disable Security PIN 🚫',
                                        onTap: _showDisablePinDialog,
                                      ),
                                    ],
                                  ),

                            _ProfileMenuItem(
                              icon: Icons.chat_bubble_outline,
                              label: '${lang.translate('chat_support')} 💬',
                              onTap: () => Navigator.pushNamed(context, '/support-chat'),
                            ),
                            _ProfileMenuItem(
                              icon: Icons.translate,
                              label: '${lang.translate('change_language')} (${lang.isHindi ? 'हिंदी' : 'English'})',
                              onTap: () => lang.toggleLanguage(),
                            ),
                            const SizedBox(height: 24),

                            // Logout Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await auth.logout();
                                  if (mounted) {
                                    Navigator.pushReplacementNamed(context, '/login');
                                  }
                                },
                                icon: const Icon(Icons.logout, color: AppTheme.dangerColor),
                                label: Text(
                                  lang.translate('logout'),
                                  style: const TextStyle(
                                    color: AppTheme.dangerColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppTheme.dangerColor.withOpacity(0.3)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
