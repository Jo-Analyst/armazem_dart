import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final colorizeColors = [
    Color.fromRGBO(247, 192, 118, 1),
    Colors.deepPurple,
    const Color.fromARGB(255, 20, 87, 143),
    Colors.green,
    Colors.red,
  ];

  @override
  void initState() {
    super.initState();

    _navigateToHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFDEB887),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo_image.png',
                width: 300,
                height: 300,
              ),
              AnimatedTextKit(
                pause: Duration.zero,
                // isRepeatingAnimation: true,
                repeatForever: true,
                animatedTexts: [
                  ColorizeAnimatedText(
                    'Almoxarifado',
                    textAlign: TextAlign.center,
                    textStyle: const TextStyle(
                      fontSize: 45,
                      fontFamily: 'Anta',
                      fontWeight: FontWeight.bold,
                    ),
                    colors: colorizeColors,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToHome() async {
    Timer(const Duration(seconds: 4), () async {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    });
  }
}
