import 'package:budgetfy/providers/finance_provider.dart';
import 'package:budgetfy/providers/settings_provider.dart';
import 'package:budgetfy/screens/layout.dart';
import 'package:budgetfy/screens/splash.dart';
import 'package:budgetfy/widgets/welcome/welcome.dart';
import 'package:budgetfy/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsProvider();
  await settings.load();
  runApp(MyApp(settings: settings));
}

class MyApp extends StatelessWidget {
  final SettingsProvider settings;
  const MyApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, s, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Budgetfy',
          theme: s.isDark ? AppTheme.dark : AppTheme.light,
          initialRoute: '/',
          routes: {
            '/': (context) => const Splash(),
            '/welcome': (context) => const Welcome(),
            '/dashboard': (context) => const Layout(),
          },
        ),
      ),
    );
  }
}
