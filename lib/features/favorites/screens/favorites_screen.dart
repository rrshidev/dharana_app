import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dharana_app/app/language_controller.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';
import 'package:dharana_app/l10n/app_localizations.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _api = ApiClient();
  List<Favorite> _favorites = [];
  bool _isLoading = true;

  // Каноническое имя -> локализованное название для показа.
  // Избранное приходит с сервера только с asana_name, поэтому подтягиваем
  // справочник из /asanas, где есть name_en/name_ru.
  Map<String, String> _nameByCanonical = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getFavorites();
      await _loadNameMap();
      if (mounted) {
        setState(() {
          _favorites = data.map((f) => Favorite.fromJson(f)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNameMap() async {
    try {
      final resp = await _api.dio.get('/asanas', queryParameters: {'limit': 200});
      final items = (resp.data as Map)['items'] as List? ?? [];
      final lang = LanguageController.instance.value.languageCode;
      _nameByCanonical = {
        for (final raw in items)
          (raw as Map)['name'] as String:
              Asana.fromJson(Map<String, dynamic>.from(raw)).displayName(lang)
      };
    } catch (_) {
      // Не критично: при неудаче останутся канонические названия.
      _nameByCanonical = {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.favorites)),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.Accent))
          : _favorites.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  color: AppTheme.Accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      final fav = _favorites[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(Icons.favorite, color: AppTheme.Danger),
                          title: Text(_nameByCanonical[fav.asanaName] ?? fav.asanaName),
                          subtitle: Text(
                            fav.createdAt?.substring(0, 10) ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: AppTheme.TextSecondary,
                            onPressed: () => _removeFavorite(fav.asanaName),
                          ),
                          onTap: () {
                            context.push('/asana_detail', extra: fav.asanaName);
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: AppTheme.TextSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            l10n.favoritesEmpty,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.TextSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.favoritesEmptyHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _removeFavorite(String asanaName) async {
    try {
      await _api.toggleFavorite(asanaName);
      if (mounted) {
        setState(() {
          _favorites.removeWhere((f) => f.asanaName == asanaName);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.removedFavorite(asanaName)),
            backgroundColor: AppTheme.SurfaceLight,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.errorMessage('$e')),
              backgroundColor: AppTheme.Danger),
        );
      }
    }
  }
}
