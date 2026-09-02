import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _api = ApiClient();
  List<Asana> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final response = await _api.dio.get('/asanas', queryParameters: {
        'search': query.trim(),
        'limit': 50,
      });
      if (mounted) {
        setState(() {
          _results = AsanaListResponse.fromJson(response.data).items;
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
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Поиск асан...',
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _results = [];
                        _hasSearched = false;
                      });
                    },
                  )
                : null,
          ),
          onSubmitted: _search,
          onChanged: (_) => setState(() {}),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.Accent))
          : !_hasSearched
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: AppTheme.TextSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'Введите название асаны',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : _results.isEmpty
                  ? Center(
                      child: Text(
                        'Ничего не найдено',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final asana = _results[index];
                        return ListTile(
                          leading: asana.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    '${ApiClient.baseUrl}${asana.imageUrl}',
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 48,
                                      height: 48,
                                      color: AppTheme.SurfaceLight,
                                      child: Icon(Icons.self_improvement,
                                          color: AppTheme.Accent),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.SurfaceLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.self_improvement,
                                      color: AppTheme.Accent),
                                ),
                          title: Text(asana.name),
                          subtitle: Text(
                            AppTheme.starsText(asana.difficulty),
                            style: AppTheme.difficultyStars(asana.difficulty),
                          ),
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              '/asana_detail',
                              arguments: asana.name,
                            );
                          },
                        );
                      },
                    ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
