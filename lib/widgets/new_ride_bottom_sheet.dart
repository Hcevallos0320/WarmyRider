import 'dart:async';
import 'package:flutter/material.dart';
import '../models/ride_request_model.dart';
import '../theme/app_colors.dart';

/// Bottom Sheet modal que alerta al conductor sobre un nuevo pedido de viaje.
/// Ocupa aproximadamente la mitad de la pantalla y presenta botones sobredimensionados.
class NewRideBottomSheet extends StatefulWidget {
  final RideRequestModel rideRequest;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final int timeoutSeconds;

  const NewRideBottomSheet({
    super.key,
    required this.rideRequest,
    required this.onAccept,
    required this.onDecline,
    this.timeoutSeconds = 15,
  });

  /// Método estático para levantar el BottomSheet cómodamente desde cualquier pantalla
  static Future<bool?> show({
    required BuildContext context,
    required RideRequestModel rideRequest,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => NewRideBottomSheet(
        rideRequest: rideRequest,
        onAccept: () {
          Navigator.of(ctx).pop(true);
          onAccept();
        },
        onDecline: () {
          Navigator.of(ctx).pop(false);
          onDecline();
        },
      ),
    );
  }

  @override
  State<NewRideBottomSheet> createState() => _NewRideBottomSheetState();
}

class _NewRideBottomSheetState extends State<NewRideBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timerController;
  Timer? _countdownTimer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.timeoutSeconds;

    // Controlador para la barra de progreso del temporizador (15s fluidos a 120Hz)
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.timeoutSeconds),
    )..forward();

    // Contador por segundo
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        if (mounted) {
          widget.onDecline();
        }
      }
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      // Ocupa aproximadamente la mitad de la pantalla
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.58,
        minHeight: screenHeight * 0.48,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra superior / Tirador
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Barra de tiempo decreciente animada
              AnimatedBuilder(
                animation: _timerController,
                builder: (context, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 1.0 - _timerController.value,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _timerController.value > 0.7
                            ? AppColors.statusOffline
                            : AppColors.primaryNeon,
                      ),
                      minHeight: 5,
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Cabecera: Alerta, Ganancia y Temporizador
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.accentOrange.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_rounded,
                          size: 16,
                          color: AppColors.accentOrange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_remainingSeconds}s',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // Ganancia Estimada (Enorme para que el motorizado la vea al instante)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'GANANCIA ESTIMADA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '\$${widget.rideRequest.estimatedEarnings.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryNeon,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 12),

              // Ruta: Origen y Destino con indicador de línea continua
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Punto de Recogida
                    _buildRoutePoint(
                      icon: Icons.my_location_rounded,
                      iconColor: AppColors.primaryNeon,
                      title: 'Punto de Recogida',
                      address: widget.rideRequest.pickupAddress,
                      badge: 'A 4 min',
                    ),

                    // Línea vertical conectora
                    Padding(
                      padding: const EdgeInsets.only(left: 17),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 2,
                          height: 20,
                          color: AppColors.border,
                        ),
                      ),
                    ),

                    // Punto de Destino
                    _buildRoutePoint(
                      icon: Icons.location_on_rounded,
                      iconColor: AppColors.accentOrange,
                      title: 'Destino del Pasajero',
                      address: widget.rideRequest.dropoffAddress,
                      badge: '${widget.rideRequest.distanceKm} km',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Botones gigantes en fila (Rechazar vs Aceptar)
              Row(
                children: [
                  // Botón Rechazar (Contorno)
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 64, // Altura gigante para guantes
                      child: OutlinedButton(
                        onPressed: widget.onDecline,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.statusOffline,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Rechazar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.statusOffline,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Botón Aceptar Viaje (Color sólido llamativo)
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      height: 64, // Altura gigante para guantes
                      child: ElevatedButton(
                        onPressed: widget.onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNeon,
                          foregroundColor: AppColors.textOnNeon,
                          elevation: 6,
                          shadowColor: AppColors.primaryNeon.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.two_wheeler_rounded,
                              size: 26,
                              color: AppColors.textOnNeon,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Aceptar Viaje',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                                color: AppColors.textOnNeon,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutePoint({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String address,
    required String badge,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icono circular
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: iconColor.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),

        // Textos del punto
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Etiqueta de distancia o tiempo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
