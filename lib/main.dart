import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'screens/auth_screen.dart';
import 'screens/driver_home_screen.dart';
import 'screens/driver_kyc_screen.dart';
import 'screens/login_screen.dart';
import 'screens/passenger_home_screen.dart';
import 'screens/register_screen.dart';
import 'utils/constants.dart';

Future<void> main() async {
  // Asegura la inicialización de los bindings del framework
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización resiliente de Supabase como Backend as a Service (BaaS)
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Aviso de inicialización Supabase: $e');
  }

  // Bloquea la orientación a vertical para uso seguro en soporte de motocicleta
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (_) {}

  // Configura la barra de navegación del sistema y barra de estado translúcida
  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  } catch (_) {}

  runApp(const RiobambaMotoApp());
}

/// Widget raíz de la aplicación "Riobamba Moto".
class RiobambaMotoApp extends StatelessWidget {
  const RiobambaMotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Pantalla inicial: Pantalla principal del Pasajero
      home: const PassengerHomeScreen(),

      // Rutas con nombre para navegación limpia
      routes: {
        '/passenger_home': (context) => const PassengerHomeScreen(),
        '/auth': (context) => const AuthScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/driver_home': (context) => const DriverHomeScreen(),
        '/driver_kyc': (context) => const DriverKycScreen(),
      },
    );
  }
}
