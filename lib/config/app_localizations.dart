import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // ==================== ALL STRINGS ====================

  String get appName => _get('appName');
  String get guestMode => _get('guestMode');
  String get welcome => _get('welcome');
  String get login => _get('login');
  String get register => _get('register');
  String get logout => _get('logout');
  String get home => _get('home');
  String get requests => _get('requests');
  String get alerts => _get('alerts');
  String get profile => _get('profile');
  String get ourServices => _get('ourServices');
  String get whyChooseUs => _get('whyChooseUs');
  String get whatCustomersSay => _get('whatCustomersSay');
  String get needHelp => _get('needHelp');
  String get viewAll => _get('viewAll');
  String get settings => _get('settings');
  String get darkMode => _get('darkMode');
  String get language => _get('language');
  String get deleteAccount => _get('deleteAccount');
  String get about => _get('about');
  String get helpSupport => _get('helpSupport');
  String get myApplications => _get('myApplications');
  String get editProfile => _get('editProfile');
  String get submitApplication => _get('submitApplication');
  String get requiredDocuments => _get('requiredDocuments');
  String get applyNow => _get('applyNow');
  String get loginRequired => _get('loginRequired');
  String get fastProcessing => _get('fastProcessing');
  String get secure => _get('secure');
  String get support => _get('support');
  String get trusted => _get('trusted');
  String get customers => _get('customers');
  String get centers => _get('centers');
  String get callUs => _get('callUs');
  String get chat => _get('chat');
  String get email => _get('email');
  String get noServices => _get('noServices');
  String get loading => _get('loading');
  String get backToHome => _get('backToHome');
  String get version => _get('version');
  String get popular => _get('popular');
  String get helpSupportDesc => _get('helpSupportDesc');
  String get aboutService => _get('aboutService');
  String get fee => _get('fee');
  String get time => _get('time');
  String get expert => _get('expert');
  String get total => _get('total');
  String get done => _get('done');
  String get active => _get('active');
  String get pending => _get('pending');
  String get processing => _get('processing');
  String get completed => _get('completed');
  String get rejected => _get('rejected');
  String get noApplications => _get('noApplications');
  String get trackingId => _get('trackingId');
  String get status => _get('status');
  String get save => _get('save');
  String get cancel => _get('cancel');
  String get search => _get('search');
  String get clearFilters => _get('clearFilters');
  String get allServices => _get('allServices');
  String get notifications => _get('notifications');
  String get noNotifications => _get('noNotifications');
  String get termsAndConditions => _get('termsAndConditions');
  String get privacyPolicy => _get('privacyPolicy');
  String get iAgree => _get('iAgree');

  final Map<String, Map<String, String>> _strings = {
    'en': {
      'appName': 'DZI Infinity',
      'guestMode': 'Guest Mode',
      'welcome': 'Welcome',
      'login': 'Login',
      'register': 'Register',
      'logout': 'Logout',
      'home': 'Home',
      'requests': 'Requests',
      'alerts': 'Alerts',
      'profile': 'Profile',
      'ourServices': 'Our Services',
      'whyChooseUs': 'Why Choose Us',
      'whatCustomersSay': 'What Customers Say',
      'needHelp': 'Need Help?',
      'viewAll': 'View All →',
      'settings': 'Settings',
      'darkMode': 'Dark Mode',
      'language': 'Language',
      'deleteAccount': 'Delete Account',
      'about': 'About DZI Infinity',
      'helpSupport': 'Help & Support',
      'myApplications': 'My Applications',
      'editProfile': 'Edit Profile',
      'submitApplication': 'Submit Application',
      'requiredDocuments': 'Required Documents',
      'applyNow': 'Apply Now',
      'loginRequired': 'Login required to submit',
      'fastProcessing': 'Fast Processing',
      'secure': '100% Secure',
      'support': '24/7 Support',
      'trusted': 'Trusted Partner',
      'customers': 'Customers',
      'centers': 'Centers',
      'callUs': 'Call',
      'chat': 'Chat',
      'email': 'Email',
      'noServices': 'No services available',
      'loading': 'Loading...',
      'backToHome': 'Back to Home',
      'version': 'Version 1.0.0',
      'popular': 'POPULAR',
      'helpSupportDesc': 'Our support team is available 24/7',
      'aboutService': 'About this Service',
      'fee': 'Fee',
      'time': 'Time',
      'expert': 'Expert',
      'total': 'Total',
      'done': 'Done',
      'active': 'Active',
      'pending': 'Pending',
      'processing': 'Processing',
      'completed': 'Completed',
      'rejected': 'Rejected',
      'noApplications': 'No applications yet',
      'trackingId': 'Tracking ID',
      'status': 'Status',
      'save': 'Save',
      'cancel': 'Cancel',
      'search': 'Search services...',
      'clearFilters': 'Clear filters',
      'allServices': 'All Services',
      'notifications': 'Notifications',
      'noNotifications': 'No notifications yet',
      'termsAndConditions': 'Terms & Conditions',
      'privacyPolicy': 'Privacy Policy',
      'iAgree': 'I agree to the',
    },
    'hi': {
      'appName': 'डीजेडआई इन्फिनिटी',
      'guestMode': 'अतिथि मोड',
      'welcome': 'स्वागत है',
      'login': 'लॉग इन',
      'register': 'रजिस्टर',
      'logout': 'लॉग आउट',
      'home': 'होम',
      'requests': 'अनुरोध',
      'alerts': 'अलर्ट',
      'profile': 'प्रोफाइल',
      'ourServices': 'हमारी सेवाएं',
      'whyChooseUs': 'हमें क्यों चुनें',
      'whatCustomersSay': 'ग्राहक क्या कहते हैं',
      'needHelp': 'मदद चाहिए?',
      'viewAll': 'सभी देखें →',
      'settings': 'सेटिंग्स',
      'darkMode': 'डार्क मोड',
      'language': 'भाषा',
      'deleteAccount': 'अकाउंट हटाएं',
      'about': 'डीजेडआई इन्फिनिटी के बारे में',
      'helpSupport': 'सहायता और समर्थन',
      'myApplications': 'मेरे आवेदन',
      'editProfile': 'प्रोफाइल संपादित करें',
      'submitApplication': 'आवेदन जमा करें',
      'requiredDocuments': 'आवश्यक दस्तावेज',
      'applyNow': 'अभी आवेदन करें',
      'loginRequired': 'जमा करने के लिए लॉगिन आवश्यक है',
      'fastProcessing': 'तेज़ प्रोसेसिंग',
      'secure': '100% सुरक्षित',
      'support': '24/7 सहायता',
      'trusted': 'विश्वसनीय भागीदार',
      'customers': 'ग्राहक',
      'centers': 'केंद्र',
      'callUs': 'कॉल',
      'chat': 'चैट',
      'email': 'ईमेल',
      'noServices': 'कोई सेवा उपलब्ध नहीं',
      'loading': 'लोड हो रहा है...',
      'backToHome': 'होम पर वापस जाएं',
      'version': 'वर्शन 1.0.0',
      'popular': 'लोकप्रिय',
      'helpSupportDesc': 'हमारी सहायता टीम 24/7 उपलब्ध है',
      'aboutService': 'इस सेवा के बारे में',
      'fee': 'शुल्क',
      'time': 'समय',
      'expert': 'विशेषज्ञ',
      'total': 'कुल',
      'done': 'पूर्ण',
      'active': 'सक्रिय',
      'pending': 'लंबित',
      'processing': 'प्रक्रिया में',
      'completed': 'पूरा हुआ',
      'rejected': 'अस्वीकृत',
      'noApplications': 'अभी तक कोई आवेदन नहीं',
      'trackingId': 'ट्रैकिंग आईडी',
      'status': 'स्थिति',
      'save': 'सेव करें',
      'cancel': 'रद्द करें',
      'search': 'सेवाएं खोजें...',
      'clearFilters': 'फ़िल्टर हटाएं',
      'allServices': 'सभी सेवाएं',
      'notifications': 'सूचनाएं',
      'noNotifications': 'अभी तक कोई सूचना नहीं',
      'termsAndConditions': 'नियम और शर्तें',
      'privacyPolicy': 'गोपनीयता नीति',
      'iAgree': 'मैं सहमत हूं',
    },
    'ta': {
      'appName': 'டிஇசட்ஐ இன்பினிட்டி',
      'guestMode': 'விருந்தினர் முறை',
      'welcome': 'வரவேற்கிறோம்',
      'login': 'உள்நுழைய',
      'register': 'பதிவு செய்ய',
      'logout': 'வெளியேறு',
      'home': 'முகப்பு',
      'requests': 'கோரிக்கைகள்',
      'alerts': 'எச்சரிக்கைகள்',
      'profile': 'சுயவிவரம்',
      'ourServices': 'எங்கள் சேவைகள்',
      'whyChooseUs': 'ஏன் எங்களை தேர்வு செய்ய வேண்டும்',
      'whatCustomersSay': 'வாடிக்கையாளர்கள் கூறுவது',
      'needHelp': 'உதவி தேவையா?',
      'viewAll': 'அனைத்தையும் காண்க →',
      'settings': 'அமைப்புகள்',
      'darkMode': 'இருண்ட பயன்முறை',
      'language': 'மொழி',
      'deleteAccount': 'கணக்கை நீக்கு',
      'about': 'டிஇசட்ஐ இன்பினிட்டி பற்றி',
      'helpSupport': 'உதவி மற்றும் ஆதரவு',
      'myApplications': 'எனது விண்ணப்பங்கள்',
      'editProfile': 'சுயவிவரத்தைத் திருத்து',
      'submitApplication': 'விண்ணப்பத்தை சமர்ப்பிக்கவும்',
      'requiredDocuments': 'தேவையான ஆவணங்கள்',
      'applyNow': 'இப்போது விண்ணப்பிக்கவும்',
      'loginRequired': 'சமர்ப்பிக்க உள்நுழைவு தேவை',
      'fastProcessing': 'விரைவான செயலாக்கம்',
      'secure': '100% பாதுகாப்பானது',
      'support': '24/7 ஆதரவு',
      'trusted': 'நம்பகமான பங்குதாரர்',
      'customers': 'வாடிக்கையாளர்கள்',
      'centers': 'மையங்கள்',
      'callUs': 'அழைக்க',
      'chat': 'அரட்டை',
      'email': 'மின்னஞ்சல்',
      'noServices': 'சேவைகள் எதுவும் இல்லை',
      'loading': 'ஏற்றுகிறது...',
      'backToHome': 'முகப்புக்குத் திரும்பு',
      'version': 'பதிப்பு 1.0.0',
      'popular': 'பிரபலமானது',
      'helpSupportDesc': 'எங்கள் ஆதரவு குழு 24/7 கிடைக்கும்',
      'aboutService': 'இந்த சேவை பற்றி',
      'fee': 'கட்டணம்',
      'time': 'நேரம்',
      'expert': 'நிபுணர்',
      'total': 'மொத்தம்',
      'done': 'முடிந்தது',
      'active': 'செயலில்',
      'pending': 'நிலுவையில்',
      'processing': 'செயலாக்கத்தில்',
      'completed': 'முடிக்கப்பட்டது',
      'rejected': 'நிராகரிக்கப்பட்டது',
      'noApplications': 'இதுவரை விண்ணப்பங்கள் இல்லை',
      'trackingId': 'கண்காணிப்பு எண்',
      'status': 'நிலை',
      'save': 'சேமி',
      'cancel': 'ரத்து செய்',
      'search': 'சேவைகளைத் தேடு...',
      'clearFilters': 'வடிப்பான்களை அழி',
      'allServices': 'அனைத்து சேவைகள்',
      'notifications': 'அறிவிப்புகள்',
      'noNotifications': 'இதுவரை அறிவிப்புகள் இல்லை',
      'termsAndConditions': 'விதிமுறைகள் & நிபந்தனைகள்',
      'privacyPolicy': 'தனியுரிமைக் கொள்கை',
      'iAgree': 'நான் ஒப்புக்கொள்கிறேன்',
    },
  };

  String _get(String key) {
    return _strings[locale.languageCode]?[key] ?? _strings['en']![key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'hi', 'ta'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
