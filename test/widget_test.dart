import 'package:flutter_test/flutter_test.dart';
import 'package:rcf_tracker/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const RCFTrackerApp());
    expect(find.text('Sign In'), findsOneWidget);
  });
}
