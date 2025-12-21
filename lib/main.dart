
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/splash.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/services.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. FORCE EDGE-TO-EDGE
  // This tells Flutter to draw behind the system bars
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // 2. SET OVERLAY STYLE (You were MISSING this!)
  // This forces the Status Bar & Nav Bar to be transparent so content shows through.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, 
    systemNavigationBarColor: Colors.transparent,
    
    // Adjusts icon colors (dark icons for light backgrounds)
    statusBarIconBrightness: Brightness.dark, 
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  await MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Code Scanner',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[200],
          elevation: 2,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        scaffoldBackgroundColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black,
            elevation: 2,
            shadowColor: Colors.white70,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1a1a1a),
          elevation: 2,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        scaffoldBackgroundColor: Color(0xFF121212),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: Colors.black54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const Splashscreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
