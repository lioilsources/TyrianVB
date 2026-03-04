import 'package:flutter_test/flutter_test.dart';
import 'package:tyrian_mobile/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const TyrianApp());
    expect(find.text('COMMAND CENTER'), findsOneWidget);
  });
}
