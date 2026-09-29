import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dharana_app/l10n/app_localizations.dart';

class ShareButton extends StatelessWidget {
  final String message;

  const ShareButton({super.key, required this.message});

  Future<void> _share(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await SharePlus.instance.share(ShareParams(text: message));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.shareFailed('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.share_outlined),
      tooltip: AppLocalizations.of(context)!.shareTooltip,
      onPressed: () => _share(context),
    );
  }
}