import 'package:flutter/material.dart';

class ArmazemPage extends StatelessWidget {
  const ArmazemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(80.0),
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // mainAxisAlignment: MainAxisAlignment.center,
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
                    fontSize: MediaQuery.of(context).size.width >= 800
                        ? 45
                        : 35,
                    fontFamily: 'Anta',
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(247, 192, 118, 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
