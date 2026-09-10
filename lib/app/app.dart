import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/app/theme_controller.dart';
import 'package:dharana_app/features/auth/screens/splash_screen.dart';
import 'package:dharana_app/features/auth/screens/login_screen.dart';
import 'package:dharana_app/features/auth/screens/register_screen.dart';
import 'package:dharana_app/features/auth/screens/reset_password_screen.dart';
import 'package:dharana_app/features/auth/screens/reset_password_form_screen.dart';
import 'package:dharana_app/features/main/main_screen.dart';
import 'package:dharana_app/features/catalog/screens/category_screen.dart';
import 'package:dharana_app/features/catalog/screens/asana_detail_screen.dart';

class DharanaApp extends StatefulWidget {
  const DharanaApp({super.key});

  @override
  State<DharanaApp> createState() => _DharanaAppState();
}

class _DharanaAppState extends State<DharanaApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _links = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    final initial = await _links.getInitialLink();
    if (initial != null) _handleLink(initial);
    _linkSubscription = _links.uriLinkStream.listen(_handleLink);
  }

  bool _formOpen = false;

  void _handleLink(Uri uri) {
    if (!mounted || _formOpen) return;
    final isResetHost =
        uri.host == 'dharana.ru' || uri.host == 'www.dharana.ru';
    if (!isResetHost) return;
    final isResetPath = uri.path.startsWith('/reset-password') ||
        uri.path.startsWith('/ru/reset-password');
    if (!isResetPath) return;
    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) return;

    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    _formOpen = true;
    navigator
        .pushNamed('/reset_password_form', arguments: token)
        .whenComplete(() => _formOpen = false);
  }

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
          navigatorKey: _navigatorKey,
          initialRoute: '/',
          routes: {
            '/': (_) => const SplashScreen(),
            '/login': (_) => const LoginScreen(),
            '/register': (_) => const RegisterScreen(),
            '/reset_password': (_) => const ResetPasswordScreen(),
            '/main': (_) => const MainScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/reset_password_form') {
              final token = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) => ResetPasswordFormScreen(token: token),
              );
            }
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

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }
}
