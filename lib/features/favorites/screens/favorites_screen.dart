import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _api = ApiClient();
  List<Favorite> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getFavorites();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _favorites.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  color: AppTheme.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      final fav = _favorites[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.favorite, color: AppTheme.danger),
                          title: Text(fav.asanaName),
                          subtitle: Text(
                            fav.createdAt?.substring(0, 10) ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: AppTheme.textSecondary,
                            onPressed: () => _removeFavorite(fav.asanaName),
                          ),
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              '/asana_detail',
                              arguments: fav.asanaName,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Нет избранных асан',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавляйте асаны в избранное\nнажимая сердечко на деталях',
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
            content: Text('$asanaName удалено из избранного'),
            backgroundColor: AppTheme.surfaceLight,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }
}
