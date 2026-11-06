import 'package:flutter/material.dart';
import '../models/ride_request_model.dart';
import '../theme/app_colors.dart';
import '../widgets/driver_status_button.dart';
import '../widgets/earnings_card.dart';
import '../widgets/mock_map_view.dart';
import '../widgets/new_ride_bottom_sheet.dart';
import 'auth_screen.dart';

/// Pantalla Principal del Conductor (DriverHomeScreen).
/// Estructurada en un Stack que superpone:
/// 1. Mapa Dark Mode a pantalla completa (MockMapView).
/// 2. Tarjeta superior de ganancias semi-transparente (EarningsCard).
/// 3. Botón flotante inferior gigante para alternar estado Online/Offline.
/// 4. Acceso rápido para simular solicitudes de viaje entrantes.
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  // Estado de conexión del conductor (por defecto desconectado)
  bool _isOnline = false;

  // Ganancias acumuladas del día
  double _todayEarnings = 15.50;
  int _tripsCompleted = 6;

  /// Alterna el estado entre Conectado y Desconectado
  void _toggleOnlineStatus() {
    setState(() {
      _isOnline = !_isOnline;
    });

    final snackBar = SnackBar(
      backgroundColor: _isOnline ? AppColors.surfaceElevated : AppColors.surfaceElevated,
      duration: const Duration(milliseconds: 2000),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: _isOnline ? AppColors.primaryNeon : AppColors.statusOffline,
        ),
      ),
      content: Row(
        children: [
          Icon(
            _isOnline ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
            color: _isOnline ? AppColors.primaryNeon : AppColors.statusOffline,
          ),
          const SizedBox(width: 12),
          Text(
            _isOnline
                ? '¡En línea! Buscando pasajeros en Riobamba'
                : 'Te has desconectado. No recibirás pedidos',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Despliega el Bottom Sheet simulando la entrada de un nuevo viaje
  void _simulateIncomingRide() {
    final mockRide = RideRequestModel.mockDemoRequest();

    NewRideBottomSheet.show(
      context: context,
      rideRequest: mockRide,
      onAccept: () {
        // Simulación: al aceptar el viaje se incrementan métricas
        setState(() {
          _todayEarnings += mockRide.estimatedEarnings;
          _tripsCompleted += 1;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.primaryNeon),
            ),
            content: Row(
              children: [
                const Icon(Icons.two_wheeler_rounded, color: AppColors.primaryNeon),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '¡Viaje Aceptado! Dirígete a: ${mockRide.pickupAddress}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      onDecline: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.statusOffline),
            ),
            content: const Row(
              children: [
                Icon(Icons.cancel_rounded, color: AppColors.statusOffline),
                SizedBox(width: 12),
                Text(
                  'Viaje rechazado. Sigues disponible para otros pedidos',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Capa de Fondo: Mapa de Google Maps simulado en Dark Mode
          Positioned.fill(
            child: MockMapView(
              isOnline: _isOnline,
            ),
          ),

          // 2. Capa Superior: Tarjeta de Ganancias Semi-transparente
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: EarningsCard(
                  earningsAmount: '\$ ${_todayEarnings.toStringAsFixed(2)}',
                  completedTrips: _tripsCompleted,
                  onlineTime: _isOnline ? '3h 10m' : '0h 00m',
                  onMenuTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => Container(
                        padding: const EdgeInsets.all(22),
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Ajustes del Conductor',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(Icons.two_wheeler_rounded, color: AppColors.riobambaBlue),
                                title: const Text('Mi Vehículo (Bajaj Pulsar 200)', style: TextStyle(color: Colors.white)),
                                subtitle: const Text('Placa: HA123B • Licencia Tipo A', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                              const Divider(color: AppColors.divider),
                              ListTile(
                                leading: const Icon(Icons.logout_rounded, color: AppColors.statusOffline),
                                title: const Text('Cerrar Sesión / Cambiar de Rol', style: TextStyle(color: AppColors.statusOffline, fontWeight: FontWeight.bold)),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                                    (route) => false,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 3. Botón de prueba para simular pedido entrante (Solo visible al estar en línea o para testing)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.28,
            right: 16,
            child: Material(
              color: AppColors.accentOrange,
              borderRadius: BorderRadius.circular(20),
              elevation: 6,
              shadowColor: AppColors.accentOrange.withValues(alpha: 0.5),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _simulateIncomingRide,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Simular Pedido',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Capa Inferior: Botón Gigante de Conexión
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                child: DriverStatusButton(
                  isOnline: _isOnline,
                  onToggle: _toggleOnlineStatus,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
