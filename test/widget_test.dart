// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:assistance_app/main.dart';
import 'package:assistance_app/data/providers/auth_provider.dart';
import 'package:assistance_app/data/providers/todo_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => AuthProvider()),
          ChangeNotifierProvider(create: (context) => TodoProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the app loads without crashing
    await tester.pumpAndSettle();
    
    // Should show loading or login page initially
    expect(find.byType(CircularProgressIndicator), findsAny);
  });
}
