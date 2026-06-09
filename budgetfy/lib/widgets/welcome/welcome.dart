import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cards/card_1.dart';
import 'cards/card_2.dart';
import 'cards/card_3.dart';
import 'cards/card_4.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  int _currentPage = 0;
  late final PageController _pageController;

  List<Widget> get _cards => [Card1(), Card2(), Card3(), Card4(onFinish: _finish)];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _cards.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Column(
        children: [
          // Slide area — tap advances, swipe navigates
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _nextPage,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                children: _cards,
              ),
            ),
          ),
          // Bottom controls
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 12, 32, 40),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_cards.length, _buildDot),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Toca o desliza para continuar',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
