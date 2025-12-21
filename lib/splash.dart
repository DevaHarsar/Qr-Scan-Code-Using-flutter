import 'package:flutter/material.dart';
import 'package:qr_code_scanner/homepage.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> with SingleTickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<Offset> _qrOffset;
  late Animation<double> _devOpacity;
  late Animation<double> _scanOpacity;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // 1. One controller for all animations (Staggered Animation pattern)
    _mainController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1600) // Total animation time
    );

    // 2. Define Intervals for overlapping animations
    _qrOffset = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack))
    );
    
    _devOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.4, 0.7, curve: Curves.easeIn))
    );

    _scanOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.6, 1.0, curve: Curves.easeIn))
    );

    _startSequence();
  }

  @override
  void didChangeDependencies() {
    // 3. Pre-load the image to prevent white flicker on first frame
    precacheImage(const AssetImage('assets/images/app_logo.png'), context);
    super.didChangeDependencies();
  }

  Future<void> _startSequence() async {
    await _mainController.forward();
    
    if (!_navigated && mounted) {
      _navigated = true;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const App(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Check if the system is in Dark Mode
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 2. Change Background Color based on Theme
      // Uses pure white for Light Mode, and your app's dark color for Dark Mode
      backgroundColor: isDark ? const Color(0xFF181A20) : Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SlideTransition(
                  position: _qrOffset,
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 140,
                    height: 140,
                  ),
                ),
                const SizedBox(height: 20),
                Opacity(
                  opacity: _devOpacity.value,
                  child: const Text(
                    'DEV',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      // Blue looks good on both white and black, so we keep it
                      color: Colors.blue, 
                      letterSpacing: 3,
                    ),
                  ),
                ),
                Opacity(
                  opacity: _scanOpacity.value,
                  child: Text(
                    'QR Code Scanner & Generator',
                    style: TextStyle(
                      fontSize: 22,
                      // 3. Change Text Color for visibility
                      // Grey (black54) is invisible on dark background, so switch to white70
                      color: isDark ? Colors.white70 : Colors.black54,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}