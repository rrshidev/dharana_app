import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dharana_app/app/app.dart';
import 'package:dharana_app/l10n/app_localizations.dart';

Widget _wrap(Locale locale, Widget child) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

Future<AppLocalizations> _localizationsFor(
  WidgetTester tester,
  Locale locale,
) async {
  late AppLocalizations result;
  await tester.pumpWidget(_wrap(
    locale,
    Builder(
      builder: (context) {
        result = AppLocalizations.of(context)!;
        return const SizedBox.shrink();
      },
    ),
  ));
  return result;
}

void main() {
  testWidgets('App builds and resolves localizations', (tester) async {
    await tester.pumpWidget(const DharanaApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsWidgets);
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp).first).locale,
        isNotNull);

    // Tear the tree down before the splash delay elapses, then let the
    // pending timer drain so flutter_test does not report a pending timer.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('both locales are supported', (tester) async {
    expect(
        AppLocalizations.supportedLocales, contains(const Locale('ru')));
    expect(
        AppLocalizations.supportedLocales, contains(const Locale('en')));
  });

  testWidgets('ru and en resolve to different strings', (tester) async {
    final ru = await _localizationsFor(tester, const Locale('ru'));
    final en = await _localizationsFor(tester, const Locale('en'));

    expect(ru.appTitle, isNotEmpty);
    expect(en.appTitle, isNotEmpty);
    expect(ru.splashTagline, isNot(en.splashTagline));
    expect(ru.cancel, isNot(en.cancel));
    expect(ru.errorMessage('x'), isNot(en.errorMessage('x')));
    expect(ru.close, isNot(en.close));
  });
}
