import 'package:flutter/material.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';
import 'package:dharana_app/shared/widgets/asana_card.dart';
import 'package:dharana_app/shared/widgets/loading_skeleton.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryId;
  final String displayName;

  const CategoryScreen({
    super.key,
    required this.categoryId,
    required this.displayName,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _api = ApiClient();
  List<Asana> _asanas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAsanas();
  }

  Future<void> _loadAsanas() async {
    try {
      final response = await _api.dio
          .get('/categories/${widget.categoryId}/asanas');
      if (mounted) {
        setState(() {
          _asanas = (response.data['items'] as List)
              .map((e) => Asana.fromJson(e))
              .toList();
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
        title: Text(widget.displayName),
      ),
      body: _isLoading
          ? const CatalogSkeleton()
          : _asanas.isEmpty
              ? Center(
                  child: Text(
                    'В этой категории пока нет асан',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _asanas.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AsanaCard(
                        asana: _asanas[index],
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/asana_detail',
                            arguments: _asanas[index].name,
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
