import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Tarjeta semi-transparente superior que muestra las ganancias diarias del motorizado.
/// Incluye efecto "Glassmorphism" con BackdropFilter optimizado para alto rendimiento.
class EarningsCard extends StatelessWidget {
  final String earningsAmount;
  final int completedTrips;
  final String onlineTime;
  final VoidCallback? onMenuTap;

  const EarningsCard({
    super.key,
    this.earningsAmount = '\$ 15.50',
    this.completedTrips = 6,
    this.onlineTime = '2h 45m',
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceTransparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fila superior: Menú, Título "Hoy" y Perfil
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón menú lateral (accesible rápidamente con el pulgar)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onMenuTap,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.menu_rounded,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),

                  // Título central
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNeon.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryNeon.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.electric_bolt_rounded,
                          size: 14,
                          color: AppColors.primaryNeon,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'GANANCIAS DE HOY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.primaryNeon,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Avatar o indicador de reputación
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '4.9',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Ganancia Principal Gigante (Lectura inmediata sin apartar la vista del camino)
              Text(
                earningsAmount,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              // Métricas rápidas: Viajes completados y tiempo activo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMetricItem(
                      icon: Icons.check_circle_outline_rounded,
                      label: '$completedTrips viajes',
                    ),
                    Container(
                      width: 1,
                      height: 16,
                      color: AppColors.border,
                    ),
                    _buildMetricItem(
                      icon: Icons.access_time_rounded,
                      label: onlineTime,
                    ),
                    Container(
                      width: 1,
                      height: 16,
                      color: AppColors.border,
                    ),
                    _buildMetricItem(
                      icon: Icons.local_gas_station_rounded,
                      label: 'Moto OK',
                      iconColor: AppColors.primaryNeon,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    Color iconColor = AppColors.textSecondary,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
