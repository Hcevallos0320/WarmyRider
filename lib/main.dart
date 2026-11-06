import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_constants.dart';
import 'screens/auth_screen.dart';
import 'screens/driver_home_screen.dart';
import 'screens/driver_kyc_screen.dart';
import 'screens/passenger_home_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

Future<void> main() async {
  // Asegura la inicialización de los bindings del framework
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Supabase (PostgreSQL, Auth, Realtime)
  // Usamos las constantes definidas en lib/core/supabase_constants.dart
  try {
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: SupabaseConstants.supabaseAnonKey,
    );
  } catch (error) {
    debugPrint('Aviso Supabase: Pendiente configurar credenciales reales ($error)');
  }

  // Bloquea la orientación a vertical para uso seguro en soporte de motocicleta
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configura la barra de navegación del sistema y barra de estado translúcida
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const RiobambaMotoApp());
}

/// Widget raíz de la aplicación "Riobamba Moto".
/// Configura el tema Material 3 Dark Mode obligatorio y las rutas del flujo principal.
class RiobambaMotoApp extends StatelessWidget {
  const RiobambaMotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Forzar Modo Oscuro profundo por defecto
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,

      // Pantalla inicial: Autenticación unificada (Pasajero & Conductor)
      home: const AuthScreen(),

      // Rutas con nombre para navegación limpia
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/passenger_home': (context) => const PassengerHomeScreen(),
        '/driver_home': (context) => const DriverHomeScreen(),
        '/driver_kyc': (context) => const DriverKycScreen(),
      },
    );
  }
}
