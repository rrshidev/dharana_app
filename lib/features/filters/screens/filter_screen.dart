import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final _api = ApiClient();
  String? _selectedCategory;
  String? _selectedDifficulty;
  String? _selectedEffect;
  List<Asana> _results = [];
  bool _isLoading = false;
  String? _error;
  bool _hasSearched = false;

  final _effects = [
    ('back_pain', '🦴 Боль в спине'),
    ('calm_mind', '🧘 Спокойствие'),
    ('boost_energy', '⚡ Энергия'),
    ('digestion', '🌿 Пищеварение'),
    ('flexibility', '🤸 Гибкость'),
    ('balance', '⚖️ Баланс'),
    ('strength', '💪 Сила'),
    ('stress_relief', '😌 Стресс'),
    ('strength_abs', '🎯 Пресс'),
    ('knees', '🦵 Колени'),
    ('neck_pain', '💆 Шея'),
    ('circulation', '❤️ Кровообращение'),
    ('lungs', '🫁 Дыхание'),
    ('weight_loss', '🔥 Похудение'),
  ];

  final _difficulties = [
    ('1', '★ Начинающий'),
    ('2', '★★ Средний'),
    ('3', '★★★ Продвинутый'),
  ];

  final _categories = [
    ('sit_lie+', 'Сидя и лёжа'),
    ('stay+', 'В позах стоя'),
    ('hand+', 'На руках'),
    ('coup+', 'Наклоны'),
    ('sag+', 'Прогибы'),
    ('power+', 'Силовые'),
  ];

  Future<void> _applyFilters() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
    });
    try {
      final params = <String, dynamic>{'limit': 50};
      if (_selectedCategory != null) params['category'] = _selectedCategory;
      if (_selectedDifficulty != null) {
        params['difficulty'] = int.parse(_selectedDifficulty!);
      }
      if (_selectedEffect != null) params['effect'] = _selectedEffect;

      final response = await _api.dio.get('/asanas', queryParameters: params);
      if (mounted) {
        setState(() {
          _results = AsanaListResponse.fromJson(response.data).items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки: ${e.toString().contains('type') ? 'параметры не найдены' : e}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подбор по параметрам'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory = null;
                _selectedDifficulty = null;
                _selectedEffect = null;
                _results = [];
              });
            },
            child: Text('Сбросить', style: TextStyle(color: AppTheme.Accent)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: _results.isEmpty ? 3 : 1,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Цель', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _effects.map((e) {
                    final isSelected = _selectedEffect == e.$1;
                    return FilterChip(
                      label: Text(e.$2),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedEffect = selected ? e.$1 : null);
                      },
                      selectedColor: AppTheme.Accent,
                      backgroundColor: AppTheme.SurfaceLight,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.TextSecondary,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text('Уровень', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _difficulties.map((d) {
                    final isSelected = _selectedDifficulty == d.$1;
                    return FilterChip(
                      label: Text(d.$2),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedDifficulty = selected ? d.$1 : null);
                      },
                      selectedColor: AppTheme.Accent,
                      backgroundColor: AppTheme.SurfaceLight,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.TextSecondary,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text('Позиция', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((c) {
                    final isSelected = _selectedCategory == c.$1;
                    return FilterChip(
                      label: Text(c.$2),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedCategory = selected ? c.$1 : null);
                      },
                      selectedColor: AppTheme.Accent,
                      backgroundColor: AppTheme.SurfaceLight,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.TextSecondary,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_selectedCategory != null ||
                            _selectedDifficulty != null ||
                            _selectedEffect != null)
                        ? _applyFilters
                        : null,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Показать'),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: TextStyle(color: AppTheme.Danger)),
            ),
          if (_hasSearched && _results.isEmpty && !_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48, color: AppTheme.TextSecondary.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text('Ничего не найдено', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Попробуйте другие параметры', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          if (_results.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${_results.length} асан',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final asana = _results[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.SurfaceLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: AppTheme.Accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      title: Text(asana.name),
                      subtitle: Row(
                        children: [
                          Text(
                            AppTheme.starsText(asana.difficulty),
                            style: AppTheme.difficultyStars(asana.difficulty),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              asana.categoryName ?? '',
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          '/asana_detail',
                          arguments: asana.name,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
