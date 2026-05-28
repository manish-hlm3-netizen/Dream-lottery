import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../providers/language_provider.dart';

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String _referralCode = '';
  int _referredCount = 0;
  double _referralEarnings = 0;
  List<dynamic> _referredFriends = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _api.getReferrals();
      if (res['success'] == true) {
        final data = res['data'];
        setState(() {
          _referralCode = data['referralCode'] ?? '';
          _referredCount = data['referredUsersCount'] ?? 0;
          _referralEarnings = (data['referralEarnings'] ?? 0).toDouble();
          _referredFriends = data['referredFriends'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = res['message'] ?? 'Failed to load referral details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
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

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final inviteMessage = lang.isHindi 
        ? "नमस्ते! 🎲 ड्रीम लॉटरी पर मेरे साथ जुड़ें, सबसे बेहतरीन प्रीमियम फंतासी लॉटरी प्लेटफॉर्म! मेरे रेफरल कोड: $_referralCode का उपयोग करके तुरंत ₹20 का साइनअप बोनस प्राप्त करें। अभी डाउनलोड करें और साथ में खेलें!"
        : "Hey! 🎲 Join me on Dream Lottery, the ultimate premium fantasy lottery platform! Use my referral code: $_referralCode to get a ₹20 signup bonus instantly. Download now and let's play together!";

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('refer_earn')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReferralData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: AppTheme.dangerColor),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadReferralData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Premium Banner Header
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFFFEEEE),
                              Colors.white,
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 32),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.15),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.card_giftcard_rounded,
                                size: 56,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              lang.translate('invite_friends_earn'),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                lang.translate('referral_desc'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Referral Code Card
                            Card(
                              elevation: 4,
                              shadowColor: AppTheme.primaryColor.withOpacity(0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Text(
                                      lang.translate('your_referral_code'),
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.bgPrimary,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.borderColor,
                                        ),
                                      ),
                                      child: Text(
                                        _referralCode.isEmpty ? 'N/A' : _referralCode,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.primaryColor,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _referralCode.isEmpty
                                                ? null
                                                : () => _copyToClipboard(
                                                    _referralCode,
                                                    lang.translate('copied')),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 14),
                                              side: const BorderSide(
                                                  color: AppTheme.primaryColor),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            icon: const Icon(Icons.copy_rounded,
                                                color: AppTheme.primaryColor),
                                            label: Text(
                                              lang.translate('copy_code'),
                                              style: const TextStyle(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _referralCode.isEmpty
                                                ? null
                                                : () => _copyToClipboard(
                                                    inviteMessage,
                                                    lang.translate('copied')),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.primaryColor,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            icon: const Icon(Icons.share_rounded),
                                            label: Text(
                                              lang.translate('share_invite'),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Stats Grid
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    lang.translate('referred_friends'),
                                    _referredCount.toString(),
                                    Icons.people_alt_rounded,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatCard(
                                    lang.translate('earnings'),
                                    '₹${_referralEarnings.toStringAsFixed(0)}',
                                    Icons.account_balance_wallet_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Friends List Title
                            Text(
                              lang.translate('referred_friends_list'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Friends List
                            _referredFriends.isEmpty
                                ? Card(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(
                                          color: AppTheme.borderColor),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(28),
                                      child: Center(
                                        child: Column(
                                          children: [
                                            const Icon(
                                              Icons.group_add_rounded,
                                              size: 40,
                                              color: AppTheme.textMuted,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              lang.translate('no_friends_referred'),
                                              style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              lang.translate('share_code_started'),
                                              style: const TextStyle(
                                                color: AppTheme.textMuted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _referredFriends.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final friend = _referredFriends[index];
                                      final name = friend['name'] ?? 'Friend';
                                      final phone = friend['phone'] ?? '';
                                      final dateStr = friend['createdAt'] ?? '';
                                      String joinedDate = 'Joined';
                                      if (dateStr.isNotEmpty) {
                                        try {
                                          final date = DateTime.parse(dateStr);
                                          joinedDate =
                                              "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
                                        } catch (_) {}
                                      }

                                      return Card(
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: const BorderSide(
                                            color: AppTheme.borderColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                AppTheme.primaryColor.withOpacity(0.1),
                                            child: const Icon(
                                              Icons.person_rounded,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          title: Text(
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          subtitle: phone.isNotEmpty
                                              ? Text(
                                                  phone,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                )
                                              : null,
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.bgPrimary,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppTheme.borderColor,
                                              ),
                                            ),
                                            child: Text(
                                              joinedDate,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
