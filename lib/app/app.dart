import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/features/auth/screens/splash_screen.dart';
import 'package:dharana_app/features/auth/screens/login_screen.dart';
import 'package:dharana_app/features/auth/screens/register_screen.dart';
import 'package:dharana_app/features/main/main_screen.dart';
import 'package:dharana_app/features/catalog/screens/category_screen.dart';
import 'package:dharana_app/features/catalog/screens/asana_detail_screen.dart';

class DharanaApp extends StatelessWidget {
  const DharanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.surface,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'Dharana',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/main': (_) => const MainScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/category') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => CategoryScreen(
              categoryId: args['categoryId'],
              displayName: args['displayName'],
            ),
          );
        }
        if (settings.name == '/asana_detail') {
          final asanaName = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => AsanaDetailScreen(asanaName: asanaName),
          );
        }
        return null;
      },
    );
  }
}
