import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bitacora_gps/app/app.dart';

void main() {
  testWidgets('App renders setup screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BitacoraGpsApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('BITÁCORA GPS'), findsOneWidget);
  });
}
