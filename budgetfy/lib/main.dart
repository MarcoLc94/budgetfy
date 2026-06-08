import 'package:budgetfy/providers/finance_provider.dart';
import 'package:budgetfy/screens/layout.dart';
import 'package:budgetfy/screens/splash.dart';
import 'package:budgetfy/widgets/welcome/welcome.dart';
import 'package:budgetfy/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinanceProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Budgetfy',
        theme: AppTheme.dark,
        initialRoute: '/',
        routes: {
          '/': (context) => const Splash(),
          '/welcome': (context) => const Welcome(),
          '/dashboard': (context) => const Layout(),
        },
      ),
    );
  }
}
