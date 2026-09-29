import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/models/models.dart';
import 'package:dharana_app/l10n/app_localizations.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;

  const CategoryCard({super.key, required this.category, this.onTap});

  static const Map<String, IconData> _icons = {
    'sit_lie+': Icons.airline_seat_recline_normal,
    'stay+': Icons.accessibility_new,
    'hand+': Icons.pan_tool,
    'coup+': Icons.arrow_upward,
    'sag+': Icons.waves,
    'power+': Icons.fitness_center,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _icons[category.id] ?? Icons.self_improvement,
                color: AppTheme.Accent,
                size: 28,
              ),
              const Spacer(),
              Text(
                category.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.categoryAsanaCount(category.asanaCount),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
