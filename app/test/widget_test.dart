import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart';
import 'package:app/pages/welcome_page.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BillManagerApp());

    // Verify that WelcomePage is displayed initially
    expect(find.byType(WelcomePage), findsOneWidget);
  });
}
