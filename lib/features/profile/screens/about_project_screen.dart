import 'package:flutter/material.dart';

import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/legal/legal_links.dart';
import 'package:dharana_app/l10n/app_localizations.dart';

/// Раздел «О проекте» с юридической информацией и ссылками на документы.
class AboutProjectScreen extends StatelessWidget {
  const AboutProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutProject)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.aboutLead, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          _Section(
            title: l10n.aboutMissionTitle,
            child: Text(l10n.aboutMissionText, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(height: 24),
          _Section(
            title: l10n.aboutWhatTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bullet(context, l10n.aboutWhatCatalog),
                _bullet(context, l10n.aboutWhatSequences),
                _bullet(context, l10n.aboutWhatTimer),
                _bullet(context, l10n.aboutWhatDaily),
                _bullet(context, l10n.aboutWhatStats),
                _bullet(context, l10n.aboutWhatPlatforms),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: l10n.aboutLegalTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.aboutLegalText, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                _LegalTile(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.privacyPolicy,
                  subtitle: l10n.aboutPrivacyHint,
                  onTap: () => LegalLinks.open(context, LegalLinks.privacy(context)),
                ),
                const SizedBox(height: 8),
                _LegalTile(
                  icon: Icons.description_outlined,
                  title: l10n.personalDataConsent,
                  subtitle: l10n.aboutConsentHint,
                  onTap: () => LegalLinks.open(context, LegalLinks.consent(context)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: l10n.aboutContactsTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.aboutContactsText, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => LegalLinks.open(context, 'mailto:${LegalLinks.supportEmail}'),
                  child: Text(
                    LegalLinks.supportEmail,
                    style: TextStyle(
                      color: AppTheme.AccentInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.aboutOperatorText,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.TextSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 8),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: AppTheme.AccentInk, shape: BoxShape.circle),
            ),
          ),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _LegalTile extends StatelessWidget {
  const _LegalTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.AccentInk),
        title: Text(title),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: Icon(Icons.open_in_new, size: 18, color: AppTheme.TextSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
