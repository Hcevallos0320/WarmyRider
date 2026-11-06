import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Botón flotante gigante inferior para alternar el estado del conductor.
/// Diseñado con un área táctil sobredimensionada para facilitar la pulsación incluso usando guantes.
class DriverStatusButton extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onToggle;

  const DriverStatusButton({
    super.key,
    required this.isOnline,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isOnline ? AppColors.statusOnline : AppColors.statusOffline;
    final textColor = isOnline ? AppColors.textOnNeon : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      width: double.infinity,
      height: 72, // Altura sobredimensionada para facilidad en ruta
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: isOnline ? 0.45 : 0.35),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onToggle,
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono de estado con animación de cambio de icono
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                  child: Icon(
                    isOnline
                        ? Icons.power_settings_new_rounded
                        : Icons.power_off_rounded,
                    key: ValueKey<bool>(isOnline),
                    size: 32,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 14),

                // Texto principal de estado
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline ? 'CONECTADO' : 'DESCONECTADO',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: textColor,
                      ),
                    ),
                    Text(
                      isOnline
                          ? 'Listo para recibir viajes en Riobamba'
                          : 'Toca para empezar a recibir pedidos',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Indicador visual con flecha
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.touch_app_rounded,
                    size: 20,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
