import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';
import 'package:dharana_app/l10n/app_localizations.dart';

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

  final _effectKeys = [
    'back_pain',
    'calm_mind',
    'boost_energy',
    'digestion',
    'flexibility',
    'balance',
    'strength',
    'stress_relief',
    'strength_abs',
    'knees',
    'neck_pain',
    'circulation',
    'lungs',
    'weight_loss',
  ];

  final _difficultyKeys = ['1', '2', '3'];

  final _categoryKeys = [
    'sit_lie+',
    'stay+',
    'hand+',
    'coup+',
    'sag+',
    'power+',
  ];

  String _effectLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'back_pain':
        return l10n.filterEffectBackPain;
      case 'calm_mind':
        return l10n.filterEffectCalmMind;
      case 'boost_energy':
        return l10n.filterEffectBoostEnergy;
      case 'digestion':
        return l10n.filterEffectDigestion;
      case 'flexibility':
        return l10n.filterEffectFlexibility;
      case 'balance':
        return l10n.filterEffectBalance;
      case 'strength':
        return l10n.filterEffectStrength;
      case 'stress_relief':
        return l10n.filterEffectStressRelief;
      case 'strength_abs':
        return l10n.filterEffectAbs;
      case 'knees':
        return l10n.filterEffectKnees;
      case 'neck_pain':
        return l10n.filterEffectNeck;
      case 'circulation':
        return l10n.filterEffectCirculation;
      case 'lungs':
        return l10n.filterEffectLungs;
      case 'weight_loss':
        return l10n.filterEffectWeightLoss;
    }
    return key;
  }

  String _difficultyLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case '1':
        return l10n.filterDifficultyBeginner;
      case '2':
        return l10n.filterDifficultyIntermediate;
      case '3':
        return l10n.filterDifficultyAdvanced;
    }
    return key;
  }

  String _categoryLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'sit_lie+':
        return l10n.filterCategorySitLie;
      case 'stay+':
        return l10n.filterCategoryStand;
      case 'hand+':
        return l10n.filterCategoryHands;
      case 'coup+':
        return l10n.filterCategoryBends;
      case 'sag+':
        return l10n.filterCategoryBackbends;
      case 'power+':
        return l10n.filterCategoryPower;
    }
    return key;
  }

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
          _error = e.toString().contains('type')
              ? AppLocalizations.of(context)!.filterParamsNotFound
              : e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.filterTitle),
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
            child: Text(l10n.filterReset,
                style: TextStyle(color: AppTheme.Accent)),
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
                Text(l10n.filterGoal, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _effectKeys.map((key) {
                    final isSelected = _selectedEffect == key;
                    return FilterChip(
                      label: Text(_effectLabel(l10n, key)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedEffect = selected ? key : null);
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
                Text(l10n.filterLevel, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _difficultyKeys.map((key) {
                    final isSelected = _selectedDifficulty == key;
                    return FilterChip(
                      label: Text(_difficultyLabel(l10n, key)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedDifficulty = selected ? key : null);
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
                Text(l10n.filterPosition, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categoryKeys.map((key) {
                    final isSelected = _selectedCategory == key;
                    return FilterChip(
                      label: Text(_categoryLabel(l10n, key)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedCategory = selected ? key : null);
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
                        : Text(l10n.filterShow),
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
                  Text(l10n.filterNoResults, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(l10n.filterNoResultsHint, style: Theme.of(context).textTheme.bodyMedium),
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
                    l10n.filterCountAsanas(_results.length),
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
                  final lang =
                      Localizations.localeOf(context).languageCode;
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
                      title: Text(asana.displayName(lang)),
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
                        context.push('/asana_detail', extra: asana.name);
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
