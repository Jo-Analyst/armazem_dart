import 'package:flutter/material.dart';

class ArmazemPage extends StatelessWidget {
  const ArmazemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo_image.png',
                width: 300,
                height: 300,
              ),
              Text(
                'Almoxarifado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 45,
                  fontFamily: 'Anta',
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(247, 192, 118, 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
