import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/kontraktor_nav.dart';
import 'widgets/penyelia_nav.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().mode;
    return MaterialApp(
      title: 'iPANTAU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        Widget page;
        if (settings.name == '/kontraktor/dashboard') {
          final raw = settings.arguments;
          final idx = raw is int ? raw.clamp(0, 3) : 0;
          page = KontraktorNav(initialIndex: idx);
        } else if (settings.name == '/penyelia/dashboard') {
          final raw = settings.arguments;
          final idx = raw is int ? raw.clamp(0, 3) : 0;
          page = PenyeliaNav(initialIndex: idx);
        } else {
          page = const LoginScreen();
        }
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, _) => page,
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }
}
