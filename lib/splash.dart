import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_code_scanner/homepage.dart';

class Splashscreen extends StatelessWidget {
  const Splashscreen({super.key});

  get splash => null;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AnimatedSplashScreen(
        splash: Column(
          children: [
            Center(
              child: LottieBuilder.asset(
                  "assets/lootie/Animation - 1708971591639.json"),
            )
          ],
        ),
        nextScreen: const App(),
        splashIconSize: 400,
        duration: 1900,
      ),
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
    );
  }
}
