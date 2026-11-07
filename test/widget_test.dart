import 'package:flutter_test/flutter_test.dart';
import 'package:riobamba_moto/main.dart';

void main() {
  testWidgets('Verifica renderizado inicial de rumbo (Riobamba Moto) AuthScreen', (WidgetTester tester) async {
    // Construir la app y disparar un frame
    await tester.pumpWidget(const RiobambaMotoApp());

    // Verificar que aparece la marca rumbo y la ciudad
    expect(find.text('rumbo'), findsOneWidget);
    expect(find.text('RIOBAMBA, EC'), findsOneWidget);

    // Verificar textos de bienvenida
    expect(find.text('Tu ciudad.'), findsOneWidget);
    expect(find.text('A tu ritmo.'), findsOneWidget);

    // Verificar selector de roles interactivo
    expect(find.text('Soy Pasajero'), findsOneWidget);
    expect(find.text('Soy Conductor'), findsOneWidget);

    // Verificar selector de modo (Crear Cuenta / Iniciar Sesión)
    expect(find.text('Crear Cuenta'), findsWidgets);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
