import 'package:flutter_test/flutter_test.dart';
import 'package:tinkiyagro_app/main.dart';

void main() {
  testWidgets('App landing screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TinkiyAgroApp());

    // Verify that our landing page has 'Iniciar Sesión' button.
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
