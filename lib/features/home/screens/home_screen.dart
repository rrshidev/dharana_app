import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';
import 'package:dharana_app/shared/widgets/asana_card.dart';
import 'package:dharana_app/shared/widgets/category_card.dart';
import 'package:dharana_app/shared/widgets/loading_skeleton.dart';
import 'package:dharana_app/features/auth/services/auth_service.dart';
import 'package:dharana_app/l10n/app_localizations.dart';

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
          final current = _greeting(AppLocalizations.of(context)!);
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
      final dailyResp = await _api.dio.get('/asanas/day');
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

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 6) return l10n.greetingGoodNight;
    if (hour < 12) return l10n.greetingGoodMorning;
    if (hour < 18) return l10n.greetingGoodDay;
    return l10n.greetingGoodEvening;
  }

  String get _currentGreeting =>
      _shownGreeting ?? _greeting(AppLocalizations.of(context)!);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: _isLoading
          ? const HomeSkeleton()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.AccentInk,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.homeGreeting(
                                _currentGreeting, _user?.name ?? l10n.yogi),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.practiceRegularly,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _GeneratorBanner(
                        onTap: () {
                          context.push('/generator');
                        },
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
                            label: l10n.quickFilter,
                            onTap: () {
                              context.push('/filter');
                            },
                          ),
                          const SizedBox(width: 12),
                          _QuickTile(
                            icon: Icons.video_library_outlined,
                            label: l10n.quickComplexes,
                            onTap: () {
                              context.push('/sequences');
                            },
                          ),
                          const SizedBox(width: 12),
                          _QuickTile(
                            icon: Icons.search,
                            label: l10n.quickSearch,
                            onTap: () {
                              context.push('/search');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          _QuickTile(
                            icon: Icons.menu_book_outlined,
                            label: l10n.quickBasics,
                            onTap: () {
                              context.push('/basics');
                            },
                          ),
                          const SizedBox(width: 12),
                          _QuickTile(
                            icon: Icons.layers_outlined,
                            label: l10n.quickSteps,
                            onTap: () {
                              context.push('/steps');
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
                              l10n.dailyAsana,
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
                            context.push('/asana_detail',
                                extra: _dailyAsana!.name);
                          },
                        ),
                      ),
                    ),
                  ],

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                      child: Text(
                        l10n.categories,
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
                              context.push(
                                '/category',
                                extra: {
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

class _GeneratorBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _GeneratorBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.Surface,
              AppTheme.Accent.withValues(alpha: 0.18),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.CardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.AccentInk.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.auto_awesome, color: AppTheme.AccentInk),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.generatorTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.generatorSubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.TextSecondary),
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
              Icon(icon, color: AppTheme.AccentInk, size: 26),
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
