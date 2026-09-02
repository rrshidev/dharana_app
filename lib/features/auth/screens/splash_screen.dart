import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/features/auth/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final isLoggedIn = await AuthService().isLoggedIn();
    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/main');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.Accent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.self_improvement,
                size: 60,
                color: AppTheme.Background,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Dharana',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppTheme.Accent,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Йога энциклопедия',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              color: AppTheme.Accent,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
