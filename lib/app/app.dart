import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
import 'package:dharana_app/features/filters/screens/filter_screen.dart';
import 'package:dharana_app/features/sequences/screens/sequences_screen.dart';
import 'package:dharana_app/features/search/screens/search_screen.dart';
import 'package:dharana_app/features/timer/screens/timer_screen.dart';
import 'package:dharana_app/features/timer/screens/timer_setup_screen.dart';
import 'package:dharana_app/features/admin/screens/admin_dashboard_screen.dart';
import 'package:dharana_app/features/admin/screens/admin_user_detail_screen.dart';
import 'package:dharana_app/features/profile/screens/practice_history_screen.dart';
import 'package:dharana_app/features/subscription/screens/subscription_screen.dart';
import 'package:dharana_app/features/notifications/screens/notifications_screen.dart';

class DharanaApp extends StatefulWidget {
  const DharanaApp({super.key});

  @override
  State<DharanaApp> createState() => _DharanaAppState();
}

class _DharanaAppState extends State<DharanaApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final GoRouter _router = GoRouter(
    navigatorKey: _navigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/reset_password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/reset_password_form',
        builder: (context, state) =>
            ResetPasswordFormScreen(token: state.extra as String),
      ),
      GoRoute(path: '/main', builder: (context, state) => const MainScreen()),
      GoRoute(
        path: '/category',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return CategoryScreen(
            categoryId: args['categoryId'],
            displayName: args['displayName'],
          );
        },
      ),
      GoRoute(
        path: '/asana_detail',
        builder: (context, state) =>
            AsanaDetailScreen(asanaName: state.extra as String),
      ),
      GoRoute(path: '/filter', builder: (context, state) => const FilterScreen()),
      GoRoute(
        path: '/sequences',
        builder: (context, state) => const SequencesScreen(),
      ),
      GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
      GoRoute(
        path: '/timer',
        builder: (context, state) =>
            TimerScreen(asanas: state.extra as List<Map<String, dynamic>>?),
      ),
      GoRoute(
        path: '/timer_setup',
        builder: (context, state) => const TimerSetupScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin_user_detail',
        builder: (context, state) =>
            AdminUserDetailScreen(userId: state.extra as int),
      ),
      GoRoute(
        path: '/practice_history',
        builder: (context, state) => const PracticeHistoryScreen(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
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
    _router
        .push('/reset_password_form', extra: token)
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
        return MaterialApp.router(
          title: 'Dharana',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          routerConfig: _router,
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
