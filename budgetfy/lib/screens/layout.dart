import 'package:budgetfy/screens/home.dart';
import 'package:flutter/material.dart';

class Layout extends StatefulWidget {
  const Layout({super.key});

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  int _index = 0;

  final _pages = const [Home()];
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
