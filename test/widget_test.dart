import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riobamba_moto/main.dart';
import 'package:riobamba_moto/screens/passenger_home_screen.dart';

void main() {
  testWidgets('Verifica renderizado inicial de LoginScreen en RiobambaMotoApp', (WidgetTester tester) async {
    // Construir la app y disparar un frame
    await tester.pumpWidget(const RiobambaMotoApp());

    // Verificar que aparece la marca rumbo y la ciudad
    expect(find.text('rumbo'), findsOneWidget);
    expect(find.text('RIOBAMBA, EC'), findsOneWidget);

    // Verificar títulos de bienvenida
    expect(find.text('Bienvenido.'), findsOneWidget);
    expect(find.text('De nuevo.'), findsOneWidget);

    // Verificar botón principal y enlace de registro
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Crear una cuenta nueva'), findsOneWidget);
  });

  testWidgets('Verifica renderizado de PassengerHomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PassengerHomeScreen()));
    await tester.pump();

    expect(find.text('ESPOCH'), findsOneWidget);
    expect(find.text('Pedir Moto'), findsOneWidget);
  });
}
