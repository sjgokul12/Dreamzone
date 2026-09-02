import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _loading              = false;
  bool _loggedIn             = false;
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _services = [];

  bool _darkMode              = false;
  String _language            = 'English';
  bool _notificationsEnabled  = true;
  bool _emailAlertsEnabled    = true;

  bool get loading              => _loading;
  bool get isLoggedIn           => _loggedIn;
  String? get userName          => _user?['name'];
  String? get userEmail         => _user?['email'];
  String? get userMobile        => _user?['mobile'];
  int? get userId               => _user != null ? (_user!['id'] as int?) : null;
  Map<String, dynamic>? get user => _user;
  List<Map<String, dynamic>> get services => _services;

  bool get isDarkMode            => _darkMode;
  String get appLanguage         => _language;
  bool get notificationsEnabled  => _notificationsEnabled;
  bool get emailAlertsEnabled    => _emailAlertsEnabled;

  // ── Auth ────────────────────────────────────────────────────────────────────

  Future<void> initAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      try {
        _user = json.decode(userStr);
        _loggedIn = true;
        notifyListeners();
        // Load settings asynchronously in background without delaying app launch
        loadSettings();
      } catch (e) {
        debugPrint('Error parsing stored user: $e');
      }
    }
  }

  Future<Map<String, dynamic>> register(
      String name, String mobile, String email, String password) async {
    _loading = true; notifyListeners();
    final result = await _api.register(name, mobile, email, password);
    _loading = false; notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> verifyRegisterOtp(
      String email, String otp) async {
    _loading = true; notifyListeners();
    final result = await _api.verifyRegisterOtp(email, otp);
    if (result['success'] == true) {
      _user    = result['user'] as Map<String, dynamic>?;
      _loggedIn = true;
      if (_user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_user));
        if (result['token'] != null) {
          await prefs.setString('auth_token', result['token'] as String);
        }
      }
      await loadSettings();
    }
    _loading = false; notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> resendOtp(String email, {String purpose = 'registration'}) async {
    _loading = true; notifyListeners();
    final result = await _api.resendOtp(email, purpose: purpose);
    _loading = false; notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> login(String loginId, String password) async {
    _loading = true; notifyListeners();
    final result = await _api.login(loginId, password);
    if (result['success'] == true) {
      _user    = result['user'] as Map<String, dynamic>?;
      _loggedIn = true;
      if (_user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_user));
        if (result['token'] != null) {
          await prefs.setString('auth_token', result['token'] as String);
        }
      }
      await loadSettings();
    }
    _loading = false; notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    _loading = true; notifyListeners();
    final result = await _api.forgotPassword(email);
    _loading = false; notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> resetPassword(
      String email, String otp, String newPassword) async {
    _loading = true; notifyListeners();
    final result = await _api.resetPassword(email, otp, newPassword);
    _loading = false; notifyListeners();
    return result;
  }

  // ── Services ────────────────────────────────────────────────────────────────

  Future<void> loadServices() async {
    final result = await _api.getServices();
    if (result['success'] == true) {
      _services = List<Map<String, dynamic>>.from(
          result['services'] as List);
      notifyListeners();
    }
  }

  // ── Profile ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> updateProfile(
      String name, String mobile, String email) async {
    _loading = true; notifyListeners();
    final result =
        await _api.updateProfile(_user!['id'] as int, name, mobile, email);
    if (result['success'] == true) {
      _user = result['user'] as Map<String, dynamic>?;
    }
    _loading = false; notifyListeners();
    return result;
  }

  // ── Settings ─────────────────────────────────────────────────────────────────

  Future<void> loadSettings() async {
    if (_user == null) return;
    try {
      final result = await _api.getUserSettings(_user!['id'] as int);
      if (result['success'] == true && result['settings'] != null) {
        final s = result['settings'] as Map<String, dynamic>;
        _darkMode              = s['dark_mode'] == 1;
        _language              = (s['language'] ?? 'English').toString();
        _notificationsEnabled  = s['notifications_enabled'] == 1;
        _emailAlertsEnabled    = s['email_alerts'] == 1;
        // FIX: print → debugPrint
        debugPrint('Settings loaded: DarkMode=$_darkMode, Lang=$_language');
        notifyListeners();
      }
    } catch (e) {
      // FIX: print → debugPrint
      debugPrint('Error loading settings: $e');
    }
  }

  void setDarkMode(bool value) {
    _darkMode = value;
    // FIX: print → debugPrint
    debugPrint('Dark mode set to: $_darkMode');
    notifyListeners();
    if (_user != null) {
      _api.updateUserSettings(_user!['id'] as int, {'dark_mode': value});
    }
  }

  void setLanguage(String value) {
    _language = value;
    // FIX: print → debugPrint
    debugPrint('Language set to: $_language');
    notifyListeners();
    if (_user != null) {
      _api.updateUserSettings(_user!['id'] as int, {'language': value});
    }
  }

  void setNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
    if (_user != null) {
      _api.updateUserSettings(
          _user!['id'] as int, {'notifications_enabled': value});
    }
  }

  void setEmailAlerts(bool value) {
    _emailAlertsEnabled = value;
    notifyListeners();
    if (_user != null) {
      _api.updateUserSettings(
          _user!['id'] as int, {'email_alerts': value});
    }
  }

  Future<Map<String, dynamic>> deleteAccount(String password) async {
    final result =
        await _api.deleteAccount(_user!['id'] as int, password);
    if (result['success'] == true) {
      _user     = null;
      _loggedIn = false;
      _darkMode = false;
      _language = 'English';
      notifyListeners();
    }
    return result;
  }

  Future<void> logout() async {
    _user     = null;
    _loggedIn = false;
    _darkMode = false;
    _language = 'English';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('auth_token');
    notifyListeners();
  }
}