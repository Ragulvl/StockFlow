import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockflow/main.dart';

void main() {
  testWidgets('App renders clean dashboard root test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: StockFlowApp(),
      ),
    );
    expect(find.byType(StockFlowApp), findsOneWidget);
  });
}
