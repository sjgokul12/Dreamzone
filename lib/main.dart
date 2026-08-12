import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/admin/admin_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: SystemUiOverlay.values);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  final authProvider = AuthProvider();
  await authProvider.initAuth();
  authProvider.loadServices();

  runApp(DZIApp(authProvider: authProvider));
}

// FIX: class was named DZIInfinityApp — test/widget_test.dart referenced MyApp
// Rename to DZIApp everywhere so widget_test is also fixed below
class DZIApp extends StatelessWidget {
  final AuthProvider authProvider;
  const DZIApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: authProvider,
      // FIX: unnecessary __ in lambda parameter → use _
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'DZI Infinity',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: auth.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('hi'),
              Locale('ta'),
            ],
            locale: const Locale('en'),
            initialRoute: auth.isLoggedIn ? '/home' : '/welcome',
            routes: {
              '/welcome': (_) => const WelcomeScreen(),
              '/home'  : (_) => const HomeScreen(isGuest: false),
              '/admin' : (_) => const AdminLoginScreen(),
            },
          );
        },
      ),
    );
  }
}