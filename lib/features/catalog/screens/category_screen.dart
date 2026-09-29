import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/app/language_controller.dart';
import 'package:dharana_app/core/models/models.dart';
import 'package:dharana_app/shared/widgets/asana_card.dart';
import 'package:dharana_app/shared/widgets/loading_skeleton.dart';
import 'package:dharana_app/shared/widgets/share_button.dart';
import 'package:dharana_app/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final lang = LanguageController.instance.value.languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.displayName),
        actions: [
          ShareButton(
            message:
                '${l10n.shareCatalogText(widget.displayName)}\nhttps://dharana.ru/$lang/catalog?category=${Uri.encodeQueryComponent(widget.categoryId)}',
          ),
        ],
      ),
      body: _isLoading
          ? const CatalogSkeleton()
          : _asanas.isEmpty
              ? Center(
                  child: Text(
                    l10n.categoryEmpty,
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
                          context.push('/asana_detail',
                              extra: _asanas[index].name);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
