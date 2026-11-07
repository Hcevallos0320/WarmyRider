import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riobamba_moto/main.dart';
import 'package:riobamba_moto/screens/auth_screen.dart';

void main() {
  testWidgets('Verifica renderizado inicial de rumbo (Riobamba Moto) AuthScreen', (WidgetTester tester) async {
    // Construir la app y disparar un frame
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

    // Verificar que aparece la marca rumbo y la ciudad
    expect(find.text('rumbo'), findsOneWidget);
    expect(find.text('RIOBAMBA, EC'), findsOneWidget);

    // Verificar textos de bienvenida
    expect(find.textContaining('Tu ciudad'), findsOneWidget);
    expect(find.textContaining('A tu ritmo'), findsOneWidget);

    // Verificar selector de roles interactivo
    expect(find.text('Soy Pasajero'), findsOneWidget);
    expect(find.text('Soy Conductor'), findsOneWidget);

    // Verificar selector de modo (Crear Cuenta / Iniciar Sesión)
    expect(find.text('Crear Cuenta'), findsWidgets);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });

  testWidgets('Verifica renderizado de PassengerHomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const RiobambaMotoApp());
    await tester.pump();

    expect(find.text('ESPOCH'), findsOneWidget);
    expect(find.text('Pedir Moto'), findsOneWidget);
  });
}
