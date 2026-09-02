import 'package:flutter/material.dart';
import 'dart:async';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';
import 'package:dharana_app/shared/widgets/asana_card.dart';
import 'package:dharana_app/shared/widgets/category_card.dart';
import 'package:dharana_app/shared/widgets/loading_skeleton.dart';
import 'package:dharana_app/features/auth/services/auth_service.dart';
import 'package:dharana_app/features/filters/screens/filter_screen.dart';
import 'package:dharana_app/features/sequences/screens/sequences_screen.dart';
import 'package:dharana_app/features/search/screens/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiClient();
  List<Category> _categories = [];
  Asana? _dailyAsana;
  User? _user;
  bool _isLoading = true;
  Timer? _greetingTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startGreetingTimer();
  }

  void _startGreetingTimer() {
    _greetingTimer?.cancel();
    _greetingTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        if (mounted) {
          final current = _greeting();
          final shown = _shownGreeting;
          if (current != shown) {
            setState(() => _shownGreeting = current);
          }
        }
      },
    );
  }

  String? _shownGreeting;

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final categoriesResp = await _api.dio.get('/categories');
      final dailyResp = await _api.dio.get('/asanas/random');
      final user = await AuthService().getCurrentUser();

      if (mounted) {
        setState(() {
          _categories = (categoriesResp.data as List)
              .map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList();
          _dailyAsana =
              Asana.fromJson(dailyResp.data as Map<String, dynamic>);
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Доброй ночи';
    if (hour < 12) return 'Доброе утро';
    if (hour < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  String get _currentGreeting => _shownGreeting ?? _greeting();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const HomeSkeleton()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.Accent,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_currentGreeting, ${_user?.name ?? 'йог'}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Практикуй регулярно',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        children: [
                          _QuickTile(
                            icon: Icons.tune,
                            label: 'Подбор',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const FilterScreen()),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          _QuickTile(
                            icon: Icons.video_library_outlined,
                            label: 'Комплексы',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SequencesScreen()),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          _QuickTile(
                            icon: Icons.search,
                            label: 'Поиск',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SearchScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_dailyAsana != null) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Асана дня',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AsanaCard(
                          asana: _dailyAsana!,
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              '/asana_detail',
                              arguments: _dailyAsana!.name,
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                      child: Text(
                        'Категории',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.4,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return CategoryCard(
                            category: _categories[index],
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                '/category',
                                arguments: {
                                  'categoryId': _categories[index].id,
                                  'displayName': _categories[index].displayName,
                                },
                              );
                            },
                          );
                        },
                        childCount: _categories.length,
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: const SizedBox(height: 100),
                  ),
                ],
              ),
            ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppTheme.Surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.CardBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.Accent, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
