// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:godoc/main.dart';

void main() {
  testWidgets('App loads the unified login screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GoDocApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Patient'), findsOneWidget);
    expect(find.text('Doctor'), findsOneWidget);
    expect(
      find.text('Sign in to continue to your patient or doctor workspace.'),
      findsOneWidget,
    );
    expect(find.text('Login as Patient'), findsOneWidget);
  });
}
