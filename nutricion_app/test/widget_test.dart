// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutricion_app/main.dart';

void main() {
  testWidgets('Login screen loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NutricionApp());

    // Verify that the login screen shows the app title.
    expect(find.text('NutricionApp'), findsOneWidget);
    expect(find.text('Sistema de Nutrición Personalizada'), findsOneWidget);
    
    // Verify role buttons exist
    expect(find.text('Nutricionista'), findsOneWidget);
    expect(find.text('Paciente'), findsOneWidget);
  });
}
