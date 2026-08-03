import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sistemavalle/providers/auth_provider.dart';
import 'package:sistemavalle/providers/cliente_provider.dart';
import 'package:sistemavalle/screens/login_screen.dart';

void main() {
  testWidgets('muestra la pantalla de login', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          authProvider: AuthProvider(),
          clienteProvider: ClienteProvider(),
        ),
      ),
    );

    expect(find.text('Sistema Valle'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
