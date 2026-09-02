import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/features/home/screens/home_screen.dart';
import 'package:dharana_app/features/timer/screens/timer_setup_screen.dart';
import 'package:dharana_app/features/favorites/screens/favorites_screen.dart';
import 'package:dharana_app/features/profile/screens/profile_screen.dart';
import 'package:dharana_app/shared/widgets/notification_bell.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    TimerSetupScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Stack(
        children: [
          _screens[_currentIndex],
          if (_currentIndex != 3)
            Positioned(
              top: padding + 6,
              right: 10,
              child: NotificationBell(),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: AppTheme.Surface,
        indicatorColor: AppTheme.Accent.withValues(alpha: 0.2),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppTheme.Accent),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer, color: AppTheme.Accent),
            label: 'Таймер',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite, color: AppTheme.Accent),
            label: 'Избранное',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person, color: AppTheme.Accent),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
