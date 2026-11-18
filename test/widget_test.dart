import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Framework smoke test.
///
/// This file intentionally exists so that `flutter create .` (used by the CI
/// workflows to restore the android/ios platform scaffolding) never generates
/// its template counter-app test here — that template references a `MyApp`
/// class that does not exist in this project and would break `flutter test`.
void main() {
  testWidgets('smoke: the Flutter framework renders a simple app',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('toadTIMER')),
        ),
      ),
    );

    expect(find.text('toadTIMER'), findsOneWidget);
  });
}
