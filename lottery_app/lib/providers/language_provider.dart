import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LanguageProvider with ChangeNotifier {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );
  static const _langKey = 'app_language';

  String _currentLanguage = 'en'; // default English

  LanguageProvider() {
    _loadLanguage();
  }

  String get currentLanguage => _currentLanguage;

  bool get isHindi => _currentLanguage == 'hi';

  Future<void> _loadLanguage() async {
    final lang = await _storage.read(key: _langKey);
    if (lang != null) {
      _currentLanguage = lang;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String langCode) async {
    _currentLanguage = langCode;
    await _storage.write(key: _langKey, value: langCode);
    notifyListeners();
  }

  void toggleLanguage() {
    if (_currentLanguage == 'en') {
      setLanguage('hi');
    } else {
      setLanguage('en');
    }
  }

  // Bilingual dynamic dictionary
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'welcome_back': 'Welcome Back',
      'signin_continue': 'Sign in to continue playing',
      'email': 'Email',
      'email_or_phone': 'Email or Phone Number',
      'password': 'Password',
      'signin': 'Sign In',
      'dont_have_account': "Don't have an account? ",
      'signup': 'Sign Up',
      'create_account': 'Create Account',
      'join_start_playing': 'Join and start playing lottery',
      'full_name': 'Full Name',
      'phone_number': 'Phone Number',
      'phone_hint': '10-digit mobile number',
      'already_have_account': 'Already have an account? ',
      'my_tickets': 'My Tickets',
      'results': 'Results',
      'txn_history': 'Transaction History',
      'announcements': 'Announcements',
      'refer_earn': 'Refer & Earn',
      'logout': 'Logout',
      'wallet_balance': 'Wallet Balance',
      'change_language': 'Change Language',
      'english': 'English',
      'hindi': 'Hindi',
      'luck_starts': 'Your luck starts here',
      'referral_code_opt': 'Referral Code (Optional)',
      'winning_numbers': 'Winning Numbers',
      'winners': 'Winners 🏆',
      'winners_and_participants': 'Winners & Participants 🏆👥',
      'chat_support': 'Chat with Customer Care',
      'type_message': 'Type a message...',
      'connecting_support': 'Connecting to support...',
      'no_participants': 'No participants yet for this draw',
      'view_winners_results': 'View Winners & Results',
      'no_winners': 'No winners for this draw',
      'no_lost': 'No other participants',
      'lottery_name_label': 'Lottery',
      'draw_date_label': 'Draw Date',
      'status_label': 'Status',
      'status_winner': 'Winner 🏆',
      'status_participant': 'Participant 👥',
      'winnings_label': 'Winnings',
      'selected_numbers_label': 'Picked Numbers',
      // Home & General Lotteries EN
      'wallet': 'Wallet',
      'available_balance': 'Available Balance',
      'deposit': 'Deposit',
      'withdraw': 'Withdraw',
      'no_transactions': 'No transactions yet',
      'transaction_history': 'Transaction History',
      'active_lotteries': 'Active Lotteries 🎰',
      'see_all': 'See All →',
      'play_now': 'Play Now →',
      'ready_try_luck': 'Ready to try your luck today?',
      'no_active_lotteries': 'No active lotteries right now',
      'tickets_sold': 'tickets sold',
      'quick_actions': 'Quick Actions',
      'play_lottery_action': 'Play\nLottery',
      'view_results_action': 'View\nResults',
      'my_tickets_action': 'My\nTickets',
      'draw_closed': 'Draw closed',
      'tickets_left': 'Tickets Left',
      'filled': 'Filled',
      'winners_pricing': 'Winners Pricing (Prize Pool Distribution)',
      'jackpot_pool': 'Jackpot Pool',
      'live_timer': 'Live Timer',
      // Referrals EN
      'copied': 'Copied!',
      'invite_friends_earn': 'Invite Friends & Earn ₹50!',
      'referral_desc': 'Get ₹50 free wallet balance for every friend who registers. Plus, they get ₹20 instantly to play!',
      'your_referral_code': 'YOUR REFERRAL CODE',
      'copy_code': 'Copy Code',
      'share_invite': 'Share Invite',
      'referred_friends_list': 'Referred Friends List',
      'no_friends_referred': 'No friends referred yet',
      'share_code_started': 'Share your code above to get started!',
      'referred_friends': 'Referred Friends',
      'earnings': 'Earnings',
    },
    'hi': {
      'welcome_back': 'आपका स्वागत है',
      'signin_continue': 'खेलना जारी रखने के लिए साइन इन करें',
      'email': 'ईमेल',
      'email_or_phone': 'ईमेल या फ़ोन नंबर',
      'password': 'पासवर्ड',
      'signin': 'साइन इन करें',
      'dont_have_account': 'खाता नहीं है? ',
      'signup': 'साइन अप करें',
      'create_account': 'खाता बनाएं',
      'join_start_playing': 'जुड़ें और लॉटरी खेलना शुरू करें',
      'full_name': 'पूरा नाम',
      'phone_number': 'फ़ोन नंबर',
      'phone_hint': '10-अंकीय मोबाइल नंबर',
      'already_have_account': 'क्या आपके पास पहले से एक खाता है? ',
      'my_tickets': 'मेरे टिकट',
      'results': 'परिणाम',
      'txn_history': 'लेन-देन इतिहास',
      'announcements': 'घोषणाएँ',
      'refer_earn': 'रेफर करें और कमाएं',
      'logout': 'लॉगआउट',
      'wallet_balance': 'वॉलेट बैलेंस',
      'change_language': 'भाषा बदलें',
      'english': 'English',
      'hindi': 'हिंदी',
      'luck_starts': 'आपकी किस्मत यहाँ से शुरू होती है',
      'referral_code_opt': 'रेफरल कोड (वैकल्पिक)',
      'winning_numbers': 'विजेता नंबर',
      'winners': 'विजेता 🏆',
      'winners_and_participants': 'विजेता और प्रतिभागी 🏆👥',
      'chat_support': 'कस्टमर केयर से चैट करें',
      'type_message': 'एक संदेश लिखें...',
      'connecting_support': 'सहायता से जुड़ रहे हैं...',
      'no_participants': 'इस ड्रा के लिए अभी तक कोई प्रतिभागी नहीं है',
      'view_winners_results': 'विजेता और परिणाम देखें',
      'no_winners': 'इस ड्रा के लिए कोई विजेता नहीं है',
      'no_lost': 'कोई अन्य प्रतिभागी नहीं',
      'lottery_name_label': 'लॉटरी का नाम',
      'draw_date_label': 'ड्रा की तारीख',
      'status_label': 'स्थिति',
      'status_winner': 'विजेता 🏆',
      'status_participant': 'प्रतिभागी 👥',
      'winnings_label': 'जीत की राशि',
      'selected_numbers_label': 'चुने गए नंबर',
      // Home & General Lotteries HI
      'wallet': 'वॉलेट',
      'available_balance': 'उपलब्ध बैलेंस',
      'deposit': 'जमा करें',
      'withdraw': 'निकासी करें',
      'no_transactions': 'अभी तक कोई लेन-देन नहीं',
      'transaction_history': 'लेन-देन इतिहास',
      'active_lotteries': 'सक्रिय लॉटरी 🎰',
      'see_all': 'सभी देखें →',
      'play_now': 'अभी खेलें →',
      'ready_try_luck': 'क्या आप आज अपनी किस्मत आजमाने के लिए तैयार हैं?',
      'no_active_lotteries': 'अभी कोई सक्रिय लॉटरी नहीं है',
      'tickets_sold': 'टिकट बिके',
      'quick_actions': 'त्वरित विकल्प',
      'play_lottery_action': 'लॉटरी\nखेलें',
      'view_results_action': 'परिणाम\nदेखें',
      'my_tickets_action': 'मेरे\nटिकट',
      'draw_closed': 'ड्रा बंद',
      'tickets_left': 'टिकट बचे',
      'filled': 'भरा हुआ',
      'winners_pricing': 'विजेता मूल्य (पुरस्कार पूल वितरण)',
      'jackpot_pool': 'जैकपॉट पूल',
      'live_timer': 'लाइव टाइमर',
      // Referrals HI
      'copied': 'कॉपी किया गया!',
      'invite_friends_earn': 'दोस्तों को आमंत्रित करें और ₹50 कमाएं!',
      'referral_desc': 'पंजीकरण करने वाले प्रत्येक मित्र के लिए ₹50 का मुफ्त वॉलेट बैलेंस प्राप्त करें। साथ ही, उन्हें खेलने के लिए तुरंत ₹20 मिलेंगे!',
      'your_referral_code': 'आपका रेफरल कोड',
      'copy_code': 'कोड कॉपी करें',
      'share_invite': 'आमंत्रण साझा करें',
      'referred_friends_list': 'आमंत्रित मित्रों की सूची',
      'no_friends_referred': 'अभी तक कोई मित्र आमंत्रित नहीं किया गया है',
      'share_code_started': 'शुरू करने के लिए ऊपर अपना कोड साझा करें!',
      'referred_friends': 'आमंत्रित मित्र',
      'earnings': 'कमाई',
    }
  };

  String translate(String key) {
    return _localizedValues[_currentLanguage]?[key] ?? key;
  }
}
