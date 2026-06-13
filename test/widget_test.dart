import 'package:flutter_test/flutter_test.dart';
import 'package:dentifykids/main.dart';

void main() {
  testWidgets('DentifyKidsApp renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const DentifyKidsApp(showOnboarding: true));
    expect(find.byType(DentifyKidsApp), findsOneWidget);
  });
}
