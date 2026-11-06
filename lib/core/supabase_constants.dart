import 'package:supabase_flutter/supabase_flutter.dart';

/// Constantes de configuración de Supabase para la plataforma Riobamba Moto (WarmyRider).
///
/// Gestiona la conexión a PostgreSQL, el sistema de autenticación de usuarios
/// y la escucha de eventos en tiempo real (Realtime).
class SupabaseConstants {
  SupabaseConstants._();

  /// URL del proyecto Supabase (Project URL).
  /// Reemplaza este texto por la URL provista en el dashboard de Supabase (Settings > API).
  /// Ejemplo: 'https://xyzprojectid.supabase.co'
  static const String supabaseUrl = 'https://tu-proyecto-aqui.supabase.co';

  /// Clave pública anónima (anon / public key).
  /// Reemplaza este texto por tu anon key segura para clientes móviles (Settings > API).
  static const String supabaseAnonKey = 'TU_ANON_KEY_AQUI';
}

/// Cliente global accesible en toda la app para ejecutar consultas a la base de datos,
/// gestionar autenticación (Auth) y suscripciones en tiempo real (Realtime).
///
/// Ejemplo de uso:
/// ```dart
/// // Autenticación de pasajero o conductor
/// await supabase.auth.signInWithPassword(email: email, password: password);
///
/// // Escucha en tiempo real de viajes solicitados
/// final stream = supabase.from('rides').stream(primaryKey: ['id']);
/// ```
final supabase = Supabase.instance.client;
