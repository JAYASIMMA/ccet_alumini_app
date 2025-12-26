import 'package:flutter_test/flutter_test.dart';
import 'package:ccet_alumini_app/main.dart';

void main() {
  testWidgets('Welcome screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the welcome text is present.
    expect(find.text('CCET Alumni'), findsOneWidget);
    expect(find.text('Connect, Network, Grow.'), findsOneWidget);
  });
}
