import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';

class AsanaCard extends StatelessWidget {
  final Asana asana;
  final VoidCallback? onTap;

  const AsanaCard({super.key, required this.asana, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: asana.imageUrl != null
                  ? Image.network(
                      '${ApiClient.baseUrl}${asana.imageUrl}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asana.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppTheme.starsText(asana.difficulty),
                      style: AppTheme.difficultyStars(asana.difficulty),
                    ),
                    if (asana.effects.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        asana.effects.take(3).map(_effectEmoji).join(' '),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.surfaceLight,
      child: const Icon(Icons.self_improvement, color: AppTheme.accent, size: 36),
    );
  }

  String _effectEmoji(String effect) {
    const emojis = {
      'back_pain': '🦴',
      'calm_mind': '🧘',
      'boost_energy': '⚡',
      'digestion': '🌿',
      'flexibility': '🤸',
      'balance': '⚖️',
      'strength': '💪',
      'stress_relief': '😌',
    };
    return emojis[effect] ?? '🎯';
  }
}
