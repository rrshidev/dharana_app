import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';

class TheoryDetailScreen extends StatelessWidget {
  final String title;
  final TheoryItem item;

  const TheoryDetailScreen({
    super.key,
    required this.title,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                ApiClient().resolveUrl(imageUrl),
                fit: BoxFit.cover,
                height: 220,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            item.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.Surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.CardBorder),
            ),
            child: Text(
              item.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}