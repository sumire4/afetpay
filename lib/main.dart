import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/wallet/presentation/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const AfetPayApp());
}

class AfetPayApp extends StatelessWidget {
  const AfetPayApp({super.key});

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
      home: const HomeScreen(),
    );
  }
}