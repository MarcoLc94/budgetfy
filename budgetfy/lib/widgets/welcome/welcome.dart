import 'package:budgetfy/widgets/welcome/cards/card_1.dart';
import 'package:budgetfy/widgets/welcome/cards/card_2.dart';
import 'package:budgetfy/widgets/welcome/cards/card_3.dart';
import 'package:budgetfy/widgets/welcome/cards/card_4.dart';
import 'package:flutter/material.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  int _currentPage = 0;

  final List<Widget> _cards = const [Card1(), Card2(), Card3(), Card4()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: PageController(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: _cards,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _cards.length,
                (index) => _buildDot(index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final bool isActive = index == _currentPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: isActive ? 12 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white38,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
