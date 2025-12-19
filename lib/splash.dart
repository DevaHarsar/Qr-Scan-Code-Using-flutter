import 'package:flutter/material.dart';
import 'dart:async';
import 'package:qr_code_scanner/homepage.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> with TickerProviderStateMixin {
  late AnimationController _qrController;
  late AnimationController _devController;
  late AnimationController _scanController;
  late Animation<Offset> _qrOffset;
  late Animation<double> _devOpacity;
  late Animation<double> _scanOpacity;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _qrController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _devController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scanController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _qrOffset = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(CurvedAnimation(parent: _qrController, curve: Curves.easeOut));
    _devOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _devController, curve: Curves.easeIn));
    _scanOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _scanController, curve: Curves.easeIn));

    _startSequence();
  }

  Future<void> _startSequence() async {
    await _qrController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _devController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _scanController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!_navigated && mounted) {
      _navigated = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const App()),
      );
    }
  }

  @override
  void dispose() {
    _qrController.dispose();
    _devController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SlideTransition(
              position: _qrOffset,
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _devOpacity,
              child: Text(
                'DEV',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _scanOpacity,
              child: Text(
                'QR Scan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
