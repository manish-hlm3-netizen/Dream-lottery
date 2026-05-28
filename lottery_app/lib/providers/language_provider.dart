import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LanguageProvider with ChangeNotifier {
  static const _storage = FlutterSecureStorage();
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
      'lost_participants': 'Participants 👥',
      'view_winners_results': 'View Winners & Results',
      'no_winners': 'No winners for this draw',
      'no_lost': 'No other participants',
    },
    'hi': {
      'welcome_back': 'आपका स्वागत है',
      'signin_continue': 'खेलना जारी रखने के लिए साइन इन करें',
      'email': 'ईमेल',
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
      'lost_participants': 'प्रतिभागी 👥',
      'view_winners_results': 'विजेता और परिणाम देखें',
      'no_winners': 'इस ड्रा के लिए कोई विजेता नहीं है',
      'no_lost': 'कोई अन्य प्रतिभागी नहीं',
    }
  };

  String translate(String key) {
    return _localizedValues[_currentLanguage]?[key] ?? key;
  }
}
