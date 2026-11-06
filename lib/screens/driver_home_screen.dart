import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';
import 'auth_screen.dart';
import 'passenger_home_screen.dart';

/// Pantalla Principal del Conductor (DriverHomeScreen) en Modo Claro (Light Mode)
/// - Mapa real gratuito OpenStreetMap sin API Keys vía flutter_map.
/// - Marcador central de conductor en Azul Eléctrico (#2962FF).
/// - Cápsula Superior: Menú lateral, Switch moderno (Desconectado / Conectado) y Mini-panel de ganancias ($ 18.50).
/// - Bandeja Inferior Flotante (Bottom Tray): Solicitud de viaje entrante con ruta, oferta ($ 1.25), contraofertas ($ 1.50, $ 1.75) y botones de acción rápida.
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();

  // Ubicación del conductor en Riobamba (inicialmente zona centro/ESPOCH)
  LatLng _driverCoordinates = const LatLng(-1.6635, -78.6547);
  bool _isLocatingGps = false;

  // Estado del Conductor
  bool _isOnline = false;
  double _todayEarnings = 18.50;
  int _completedTrips = 8;

  // Viaje simulado entrante
  bool _hasIncomingRide = false;
  Timer? _rideSimulationTimer;
  double _currentOffer = 1.25;
  double? _selectedCounterOffer;

  // Puntos de la solicitud entrante
  final LatLng _pickupCoords = const LatLng(-1.6568, -78.6792); // ESPOCH
  final LatLng _dropoffCoords = const LatLng(-1.6702, -78.6433); // Terminal Terrestre

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Intentar sincronizar la posición GPS real al iniciar
    _syncGpsLocation(silently: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rideSimulationTimer?.cancel();
    super.dispose();
  }

  /// Alterna entre el estado Desconectado y Conectado
  void _toggleOnlineStatus() {
    setState(() {
      _isOnline = !_isOnline;
      if (!_isOnline) {
        _hasIncomingRide = false;
        _rideSimulationTimer?.cancel();
      }
    });

    if (_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.lightSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.riobambaBlue),
          ),
          content: const Row(
            children: [
              Icon(Icons.radar_rounded, color: AppColors.riobambaBlue),
              SizedBox(width: 10),
              Text(
                '¡Conectado! Buscando pasajeros en Riobamba...',
                style: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );

      // Simular llegada de viaje tras 1.8 segundos de estar conectado
      _rideSimulationTimer?.cancel();
      _rideSimulationTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted && _isOnline) {
          setState(() {
            _hasIncomingRide = true;
            _currentOffer = 1.25;
            _selectedCounterOffer = null;
          });
          // Ajustar mapa para visualizar la solicitud
          _mapController.move(_pickupCoords, 14.8);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.lightTextPrimary,
          duration: Duration(milliseconds: 1200),
          content: Text('Te has desconectado. No recibirás pedidos.', style: TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  /// Sincroniza la posición GPS en vivo del conductor
  Future<void> _syncGpsLocation({bool silently = false}) async {
    if (!silently) setState(() => _isLocatingGps = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!silently && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.lightTextPrimary,
              content: Text('Por favor enciende el GPS de tu dispositivo.', style: TextStyle(color: Colors.white)),
            ),
          );
        }
        if (!silently) setState(() => _isLocatingGps = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied && !silently && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.statusOffline,
              content: Text('Permiso de GPS denegado.', style: TextStyle(color: Colors.white)),
            ),
          );
          setState(() => _isLocatingGps = false);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final userGps = LatLng(position.latitude, position.longitude);

      setState(() {
        _driverCoordinates = userGps;
      });

      _mapController.move(userGps, 15.5);

      if (!silently && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.lightSurface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.riobambaBlue),
            ),
            content: const Row(
              children: [
                Icon(Icons.gps_fixed_rounded, color: AppColors.riobambaBlue),
                SizedBox(width: 10),
                Text('Ubicación del conductor actualizada', style: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }
    } catch (_) {
      // Manejo silencioso en inicialización
    } finally {
      if (!silently && mounted) {
        setState(() => _isLocatingGps = false);
      }
    }
  }

  /// Acepta el viaje y actualiza las ganancias
  void _acceptTrip() {
    final finalPrice = _selectedCounterOffer ?? _currentOffer;
    setState(() {
      _todayEarnings += finalPrice;
      _completedTrips += 1;
      _hasIncomingRide = false;
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.pickupGreen, size: 28),
            SizedBox(width: 10),
            Text('¡Viaje Aceptado!', style: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dirígete a recoger al pasajero en:', style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            const Text(
              '📍 ESPOCH (Puerta Principal)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.lightTextPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.lightSurfaceSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tarifa pactada:', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary)),
                  Text('\$${finalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.pickupGreen, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.riobambaBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Iniciar Navegación', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Rechaza el viaje actual
  void _rejectTrip() {
    setState(() {
      _hasIncomingRide = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.lightTextPrimary,
        duration: Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
        content: Text('Viaje rechazado. Sigues conectado en espera de pedidos.', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  /// Despliega el menú lateral o de ajustes del conductor
  void _openDriverMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 25, offset: Offset(0, -4)),
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
                  decoration: BoxDecoration(color: AppColors.lightBorder, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 18),

              // Cabecera del conductor
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.riobambaBlue.withValues(alpha: 0.15),
                    child: const Icon(Icons.sports_motorsports_rounded, color: AppColors.riobambaBlue, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Luis C. (Conductor)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.lightTextPrimary)),
                        SizedBox(height: 2),
                        Text('Bajaj Pulsar NS 200 • Placa: HA-123B', style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: AppColors.lightBorder),

              ListTile(
                leading: const Icon(Icons.history_rounded, color: AppColors.lightTextSecondary),
                title: const Text('Historial de Viajes Realizados', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary)),
                subtitle: Text('$_completedTrips carreras completadas hoy', style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                onTap: () => Navigator.of(ctx).pop(),
              ),

              ListTile(
                leading: const Icon(Icons.sync_alt_rounded, color: AppColors.riobambaRed),
                title: const Text('Cambiar a Modo Pasajero', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.riobambaRed)),
                subtitle: const Text('Pedir viajes como cliente en Riobamba', style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const PassengerHomeScreen()),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.statusOffline),
                title: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.statusOffline)),
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
  }

  @override
  Widget build(BuildContext context) {
    // Sombra sutil estándar Light Mode
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
          // 1. MAPA REAL CLARO DE FONDO (OpenStreetMap Estándar sin API Keys)
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _driverCoordinates,
                initialZoom: 15.0,
                minZoom: 12.0,
                maxZoom: 18.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.riobambamoto.app',
                ),

                // Si hay viaje entrante, trazar ruta entre origen y destino
                if (_hasIncomingRide) ...[
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_pickupCoords, _dropoffCoords],
                        color: AppColors.riobambaBlue,
                        strokeWidth: 4.8,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // Recogida Pasajero (ESPOCH)
                      Marker(
                        point: _pickupCoords,
                        width: 44,
                        height: 44,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.pickupGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                          ),
                          child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      // Llegada Pasajero (Terminal)
                      Marker(
                        point: _dropoffCoords,
                        width: 44,
                        height: 44,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.riobambaRed,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                          ),
                          child: const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],

                // Marcador Central del Conductor (Motocicleta Azul #2962FF en círculo blanco con sombra)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _driverCoordinates,
                      width: 56,
                      height: 56,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Halo pulsante al estar conectado
                              if (_isOnline)
                                Container(
                                  width: 42 + (_pulseController.value * 14),
                                  height: 42 + (_pulseController.value * 14),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.riobambaBlue.withValues(
                                      alpha: (1.0 - _pulseController.value) * 0.35,
                                    ),
                                  ),
                                ),
                              // Marcador circular blanco con borde azul
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _isOnline ? AppColors.riobambaBlue : AppColors.lightTextSecondary,
                                    width: 2.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.two_wheeler_rounded,
                                  color: _isOnline ? AppColors.riobambaBlue : AppColors.lightTextSecondary,
                                  size: 26,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. INTERFAZ FLOTANTE SUPERIOR (ESTADO Y GANANCIAS) - MODO CLARO
          Positioned(
            top: 0,
            left: 14,
            right: 14,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: cardShadow,
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Izquierda: Botón circular de menú
                    Material(
                      color: AppColors.lightSurfaceSubtle,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _openDriverMenu,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.lightBorder),
                          ),
                          child: const Icon(Icons.menu_rounded, color: AppColors.lightTextPrimary, size: 20),
                        ),
                      ),
                    ),

                    // Centro: Toggle grande Conectado / Desconectado
                    GestureDetector(
                      onTap: _toggleOnlineStatus,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isOnline
                              ? AppColors.riobambaBlue.withValues(alpha: 0.12)
                              : AppColors.lightSurfaceSubtle,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isOnline ? AppColors.riobambaBlue : AppColors.lightBorder,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isOnline ? AppColors.riobambaBlue : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isOnline ? 'CONECTADO' : 'DESCONECTADO',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                                color: _isOnline ? AppColors.riobambaBlue : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isOnline ? Icons.power_rounded : Icons.power_off_rounded,
                              size: 16,
                              color: _isOnline ? AppColors.riobambaBlue : AppColors.lightTextSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Derecha: Mini-panel de ganancias ($ 18.50)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.lightSurfaceSubtle,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'HOY',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.lightTextSecondary),
                          ),
                          Text(
                            '\$ ${_todayEarnings.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.pickupGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botón Flotante para centrar GPS
          Positioned(
            right: 16,
            bottom: _hasIncomingRide ? 350 : 28,
            child: Material(
              color: AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              elevation: 4,
              shadowColor: Colors.black12,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _isLocatingGps ? null : () => _syncGpsLocation(silently: false),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: _isLocatingGps
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.riobambaBlue),
                        )
                      : const Icon(Icons.my_location_rounded, color: AppColors.riobambaBlue, size: 22),
                ),
              ),
            ),
          ),

          // 3. BANDEJA DE SOLICITUDES DE VIAJE (BOTTOM SHEET FLOTANTE)
          if (_hasIncomingRide)
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 25,
                          offset: const Offset(0, -4),
                        ),
                      ],
                      border: Border.all(color: AppColors.riobambaBlue.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header de la tarjeta: Título + Distancia en tiempo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.bolt_rounded, color: AppColors.accentOrange, size: 22),
                                SizedBox(width: 6),
                                Text(
                                  '¡Nuevo viaje cerca!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.lightTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.riobambaBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'A 3 min de ti',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.riobambaBlue,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        const Divider(color: AppColors.lightBorder, height: 1),
                        const SizedBox(height: 12),

                        // Cuerpo de la tarjeta: Punto A, Punto B y notas
                        Row(
                          children: [
                            // Línea y puntos
                            Column(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(color: AppColors.pickupGreen, shape: BoxShape.circle),
                                ),
                                Container(width: 2, height: 26, color: AppColors.lightBorder),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(color: AppColors.riobambaRed, shape: BoxShape.circle),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),

                            // Textos de Recogida y Destino
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PUNTO DE RECOGIDA',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.pickupGreen),
                                  ),
                                  const Text(
                                    'ESPOCH (Puerta Principal)',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'DESTINO',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.riobambaRed),
                                  ),
                                  const Text(
                                    'Terminal Terrestre Riobamba',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Oferta Económica del Pasajero
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'OFERTA',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.lightTextSecondary),
                                ),
                                Text(
                                  '\$ ${_currentOffer.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.lightTextPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Chip de Pago del Pasajero
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.lightSurfaceSubtle,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.lightBorder),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('📱 Pago con DeUna!', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('• 2.5 km • Tarifa directa', style: TextStyle(fontSize: 11, color: AppColors.lightTextSecondary)),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Acciones Rápidas (Split-HUD): Botones de Contraoferta ($1.50 y $1.75)
                        Row(
                          children: [
                            const Text(
                              'Contraofertar:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.lightTextSecondary),
                            ),
                            const SizedBox(width: 8),
                            _buildCounterOfferChip(1.50),
                            const SizedBox(width: 6),
                            _buildCounterOfferChip(1.75),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Botones Principales de Acción: Rechazar vs Aceptar Viaje
                        Row(
                          children: [
                            // Botón Rechazar
                            Expanded(
                              flex: 4,
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: _rejectTrip,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.lightTextSecondary,
                                    side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text('Rechazar', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Botón Aceptar Viaje (Azul Eléctrico)
                            Expanded(
                              flex: 6,
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _acceptTrip,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.riobambaBlue,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: AppColors.riobambaBlue.withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        _selectedCounterOffer != null
                                            ? 'Pedir \$${_selectedCounterOffer!.toStringAsFixed(2)}'
                                            : 'Aceptar Viaje',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
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
              ),
            ),
        ],
      ),
    );
  }

  /// Chip interactivo de contraoferta
  Widget _buildCounterOfferChip(double amount) {
    final isSelected = _selectedCounterOffer == amount;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCounterOffer = isSelected ? null : amount;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.riobambaBlue : AppColors.lightSurfaceSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.riobambaBlue : AppColors.lightBorder,
          ),
        ),
        child: Text(
          '\$ ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
      ),
    );
  }
}
