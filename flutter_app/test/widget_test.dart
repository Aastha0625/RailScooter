import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscoot/screens/auth/login_screen.dart';

void main() {
  testWidgets('login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
