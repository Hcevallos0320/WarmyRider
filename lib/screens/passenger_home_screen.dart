import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';
import 'auth_screen.dart';
import 'driver_home_screen.dart';

/// Modelo de referencia geográfica para lugares de Riobamba
class RiobambaPlace {
  final String name;
  final String address;
  final LatLng coordinates;
  final IconData icon;

  const RiobambaPlace({
    required this.name,
    required this.address,
    required this.coordinates,
    required this.icon,
  });
}

/// Pantalla Principal del Pasajero con Arquitectura "Split-HUD" (Modo Claro)
/// - Cápsula Superior Flotante: Origen (Punto de Recogida) + Perfil Bottom-Up + SOS
/// - Consola Inferior Flotante: Destino (Punto de Llegada) + Chips Rápidos + Píldoras de Tarifa + Pedir Moto
/// - Fondo: Mapa real de OpenStreetMap (Light) con GPS y tracking de motos
class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();

  // Lugares emblemáticos de Riobamba para acceso rápido
  final List<RiobambaPlace> _riobambaPlaces = const [
    RiobambaPlace(
      name: 'Terminal Terrestre',
      address: 'Av. La Prensa y Daniel León Borja',
      coordinates: LatLng(-1.6702, -78.6433),
      icon: Icons.directions_bus_rounded,
    ),
    RiobambaPlace(
      name: 'Paseo Shopping',
      address: 'Av. Antonio José de Sucre',
      coordinates: LatLng(-1.6601, -78.6655),
      icon: Icons.shopping_bag_rounded,
    ),
    RiobambaPlace(
      name: 'UNACH',
      address: 'Av. Antonio José de Sucre (Campus Norte)',
      coordinates: LatLng(-1.6515, -78.6534),
      icon: Icons.school_rounded,
    ),
    RiobambaPlace(
      name: 'Centro',
      address: 'Parque Maldonado / Catedral de Riobamba',
      coordinates: LatLng(-1.6728, -78.6475),
      icon: Icons.account_balance_rounded,
    ),
    RiobambaPlace(
      name: 'ESPOCH',
      address: 'Panamericana Sur km 1 1/2',
      coordinates: LatLng(-1.6568, -78.6792),
      icon: Icons.school_outlined,
    ),
  ];

  // Puntos de Ruta en Riobamba (Split-HUD: Origen arriba, Destino abajo)
  LatLng _originCoordinates = const LatLng(-1.6568, -78.6792);
  String _originAddress = 'ESPOCH (Puerta Principal)';

  LatLng _destinationCoordinates = const LatLng(-1.6702, -78.6433);
  String _destinationAddress = 'Terminal Terrestre Riobamba';
  String _selectedPlaceChip = 'Terminal Terrestre';

  // Métricas del viaje
  double _distanceKm = 2.5;
  int _estimatedMinutes = 6;

  // Barra de Píldoras de Tarifa
  final List<double> _farePills = const [1.00, 1.25, 1.50, 1.75, 2.00];
  double _selectedFare = 1.25;

  // Preferencias de viaje
  String _paymentMethod = 'DeUna!'; // 'DeUna!' o 'Efectivo'
  bool _hasBackpack = true;

  // Estado del GPS y animación de radar
  bool _isLocatingGps = false;
  late final AnimationController _pulseController;

  // Motocicletas cercanas simuladas en Riobamba
  final List<LatLng> _mockDrivers = const [
    LatLng(-1.6595, -78.6730), // Cerca de ESPOCH
    LatLng(-1.6635, -78.6580), // Av. Daniel León Borja
    LatLng(-1.6680, -78.6490), // Cerca de Terminal
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _recalculateTripMetrics();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Recalcula la distancia y actualiza la tarifa sugerida
  void _recalculateTripMetrics() {
    const Distance distanceCalculator = Distance();
    final meters = distanceCalculator.as(
      LengthUnit.Meter,
      _originCoordinates,
      _destinationCoordinates,
    );

    setState(() {
      _distanceKm = double.parse((meters / 1000).toStringAsFixed(1));
      if (_distanceKm < 0.5) _distanceKm = 0.5;
      _estimatedMinutes = (_distanceKm * 2.3).round() + 1;

      // Sugerir la píldora correspondiente según distancia
      if (_distanceKm <= 1.5) {
        _selectedFare = 1.00;
      } else if (_distanceKm <= 3.0) {
        _selectedFare = 1.25;
      } else if (_distanceKm <= 4.5) {
        _selectedFare = 1.50;
      } else if (_distanceKm <= 6.0) {
        _selectedFare = 1.75;
      } else {
        _selectedFare = 2.00;
      }
    });
  }

  /// Selecciona un destino rápido desde los chips inferiores
  void _selectQuickDestination(RiobambaPlace place) {
    setState(() {
      _selectedPlaceChip = place.name;
      _destinationAddress = '${place.name} (${place.address})';
      _destinationCoordinates = place.coordinates;
    });

    _recalculateTripMetrics();
    _mapController.move(place.coordinates, 15.0);
  }

  /// Obtiene la ubicación GPS en vivo del dispositivo y reposiciona el mapa
  Future<void> _getCurrentGpsLocation() async {
    setState(() => _isLocatingGps = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.lightTextPrimary,
              content: Text('Por favor enciende el GPS de tu dispositivo.', style: TextStyle(color: Colors.white)),
            ),
          );
        }
        setState(() => _isLocatingGps = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppColors.statusOffline,
                content: Text('Permiso de GPS denegado.', style: TextStyle(color: Colors.white)),
              ),
            );
          }
          setState(() => _isLocatingGps = false);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final userGps = LatLng(position.latitude, position.longitude);

      setState(() {
        _originCoordinates = userGps;
        _originAddress = 'Mi Ubicación Actual (GPS en vivo)';
      });

      _recalculateTripMetrics();
      _mapController.move(userGps, 16.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.lightSurface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.pickupGreen),
            ),
            content: const Row(
              children: [
                Icon(Icons.gps_fixed_rounded, color: AppColors.pickupGreen),
                SizedBox(width: 10),
                Text('Ubicación GPS sincronizada en Riobamba', style: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.lightTextPrimary,
            content: Text('No se pudo obtener el GPS: $e', style: const TextStyle(color: Colors.white)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocatingGps = false);
      }
    }
  }

  /// Despliega el Perfil del Pasajero desde abajo hacia arriba (Bottom-Up Profile Sheet)
  void _openProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PassengerProfileSheet(
        onSwitchToDriver: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
          );
        },
      ),
    );
  }

  /// Despliega el selector modal para cambiar punto de recogida o destino
  void _openLocationPickerSheet({required bool isOrigin}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LocationPickerSheet(
        isOrigin: isOrigin,
        currentAddress: isOrigin ? _originAddress : _destinationAddress,
        places: _riobambaPlaces,
        onPlaceSelected: (name, address, coords) {
          setState(() {
            if (isOrigin) {
              _originAddress = '$name ($address)';
              _originCoordinates = coords;
            } else {
              _destinationAddress = '$name ($address)';
              _destinationCoordinates = coords;
              _selectedPlaceChip = name;
            }
          });
          _recalculateTripMetrics();
          _mapController.move(coords, 15.5);
          Navigator.of(ctx).pop();
        },
        onUseGps: () async {
          Navigator.of(ctx).pop();
          await _getCurrentGpsLocation();
        },
      ),
    );
  }

  /// Modal de Asistencia SOS
  void _openSosModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.shield_rounded, color: AppColors.riobambaRed, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Centro de Seguridad y SOS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu viaje en Riobamba está monitoreado. En caso de emergencia usa estas opciones:',
                style: TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 18),

              ListTile(
                tileColor: AppColors.lightSurfaceSubtle,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.share_location_rounded, color: Color(0xFF25D366)),
                ),
                title: const Text('Compartir mi ruta por WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary)),
                subtitle: const Text('Envía tu ubicación y placa a un contacto', style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.lightTextPrimary,
                      content: Text('Enlace de seguridad copiado al portapapeles.', style: TextStyle(color: Colors.white)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              ListTile(
                tileColor: AppColors.statusOffline.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.statusOffline.withValues(alpha: 0.3)),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.statusOffline.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.emergency_rounded, color: AppColors.statusOffline),
                ),
                title: const Text('Llamar al ECU 911 Riobamba', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.statusOffline)),
                subtitle: const Text('Respuesta inmediata de policía y ambulancia', style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.statusOffline,
                      content: Text('Simulando llamada con ECU 911 Riobamba...', style: TextStyle(color: Colors.white)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Diálogo para cerrar sesión
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Cerrar Sesión?', style: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold)),
        content: const Text(
          'Volverás a la pantalla de autenticación para cambiar de cuenta o rol.',
          style: TextStyle(color: AppColors.lightTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.lightTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.riobambaRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthScreen()),
                (route) => false,
              );
            },
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Dispara la búsqueda de la moto
  void _requestRide() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PassengerRideSearchingSheet(
        pickupAddress: _originAddress,
        dropoffAddress: _destinationAddress,
        fare: _selectedFare,
        paymentMethod: _paymentMethod,
        hasBackpack: _hasBackpack,
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sombra sutil estándar de Light Mode
    final cardShadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Stack(
        children: [
          // 1. MAPA REAL CLARO DE FONDO (OpenStreetMap Estándar)
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(-1.6635, -78.6547),
                initialZoom: 14.8,
                minZoom: 12.0,
                maxZoom: 18.5,
              ),
              children: [
                // Capa Clara OpenStreetMap
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.riobambamoto.app',
                ),

                // Línea de Ruta Roja (#FF2E4C)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_originCoordinates, _destinationCoordinates],
                      color: AppColors.riobambaRed,
                      strokeWidth: 4.8,
                    ),
                  ],
                ),

                // Capa de Marcadores (Origen, Destino y Motos cercanas)
                MarkerLayer(
                  markers: [
                    // Marcador Verde Origen (Con halo pulsante)
                    Marker(
                      point: _originCoordinates,
                      width: 50,
                      height: 50,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 26 + (_pulseController.value * 20),
                                height: 26 + (_pulseController.value * 20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.pickupGreen.withValues(
                                    alpha: (1.0 - _pulseController.value) * 0.45,
                                  ),
                                ),
                              ),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: AppColors.pickupGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 6),
                                  ],
                                ),
                                child: const Icon(Icons.person_pin_circle_rounded, size: 14, color: Colors.white),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Marcador Rojo Destino
                    Marker(
                      point: _destinationCoordinates,
                      width: 44,
                      height: 44,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.riobambaRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 8),
                          ],
                        ),
                        child: const Icon(Icons.flag_rounded, color: Colors.white, size: 18),
                      ),
                    ),

                    // Motos cercanas simuladas
                    ..._mockDrivers.map(
                      (driverPos) => Marker(
                        point: driverPos,
                        width: 38,
                        height: 38,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.riobambaRed, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 6),
                            ],
                          ),
                          child: const Icon(
                            Icons.two_wheeler_rounded,
                            color: AppColors.riobambaRed,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. PARTE SUPERIOR: CÁPSULA FLOTANTE (ORIGEN Y PERFIL) - MODO CLARO
          Positioned(
            top: 0,
            left: 14,
            right: 14,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: cardShadow,
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fila Superior: Perfil a la izquierda y Botones SOS / Salir a la derecha
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Botón de Perfil del Usuario (Abre Bottom Sheet)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _openProfileBottomSheet,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                              decoration: BoxDecoration(
                                color: AppColors.lightSurfaceSubtle,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.lightBorder),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: AppColors.riobambaRed,
                                    child: Text('H', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                                  ),
                                  SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Henry C.',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.lightTextPrimary),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                                          SizedBox(width: 2),
                                          Text(
                                            '4.95',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.lightTextSecondary, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Acciones: SOS y Salir
                        Row(
                          children: [
                            Material(
                              color: AppColors.lightSurfaceSubtle,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: _openSosModal,
                                child: Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.riobambaRed.withValues(alpha: 0.2)),
                                  ),
                                  child: const Icon(Icons.shield_rounded, color: AppColors.riobambaRed, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: AppColors.lightSurfaceSubtle,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: _handleLogout,
                                child: Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.lightBorder),
                                  ),
                                  child: const Icon(Icons.logout_rounded, color: AppColors.lightTextSecondary, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Fila Inferior (Dentro de la misma tarjeta): Selector de Punto de Recogida y Botón GPS
                    Material(
                      color: AppColors.lightSurfaceSubtle,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _openLocationPickerSheet(isOrigin: true),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: AppColors.pickupGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'PUNTO DE RECOGIDA',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.pickupGreen,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      _originAddress,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Botón de centrado GPS en Azul Eléctrico
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _isLocatingGps ? null : _getCurrentGpsLocation,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: AppColors.riobambaBlue.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _isLocatingGps
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.riobambaBlue),
                                          )
                                        : const Icon(Icons.my_location_rounded, color: AppColors.riobambaBlue, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. PARTE INFERIOR: CONSOLA FLOTANTE (DESTINO Y VIAJE) - MODO CLARO
          Positioned(
            bottom: 0,
            left: 14,
            right: 14,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: cardShadow,
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Caja de Punto de Llegada (Destino)
                      Material(
                        color: AppColors.lightSurfaceSubtle,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _openLocationPickerSheet(isOrigin: false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.riobambaRed.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppColors.riobambaRed.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.location_on_rounded, color: AppColors.riobambaRed, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'DESTINO DEL VIAJE',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.riobambaRed,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        _destinationAddress,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.lightTextPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.search_rounded, color: AppColors.lightTextSecondary, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Chips Rápidos de Riobamba (Scroll Horizontal)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: _riobambaPlaces.map((place) {
                            final isSelected = _selectedPlaceChip == place.name;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                avatar: Icon(
                                  place.icon,
                                  size: 15,
                                  color: isSelected ? AppColors.riobambaRed : AppColors.lightTextSecondary,
                                ),
                                label: Text(place.name),
                                selected: isSelected,
                                selectedColor: AppColors.riobambaRed.withValues(alpha: 0.12),
                                backgroundColor: AppColors.lightSurfaceSubtle,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? AppColors.riobambaRed : AppColors.lightTextSecondary,
                                ),
                                side: BorderSide(
                                  color: isSelected ? AppColors.riobambaRed : AppColors.lightBorder,
                                ),
                                onSelected: (_) => _selectQuickDestination(place),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 12),
                      const Divider(color: AppColors.lightBorder, height: 1),
                      const SizedBox(height: 10),

                      // Selector de Tarifa (Píldoras)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'OFERTA DE TARIFA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.lightTextSecondary,
                              letterSpacing: 0.6,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.lightSurfaceSubtle,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_distanceKm km • ~$_estimatedMinutes min',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.pickupGreen),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Fila de Píldoras de Tarifa
                      Row(
                        children: _farePills.map((fare) {
                          final isSelected = _selectedFare == fare;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedFare = fare),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.riobambaRed : AppColors.lightSurfaceSubtle,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? AppColors.riobambaRed : AppColors.lightBorder,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.riobambaRed.withValues(alpha: 0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '\$${fare.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                        color: isSelected ? Colors.white : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 12),

                      // Etiquetas de Viaje Rápidas (Pago + Mochila)
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _paymentMethod = _paymentMethod == 'DeUna!' ? 'Efectivo' : 'DeUna!';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.lightSurfaceSubtle,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.lightBorder),
                              ),
                              child: Text(
                                _paymentMethod == 'DeUna!' ? '📱 Pago con DeUna!' : '💵 Efectivo',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          GestureDetector(
                            onTap: () {
                              setState(() => _hasBackpack = !_hasBackpack);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _hasBackpack ? AppColors.riobambaRed.withValues(alpha: 0.1) : AppColors.lightSurfaceSubtle,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _hasBackpack ? AppColors.riobambaRed : AppColors.lightBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.backpack_rounded,
                                    size: 14,
                                    color: _hasBackpack ? AppColors.riobambaRed : AppColors.lightTextSecondary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '🎒 Llevo mochila',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _hasBackpack ? AppColors.riobambaRed : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Botón de Acción Principal en Rojo Carmesí
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _requestRide,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.riobambaRed,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: AppColors.riobambaRed.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                'Pedir Moto • \$${_selectedFare.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hoja modal del Perfil del Pasajero desplegable de abajo hacia arriba (Bottom-Up Profile Sheet) - Modo Claro
class _PassengerProfileSheet extends StatelessWidget {
  final VoidCallback onSwitchToDriver;

  const _PassengerProfileSheet({required this.onSwitchToDriver});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
      decoration: const BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 25, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Tarjeta de Identidad del Pasajero
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.riobambaRed, width: 2.2),
                        color: AppColors.lightSurfaceSubtle,
                      ),
                      child: const Center(
                        child: Text(
                          'H',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: AppColors.riobambaRed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Henry C.',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.lightTextPrimary),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.verified_rounded, size: 18, color: AppColors.pickupGreen),
                        ],
                      ),
                      SizedBox(height: 3),
                      Text(
                        '+593 99 123 4567 • Riobamba',
                        style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Estadísticas en 3 columnas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.lightSurfaceSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('PUNTUACIÓN', '4.95 ⭐', Colors.amber),
                  Container(width: 1, height: 28, color: AppColors.lightBorder),
                  _buildStatItem('VIAJES', '32', AppColors.lightTextPrimary),
                  Container(width: 1, height: 28, color: AppColors.lightBorder),
                  _buildStatItem('NIVEL', 'Pionero', AppColors.pickupGreen),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Opciones de Configuración
            _buildOptionTile(
              icon: Icons.payments_rounded,
              title: 'Método de Pago Predeterminado',
              subtitle: 'DeUna! / Banco Pichincha',
            ),
            const SizedBox(height: 8),

            _buildOptionTile(
              icon: Icons.bookmark_added_rounded,
              title: 'Direcciones Guardadas',
              subtitle: 'Casa, ESPOCH, Trabajo',
            ),
            const SizedBox(height: 8),

            _buildOptionTile(
              icon: Icons.history_rounded,
              title: 'Historial de Carreras',
              subtitle: '32 viajes en Riobamba',
            ),

            const Spacer(),

            // Botón Especial de Cambio de Rol en Azul Eléctrico (#2962FF)
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: onSwitchToDriver,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.riobambaBlue,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.riobambaBlue.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sports_motorsports_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Cambiar a Modo Conductor 🏍️',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.lightTextSecondary, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: valueColor),
        ),
      ],
    );
  }

  Widget _buildOptionTile({required IconData icon, required String title, required String subtitle}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: AppColors.lightTextSecondary, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.lightTextSecondary, size: 13),
      ),
    );
  }
}

/// Hoja modal de búsqueda para cambiar punto de recogida o destino (Modo Claro)
class _LocationPickerSheet extends StatefulWidget {
  final bool isOrigin;
  final String currentAddress;
  final List<RiobambaPlace> places;
  final Function(String name, String address, LatLng coords) onPlaceSelected;
  final VoidCallback onUseGps;

  const _LocationPickerSheet({
    required this.isOrigin,
    required this.currentAddress,
    required this.places,
    required this.onPlaceSelected,
    required this.onUseGps,
  });

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<RiobambaPlace> _filteredPlaces;

  @override
  void initState() {
    super.initState();
    _filteredPlaces = widget.places;
    _searchController.addListener(_filter);
  }

  void _filter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredPlaces = widget.places;
      } else {
        _filteredPlaces = widget.places.where((p) {
          return p.name.toLowerCase().contains(query) || p.address.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isOrigin ? AppColors.pickupGreen : AppColors.riobambaRed;
    final query = _searchController.text.trim();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40, height: 5, decoration: BoxDecoration(color: AppColors.lightBorder, borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Icon(widget.isOrigin ? Icons.my_location_rounded : Icons.location_on_rounded, color: accentColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  widget.isOrigin ? 'PUNTO DE RECOGIDA' : 'PUNTO DE DESTINO',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accentColor),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Buscador
            Container(
              decoration: BoxDecoration(
                color: AppColors.lightSurfaceSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
                cursorColor: accentColor,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  prefixIcon: Icon(Icons.search_rounded, color: accentColor, size: 22),
                  hintText: widget.isOrigin ? 'Buscar recogida en Riobamba...' : 'Buscar destino en Riobamba...',
                  hintStyle: const TextStyle(color: AppColors.lightTextSecondary, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Usar GPS
            ListTile(
              tileColor: AppColors.lightSurfaceSubtle,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.gps_fixed_rounded, color: AppColors.pickupGreen, size: 20),
              title: const Text('Usar mi ubicación GPS actual', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.lightTextSecondary, size: 13),
              onTap: widget.onUseGps,
            ),
            const SizedBox(height: 10),

            if (query.isNotEmpty) ...[
              ListTile(
                tileColor: accentColor.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(Icons.pin_drop_rounded, color: accentColor, size: 20),
                title: Text('Establecer "$query" en Riobamba', style: TextStyle(fontWeight: FontWeight.bold, color: accentColor)),
                onTap: () => widget.onPlaceSelected(query, 'Ubicación personalizada', const LatLng(-1.6660, -78.6560)),
              ),
              const SizedBox(height: 10),
            ],

            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: _filteredPlaces.length,
                separatorBuilder: (context, index) => const Divider(color: AppColors.lightBorder, height: 1),
                itemBuilder: (context, index) {
                  final place = _filteredPlaces[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    leading: Icon(place.icon, color: AppColors.lightTextPrimary, size: 20),
                    title: Text(place.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary)),
                    subtitle: Text(place.address, style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                    onTap: () => widget.onPlaceSelected(place.name, place.address, place.coordinates),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hoja modal de búsqueda con radar y asignación del motorizado (Modo Claro)
class _PassengerRideSearchingSheet extends StatefulWidget {
  final String pickupAddress;
  final String dropoffAddress;
  final double fare;
  final String paymentMethod;
  final bool hasBackpack;
  final VoidCallback onCancel;

  const _PassengerRideSearchingSheet({
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.fare,
    required this.paymentMethod,
    required this.hasBackpack,
    required this.onCancel,
  });

  @override
  State<_PassengerRideSearchingSheet> createState() => _PassengerRideSearchingSheetState();
}

class _PassengerRideSearchingSheetState extends State<_PassengerRideSearchingSheet> {
  bool _driverFound = false;
  Timer? _matchingTimer;

  @override
  void initState() {
    super.initState();
    _matchingTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _driverFound = true);
    });
  }

  @override
  void dispose() {
    _matchingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 25, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40, height: 5, decoration: BoxDecoration(color: AppColors.lightBorder, borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 18),

            if (!_driverFound) ...[
              const Center(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(color: AppColors.riobambaRed, strokeWidth: 3.5),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Buscando el motorizado más cercano...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Oferta: \$${widget.fare.toStringAsFixed(2)} • Pago: ${widget.paymentMethod}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: widget.onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusOffline,
                  side: const BorderSide(color: AppColors.statusOffline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Cancelar Búsqueda', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.pickupGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.pickupGreen.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.pickupGreen, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('¡Motorizado Confirmado!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.lightTextPrimary)),
                          Text('Luis C. viene en su Bajaj Pulsar 200 • Casco limpio', style: TextStyle(fontSize: 13, color: AppColors.lightTextSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.lightSurfaceSubtle,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.riobambaBlue,
                          child: Icon(Icons.sports_motorsports_rounded, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Luis C. (★ 4.9)', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary)),
                            Text('Placa: HA-123B', style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                          ],
                        ),
                      ],
                    ),
                    Text('\$${widget.fare.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.pickupGreen)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: widget.onCancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pickupGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Entendido, esperando en el punto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
