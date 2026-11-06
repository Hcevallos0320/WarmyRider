import 'package:supabase_flutter/supabase_flutter.dart';

/// Constantes y credenciales de conexión con Supabase (BaaS).
class SupabaseConstants {
  SupabaseConstants._();

  /// URL del proyecto en Supabase
  static const String supabaseUrl = 'https://gglnxsoajmiuwwetlubt.supabase.co';

  /// Clave anónima / publishable key del proyecto en Supabase
  static const String supabaseAnonKey = 'sb_publishable_QhQ5PqmVqiWs-lvtOXcXaA_3ARhxKTU';
}

/// Variables constantes de acceso directo
const String supabaseUrl = SupabaseConstants.supabaseUrl;
const String supabaseAnonKey = SupabaseConstants.supabaseAnonKey;

/// Cliente global de Supabase para consultas a PostgreSQL, autenticación y Realtime
final supabase = Supabase.instance.client;
