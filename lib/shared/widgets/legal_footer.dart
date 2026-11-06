import 'package:flutter/material.dart';

import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/legal/legal_links.dart';
import 'package:dharana_app/l10n/app_localizations.dart';

/// Ссылки на юридические документы внизу экранов входа и регистрации.
class LegalFooter extends StatelessWidget {
  const LegalFooter({super.key, this.alignment = WrapAlignment.center});

  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = TextStyle(
      color: AppTheme.TextSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    return Wrap(
      alignment: alignment,
      spacing: 12,
      runSpacing: 4,
      children: [
        TextButton(
          onPressed: () => LegalLinks.open(context, LegalLinks.privacy(context)),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.AccentInk,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(l10n.privacyPolicy, style: style.copyWith(color: AppTheme.AccentInk)),
        ),
        TextButton(
          onPressed: () => LegalLinks.open(context, LegalLinks.consent(context)),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.AccentInk,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(l10n.personalDataConsent, style: style.copyWith(color: AppTheme.AccentInk)),
        ),
      ],
    );
  }
}
