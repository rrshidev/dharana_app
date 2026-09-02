import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/app/theme_controller.dart';
import 'package:dharana_app/features/auth/screens/splash_screen.dart';
import 'package:dharana_app/features/auth/screens/login_screen.dart';
import 'package:dharana_app/features/auth/screens/register_screen.dart';
import 'package:dharana_app/features/main/main_screen.dart';
import 'package:dharana_app/features/catalog/screens/category_screen.dart';
import 'package:dharana_app/features/catalog/screens/asana_detail_screen.dart';

class DharanaApp extends StatefulWidget {
  const DharanaApp({super.key});

  @override
  State<DharanaApp> createState() => _DharanaAppState();
}

class _DharanaAppState extends State<DharanaApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) {
        final isDark = AppTheme.isDark;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: AppTheme.Surface,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
        );
        return MaterialApp(
          title: 'Dharana',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
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
      },
    );
  }
}
