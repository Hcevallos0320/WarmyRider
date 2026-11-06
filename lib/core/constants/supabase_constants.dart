import 'package:supabase_flutter/supabase_flutter.dart';

/// Constantes y credenciales de conexión con Supabase (BaaS).
class SupabaseConstants {
  SupabaseConstants._();

  /// URL del proyecto en Supabase
  static const String supabaseUrl = 'https://gglnxsoajmiuwwetlubt.supabase.co';

  /// Clave anónima / publishable key del proyecto en Supabase
  static const String supabaseAnonKey = 'sb_publishable_QhQ5PqmVqiWs-lvtOXcXaA_3ARhxKTU';

  /// Client ID de Google OAuth para la Web (Google Cloud Console).
  ///
  /// En el navegador Web (Chrome/Edge), la librería de Google exige un Web Client ID.
  /// Para obtenerlo:
  /// 1. Ve a https://console.cloud.google.com/apis/credentials
  /// 2. Crea un "ID de cliente de OAuth" -> "Aplicación web".
  /// 3. Agrega tu origen autorizado (ej: http://localhost:PORT).
  /// 4. Pégalo aquí o en web/index.html.
  ///
  /// Si lo dejas vacío, la aplicación detectará el entorno Web y te permitirá
  /// continuar con el selector de cuentas de prueba para no bloquear tu desarrollo.
  static const String googleWebClientId = '';
}

/// Variables constantes de acceso directo
const String supabaseUrl = SupabaseConstants.supabaseUrl;
const String supabaseAnonKey = SupabaseConstants.supabaseAnonKey;

/// Cliente global de Supabase para consultas a PostgreSQL, autenticación y Realtime
final supabase = Supabase.instance.client;
