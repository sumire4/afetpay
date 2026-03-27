import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/wallet/presentation/home_screen.dart';
import 'features/auth/presentation/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(AfetPayApp(isLoggedIn: isLoggedIn));
}

class AfetPayApp extends StatelessWidget {
  final bool isLoggedIn;
  
  const AfetPayApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AfetPay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1B5E97),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF6F9FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}