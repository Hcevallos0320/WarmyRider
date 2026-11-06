import 'package:flutter_test/flutter_test.dart';
import 'package:riobamba_moto/main.dart';

void main() {
  testWidgets('Verifica renderizado inicial de Riobamba Moto AuthScreen', (WidgetTester tester) async {
    // Construir la app y disparar un frame
    await tester.pumpWidget(const RiobambaMotoApp());

    // Verificar que aparece el título de Riobamba Moto
    expect(find.text('Riobamba Moto'), findsOneWidget);

    // Verificar selector de roles interactivo
    expect(find.text('Soy Pasajero'), findsOneWidget);
    expect(find.text('Soy Conductor'), findsOneWidget);

    // Verificar selector de modo (Iniciar Sesión / Crear Cuenta)
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Crear Cuenta'), findsOneWidget);

    // Verificar botón principal Ingresar
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
