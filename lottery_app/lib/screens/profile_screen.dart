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
                  Navigator.pop(dialogContext);
                  _checkPinStatus();
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
                  Navigator.pop(dialogContext);
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
          // Premium Curved Background Banner
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 180,
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
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    left: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 30,
                    right: 70,
                    child: Icon(Icons.star, size: 16, color: Colors.white.withOpacity(0.12)),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Consumer<AuthProvider>(
                builder: (ctx, auth, _) {
                  return Column(
                    children: [
                      const SizedBox(height: 30),

                      // ── Compact Profile Card ──
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            // Small Avatar Circle
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Container(
                                width: 54,
                                height: 54,
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
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Name & Email
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auth.userName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    auth.userEmail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Balance Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.successColor.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    lang.translate('wallet_balance'),
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '₹${(auth.walletBalance + auth.referralBalance).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.successColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Menu Items ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
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

                            !_isPinSet
                                ? _ProfileMenuItem(
                                    icon: Icons.lock_open_outlined,
                                    label: 'Set Security PIN 🔑',
                                    onTap: () async {
                                      final res = await Navigator.pushNamed(
                                        context,
                                        '/security-pin',
                                        arguments: {'mode': 'setup'},
                                      );
                                      if (res == true) _checkPinStatus();
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
                                            arguments: {'mode': 'change'},
                                          );
                                          if (res == true) _checkPinStatus();
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

                            const SizedBox(height: 8),

                            // ── HOW TO PLAY SECTION ──
                            _HowToPlaySection(lang: lang),

                            const SizedBox(height: 20),

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
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
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

// ─────────────────────────────────────────────────────────────
// HOW TO PLAY SECTION WIDGET
// ─────────────────────────────────────────────────────────────

class _HowToPlaySection extends StatelessWidget {
  final LanguageProvider lang;
  const _HowToPlaySection({required this.lang});

  @override
  Widget build(BuildContext context) {
    final isHindi = lang.isHindi;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.12),
                  AppTheme.primaryColor.withOpacity(0.04),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.menu_book_rounded,
                      color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  isHindi ? 'कैसे खेलें? 📖' : 'How to Play? 📖',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Expandable tiles
          _HowToTile(
            icon: Icons.confirmation_number,
            iconColor: const Color(0xFF6366F1),
            title: isHindi ? 'लॉटरी टिकट कैसे खरीदें?' : 'How to Buy a Lottery Ticket?',
            steps: isHindi
                ? [
                    '1. होम या लॉटरी टैब पर जाएं',
                    '2. कोई भी सक्रिय लॉटरी चुनें',
                    '3. अपने ${_bold("pickCount")} नंबर 1 से maxNumber तक चुनें',
                    '4. "टिकट खरीदें" बटन दबाएं',
                    '5. आपके वॉलेट से राशि कट जाएगी',
                    '6. एक लॉटरी पर अधिकतम 3 टिकट',
                  ]
                : [
                    '1. Go to Home or Lottery tab',
                    '2. Select any active lottery',
                    '3. Pick your lucky numbers (1 to maxNumber)',
                    '4. Tap the "Buy Ticket" button',
                    '5. Ticket price is deducted from your wallet',
                    '6. Maximum 3 tickets per lottery per user',
                  ],
          ),

          _HowToTile(
            icon: Icons.account_balance_wallet,
            iconColor: const Color(0xFF10B981),
            title: isHindi ? 'वॉलेट में पैसे कैसे जमा करें?' : 'How to Deposit into Wallet?',
            steps: isHindi
                ? [
                    '1. वॉलेट टैब पर जाएं',
                    '2. "जमा करें" बटन दबाएं',
                    '3. UPI ID या QR कोड से पेमेंट करें',
                    '4. स्क्रीनशॉट और UTR नंबर दर्ज करें',
                    '5. सबमिट करें — एडमिन द्वारा 24 घंटे में अप्रूव',
                    '6. अप्रूवल के बाद बैलेंस वॉलेट में जुड़ेगा',
                  ]
                : [
                    '1. Go to the Wallet tab',
                    '2. Tap the "Deposit" button',
                    '3. Pay via UPI ID or QR code shown',
                    '4. Enter your UTR number & upload screenshot',
                    '5. Submit — Admin approves within 24 hours',
                    '6. Balance is added after approval',
                  ],
          ),

          _HowToTile(
            icon: Icons.upload_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: isHindi ? 'पैसे कैसे निकालें?' : 'How to Withdraw Winnings?',
            steps: isHindi
                ? [
                    '1. वॉलेट टैब पर जाएं',
                    '2. "निकासी करें" बटन दबाएं',
                    '3. निकासी राशि और UPI ID दर्ज करें',
                    '4. सबमिट करें — एडमिन प्रोसेस करेगा',
                    '5. न्यूनतम निकासी राशि: ₹100',
                    '6. सामान्यतः 24-48 घंटों में क्रेडिट होता है',
                  ]
                : [
                    '1. Go to the Wallet tab',
                    '2. Tap the "Withdraw" button',
                    '3. Enter amount and your UPI ID',
                    '4. Submit — Admin processes your request',
                    '5. Minimum withdrawal amount: ₹100',
                    '6. Usually credited within 24-48 hours',
                  ],
          ),

          _HowToTile(
            icon: Icons.emoji_events,
            iconColor: const Color(0xFFEF4444),
            title: isHindi ? 'जीत की राशि कैसे बांटी जाती है?' : 'How are Prize Winnings Split?',
            steps: isHindi
                ? [
                    '🥇 रैंक 1 — सर्वोच्च पुरस्कार राशि',
                    '🥈 रैंक 2 — दूसरी सबसे बड़ी राशि',
                    '🥉 रैंक 3 — तीसरी राशि',
                    '4️⃣ रैंक 4–10 — समान पुरस्कार राशि',
                    '⚡ टाई: समान नंबर वाले टिकटों पर पुरस्कार समान रूप से बांटा जाता है',
                    '💡 उदाहरण: 2 टिकट टाई → हर एक को आधा पुरस्कार',
                  ]
                : [
                    '🥇 Rank 1 — Highest prize amount',
                    '🥈 Rank 2 — Second highest prize',
                    '🥉 Rank 3 — Third prize amount',
                    '4️⃣ Rank 4–10 — Equal prize for all',
                    '⚡ Tie Rule: Prize is split equally among tickets with identical winning numbers',
                    '💡 Example: 2 tickets tie → each gets 50% of prize',
                  ],
          ),

          _HowToTile(
            icon: Icons.gavel_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: isHindi ? 'नियम एवं शर्तें' : 'Rules & Regulations',
            steps: isHindi
                ? [
                    '✅ खेलने की न्यूनतम आयु: 18 वर्ष',
                    '✅ एक लॉटरी पर अधिकतम 3 टिकट प्रति यूजर',
                    '✅ ड्रा की तारीख के बाद टिकट वापस नहीं होगा',
                    '✅ जीत की राशि सीधे वॉलेट में जमा होगी',
                    '✅ धोखाधड़ी पाए जाने पर खाता बंद किया जाएगा',
                    '✅ एडमिन का निर्णय अंतिम एवं बाध्यकारी होगा',
                    '✅ रेफरल बोनस केवल नए यूजर के लिए मान्य है',
                  ]
                : [
                    '✅ Minimum age to play: 18 years',
                    '✅ Max 3 tickets per lottery per user',
                    '✅ No refunds after draw date has passed',
                    '✅ Winnings are credited directly to wallet',
                    '✅ Accounts found cheating will be banned',
                    '✅ Admin decision is final and binding',
                    '✅ Referral bonus valid for new users only',
                  ],
          ),

          _HowToTile(
            icon: Icons.card_giftcard,
            iconColor: const Color(0xFF0EA5E9),
            title: isHindi ? 'रेफरल बोनस कैसे काम करता है?' : 'How does Referral Bonus Work?',
            steps: isHindi
                ? [
                    '1. प्रोफ़ाइल → "रेफर करें और कमाएं" पर जाएं',
                    '2. अपना यूनीक रेफरल कोड शेयर करें',
                    '3. दोस्त कोड से रजिस्टर करें → उन्हें ₹20 मिलेगा',
                    '4. आपको ₹50 रेफरल बैलेंस मिलेगा',
                    '5. रेफरल बैलेंस से टिकट खरीदे जा सकते हैं',
                    '6. रेफरल बैलेंस को निकाला नहीं जा सकता',
                  ]
                : [
                    '1. Go to Profile → "Refer & Earn"',
                    '2. Share your unique referral code',
                    '3. Friend registers with your code → they get ₹20',
                    '4. You earn ₹50 referral balance instantly',
                    '5. Referral balance can be used to buy tickets',
                    '6. Referral balance cannot be withdrawn directly',
                  ],
            isLast: true,
          ),
        ],
      ),
    );
  }

  String _bold(String text) => text; // placeholder for formatting
}

// ─────────────────────────────────────────────────────────────
// EXPANDABLE HOW-TO TILE WIDGET
// ─────────────────────────────────────────────────────────────

class _HowToTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> steps;
  final bool isLast;

  const _HowToTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.steps,
    this.isLast = false,
  });

  @override
  State<_HowToTile> createState() => _HowToTileState();
}

class _HowToTileState extends State<_HowToTile> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _rotateAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: _toggle,
          borderRadius: widget.isLast
              ? const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                )
              : BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: widget.iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(widget.icon, color: widget.iconColor, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                RotationTransition(
                  turns: _rotateAnim,
                  child: const Icon(Icons.expand_more,
                      color: AppTheme.textMuted, size: 20),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.iconColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.iconColor.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.steps.map((step) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text(
                    step,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        if (!widget.isLast)
          const Divider(height: 1, color: AppTheme.borderColor, indent: 16, endIndent: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PROFILE MENU ITEM WIDGET
// ─────────────────────────────────────────────────────────────

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
