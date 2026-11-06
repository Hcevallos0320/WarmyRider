import 'package:flutter/material.dart';

/// Paleta de colores oficial de "Riobamba Moto".
/// Inspirada en los colores de la bandera de Riobamba (Rojo y Azul)
/// adaptada a una estética Dark Mode Premium con alto contraste.
class AppColors {
  // Fondos principales (Dark Mode profundo / OLED friendly)
  static const Color background = Color(0xFF0A0F1D); // Azul Noche Profundo
  static const Color surface = Color(0xFF141C2F); // Azul Pizarra Oscuro
  static const Color surfaceElevated = Color(0xFF1E2638);
  static const Color surfaceTransparent = Color(0xD9141C2F); // 85% opacidad para efecto vidrio

  // Identidad Riobamba - Colores Dinámicos por Rol
  static const Color riobambaRed = Color(0xFFFF2E4C); // Rojo Carmesí Vibrante (Pasajero)
  static const Color riobambaBlue = Color(0xFF2962FF); // Azul Eléctrico (Conductor)

  // Paleta Light Mode (Modo Claro - Identidad Riobamba)
  static const Color lightBackground = Color(0xFFF8F9FA); // Gris ultra claro
  static const Color lightSurface = Color(0xFFFFFFFF); // Blanco puro para tarjetas
  static const Color lightSurfaceSubtle = Color(0xFFF1F5F9); // Gris sutil para chips/inputs
  static const Color lightTextPrimary = Color(0xFF1A1D24); // Título en Negro profundo
  static const Color lightTextSecondary = Color(0xFF64748B); // Subtítulos en Gris Pizarra
  static const Color lightBorder = Color(0xFFE2E8F0); // Borde sutil claro
  static const Color pickupGreen = Color(0xFF00C853); // Verde esmeralda para punto de recogida

  // Colores de Acento y Acción Principal (Alta Visibilidad para conducción)
  static const Color primaryNeon = Color(0xFF00E676); // Verde Neón (Conectado / Aceptar)
  static const Color primaryNeonDark = Color(0xFF00B050);
  static const Color accentOrange = Color(0xFFFF9100); // Naranja brillante para alertas/rutas
  
  // Estados del Conductor
  static const Color statusOnline = Color(0xFF00E676); // En línea
  static const Color statusOffline = Color(0xFFFF3B30); // Desconectado (Rojo brillante)
  static const Color statusBusy = Color(0xFFFFCC00); // En viaje / Ocupado

  // Textos con alto contraste
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8); // Gris Azulado moderno
  static const Color textMuted = Color(0xFF64748B);
  static const Color textOnNeon = Color(0xFF051B11); // Texto oscuro legible sobre verde neón

  // Bordes y separadores
  static const Color border = Color(0xFF232D42);
  static const Color borderActive = Color(0xFF2962FF);
  static const Color divider = Color(0xFF1F293D);

  // Mapa simulado (Dark Style de Google Maps)
  static const Color mapBackground = Color(0xFF12161F);
  static const Color mapRoad = Color(0xFF1D2330);
  static const Color mapMainArtery = Color(0xFF2A3446);
  static const Color mapWater = Color(0xFF0C131D);
}
