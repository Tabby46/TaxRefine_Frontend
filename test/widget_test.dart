import 'package:flutter_test/flutter_test.dart';
import 'package:taxrefine/main.dart';

void main() {
  testWidgets('App boots and shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TaxRefineApp());

    expect(find.text('TaxRefine Frontend Ready'), findsOneWidget);
  });
}
