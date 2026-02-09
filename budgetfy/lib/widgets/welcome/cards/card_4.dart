import 'package:flutter/material.dart';

class Card4 extends StatelessWidget {
  const Card4({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/App-monetization.gif', height: 320),
          const SizedBox(height: 32),
          const Text(
            'Budgetfy nace para ayudarte, Controla tus gastos, entiende tus ingresos y toma mejores decisiones.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
          ),
          SizedBox(height: 50),
          ElevatedButton(
            onPressed: () {
              // Aquí navegas a Home
              Navigator.pushReplacementNamed(context, '/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF92E3A9),
              // amarillo contraste
              foregroundColor: Color(0xFF673BB7), // texto morado
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: const Text(
              'Continuar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
