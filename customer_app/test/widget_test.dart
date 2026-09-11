import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/main.dart';

void main() {
  testWidgets('NileSky customer app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NileSkyCustomerApp());
    expect(find.text('NileSky'), findsOneWidget);
  });
}
