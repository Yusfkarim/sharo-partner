import 'package:flutter_test/flutter_test.dart';
import 'package:sharo_partner/main.dart';

void main() {
  testWidgets('SharoPartnerApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SharoPartnerApp());
    expect(find.byType(SharoPartnerApp), findsOneWidget);
  });
}
