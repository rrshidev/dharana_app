import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dharana_app/l10n/app_localizations.dart';

/// Канонические адреса юридических документов на сайте.
class LegalLinks {
  /// Версия документов, которую пользователь видит в приложении.
  /// Держим в синхроне с сайтом и API.
  static const version = '1.0';

  static const privacyRu = 'https://dharana.ru/ru/privacy';
  static const privacyEn = 'https://dharana.ru/en/privacy';
  static const consentRu = 'https://dharana.ru/ru/consent';
  static const consentEn = 'https://dharana.ru/en/consent';
  static const aboutRu = 'https://dharana.ru/ru/about';
  static const aboutEn = 'https://dharana.ru/en/about';
  static const supportEmail = 'support@dharana.ru';

  static bool _isEn(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'en';

  static String privacy(BuildContext context) =>
      _isEn(context) ? privacyEn : privacyRu;

  static String consent(BuildContext context) =>
      _isEn(context) ? consentEn : consentRu;

  static String about(BuildContext context) =>
      _isEn(context) ? aboutEn : aboutRu;

  static Future<void> open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.linkOpenFailed)),
      );
    }
  }
}
