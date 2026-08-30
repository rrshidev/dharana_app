import 'package:flutter_test/flutter_test.dart';
import 'package:dharana_app/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DharanaApp());
    await tester.pumpAndSettle();
    expect(find.text('Dharana'), findsOneWidget);
  });
}
