import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/supabase_constants.dart';
import 'login_screen.dart';

/// Pantalla Principal del Pasajero (PassengerHomeScreen - Split-HUD Light Mode)
///
/// Arquitectura Visual y Funcional (Réplica 100% fiel de la maqueta):
/// 1. Scaffold con Drawer lateral (Historial, Soporte, Perfil y Cerrar Sesión).
/// 2. Stack principal con mapa interactivo centrado en Riobamba (ESPOCH -> Terminal Terrestre).
/// 3. Tarjeta Superior Flotante:
///    - Botón de Menú lateral (`Icons.menu`).
///    - Foto de perfil con calificación "4.95 ⭐".
///    - Textos: "Punto de Recogida", "• ESPOCH" (Grande, bold) y "Entrada principal".
///    - Botón de GPS / Target circular verde claro con ícono verde oscuro.
/// 4. Elementos en el Mapa:
///    - Marcador de origen (ESPOCH con halo rosa/rojo).
///    - Marcador de destino (Terminal Terrestre con bandera roja).
///    - Ruta en polilínea roja carmesí siguiendo las calles de Riobamba.
///    - Píldora flotante: "🏍️ Moto a 3 min".
///    - Botón de recentrado flotante a la derecha.
/// 5. Tarjeta Inferior Flotante (Destino y Tarifa):
///    - Input de Punto de Llegada ("Terminal Terrestre" con pin rojo y lápiz de edición).
///    - Chips rápidos de acceso: 🏠 Casa, 💼 Trabajo, 🛍️ Paseo Shopping.
///    - Sección "Elige tu tarifa" con distancia/tiempo "2.4 km · 8 min".
///    - Opciones de tarifa interactivas: $1.00, ✔️ $1.25 (Activa con borde rojo), $1.50.
///    - Botón principal de ancho completo "-> Pedir Moto" con sombra roja difuminada.
class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  // Clave global para controlar el Scaffold y el Drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Controlador del mapa
  final MapController _mapController = MapController();

  // Coordenadas emblemáticas de Riobamba
  static const LatLng _espochCoords = LatLng(-1.6565, -78.6775);
  static const LatLng _terminalCoords = LatLng(-1.6702, -78.6433);
  static const LatLng _mapCenterCoords = LatLng(-1.6635, -78.6580);

  // Ruta trazada entre ESPOCH y Terminal Terrestre
  final List<LatLng> _routePoints = const [
    LatLng(-1.6565, -78.6775),
    LatLng(-1.6600, -78.6710),
    LatLng(-1.6655, -78.6650),
    LatLng(-1.6580, -78.6550),
    LatLng(-1.6640, -78.6470),
    LatLng(-1.6702, -78.6433),
  ];

  // Estado del destino y tarifa seleccionada
  String _destinationName = 'Terminal Terrestre';
  String _selectedFare = '1.25';
  bool _isRequestingRide = false;

  // Paleta de diseño oficial Rumbo
  static const Color _rumboRed = Color(0xFFFE2C55);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _textMuted = Color(0xFF9CA3AF);
  static const Color _inputBg = Color(0xFFF3F4F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Stack(
          children: [
            // 1. Capa de Fondo: Mapa Interactivo de Riobamba
            _buildMapLayer(),

            // 2. Botón flotante para recentrar mapa
            _buildRecenterButton(),

            // 3. Menú y Tarjeta Superior Flotante (Punto de Recogida)
            _buildTopHud(),

            // 4. Tarjeta Inferior Flotante (Destino, Chips Rápidos y Tarifa)
            _buildBottomHud(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. CAPA DEL MAPA (FLUTTER MAP CON RUTA Y MARCADORES REALES DE RIOBAMBA)
  // ===========================================================================

  Widget _buildMapLayer() {
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: _mapCenterCoords,
        initialZoom: 14.5,
        minZoom: 11.0,
        maxZoom: 18.0,
      ),
      children: [
        // Capa de mosaicos OpenStreetMap Light
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.riobamba.moto.warmi_rider',
        ),

        // Polilínea de ruta roja carmesí
        PolylineLayer(
          polylines: [
            Polyline(
              points: _routePoints,
              color: _rumboRed,
              strokeWidth: 4.5,
            ),
          ],
        ),

        // Marcadores en el mapa
        MarkerLayer(
          markers: [
            // Marcador de Origen: ESPOCH con halo rosa suave
            Marker(
              point: _espochCoords,
              width: 50,
              height: 50,
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _rumboRed.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: _rumboRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Píldora Flotante: "Moto a 3 min"
            Marker(
              point: const LatLng(-1.6605, -78.6660),
              width: 200,
              height: 48,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.two_wheeler_rounded,
                        color: _rumboRed,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Moto a 3 min',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Marcador de Destino: Bandera roja en Terminal Terrestre
            Marker(
              point: _terminalCoords,
              width: 180,
              height: 80,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _rumboRed,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _rumboRed.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.flag_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Terminal Terrestre',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. BOTÓN DE RECENTRADO DE MAPA FLOTANTE
  // ===========================================================================

  Widget _buildRecenterButton() {
    return Positioned(
      right: 18,
      bottom: 330, // Justo encima de la tarjeta inferior
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              HapticFeedback.lightImpact();
              _mapController.move(_mapCenterCoords, 14.5);
            },
            child: const Icon(
              Icons.my_location_rounded,
              color: _textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. MENÚ Y TARJETA SUPERIOR (PUNTO DE RECOGIDA)
  // ===========================================================================

  Widget _buildTopHud() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Botón de Menú Hamburguesa flotante
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(23),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    child: const Icon(
                      Icons.menu_rounded,
                      color: _textPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Tarjeta Superior Flotante: Perfil, ESPOCH y Target verde
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Lado Izquierdo: Foto circular y Calificación "4.95 ⭐"
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _inputBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: _inputBg, width: 2),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: _rumboRed.withValues(alpha: 0.12),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: _rumboRed,
                                    size: 22,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            '4.95 ⭐',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Centro: Textos en columna
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Punto de Recogida',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: const [
                                Icon(
                                  Icons.circle,
                                  color: _rumboRed,
                                  size: 8,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'ESPOCH',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: _textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Entrada principal',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Lado Derecho: Botón circular verde claro con ícono GPS verde oscuro
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.gps_fixed_rounded,
                          color: Color(0xFF2E7D32),
                          size: 20,
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
    );
  }

  // ===========================================================================
  // 4. TARJETA INFERIOR (DESTINO, CHIPS RÁPIDOS Y SELECCIÓN DE TARIFA)
  // ===========================================================================

  Widget _buildBottomHud() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 28,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra pequeña superior de arrastre
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              // A. Input de Destino (Punto de Llegada)
              _buildDestinationCard(),
              const SizedBox(height: 14),

              // B. Chips Rápidos (Casa, Trabajo, Paseo Shopping)
              _buildQuickChips(),
              const SizedBox(height: 18),

              // C. Sección de Tarifa (Encabezado y botones de precio)
              _buildFareSection(),
              const SizedBox(height: 20),

              // D. Botón Principal: "Pedir Moto ->"
              _buildRequestRideButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Input de Destino: Contenedor gris claro con pin rojo y lápiz
  Widget _buildDestinationCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _rumboRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.location_on_rounded,
              color: _rumboRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Punto de Llegada',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _destinationName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.edit_outlined,
              color: _textSecondary,
              size: 19,
            ),
            onPressed: _showEditDestinationModal,
          ),
        ],
      ),
    );
  }

  /// Chips Rápidos: Fila con 🏠 Casa, 💼 Trabajo, 🛍️ Paseo Shopping
  Widget _buildQuickChips() {
    final chips = [
      {'icon': Icons.home_rounded, 'label': 'Casa'},
      {'icon': Icons.work_rounded, 'label': 'Trabajo'},
      {'icon': Icons.shopping_bag_rounded, 'label': 'Paseo Shopping'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: chips.map((chip) {
          final isSelected = _destinationName == chip['label'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _destinationName = chip['label'] as String;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _rumboRed.withValues(alpha: 0.1) : _inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _rumboRed : Colors.transparent,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      chip['icon'] as IconData,
                      size: 14,
                      color: isSelected ? _rumboRed : _textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      chip['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? _rumboRed : _textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Sección de Tarifa: Encabezado con distancia/tiempo y 3 pastillas de precio
  Widget _buildFareSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Fila de título y distancia
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Elige tu tarifa',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            Text(
              '2.4 km · 8 min',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Opciones de Precio ($1.00, ✔️ $1.25, $1.50)
        Row(
          children: [
            _buildFareOption(price: '1.00', label: '\$1.00'),
            const SizedBox(width: 10),
            _buildFareOption(price: '1.25', label: '\$1.25', hasCheckmark: true),
            const SizedBox(width: 10),
            _buildFareOption(price: '1.50', label: '\$1.50'),
          ],
        ),
      ],
    );
  }

  /// Pastilla individual de precio
  Widget _buildFareOption({
    required String price,
    required String label,
    bool hasCheckmark = false,
  }) {
    final isSelected = _selectedFare == price;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedFare = price);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF1F3) : _inputBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? _rumboRed : Colors.transparent,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected && hasCheckmark) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  color: _rumboRed,
                  size: 16,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? _rumboRed : _textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Botón Principal: "Pedir Moto ->"
  Widget _buildRequestRideButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 54,
      decoration: BoxDecoration(
        color: _rumboRed,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _rumboRed.withValues(alpha: 0.38),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _isRequestingRide ? null : _handleRequestRide,
        child: _isRequestingRide
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Pedir Moto',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ===========================================================================
  // ACCIONES Y MODALES
  // ===========================================================================

  void _handleRequestRide() {
    HapticFeedback.heavyImpact();
    setState(() => _isRequestingRide = true);

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _isRequestingRide = false);

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¡Viaje solicitado por \$$_selectedFare! Buscando conductores cercanos en Riobamba...',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: _rumboRed,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    });
  }

  void _showEditDestinationModal() {
    final controller = TextEditingController(text: _destinationName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Cambiar Punto de Llegada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: _inputBg,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  icon: Icon(Icons.location_on_outlined, color: _rumboRed),
                  border: InputBorder.none,
                  hintText: 'Ingresa lugar o dirección en Riobamba',
                ),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _rumboRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  setState(() => _destinationName = text);
                }
                Navigator.pop(sheetContext);
              },
              child: const Text(
                'Guardar Destino',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotification(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? _rumboRed : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ===========================================================================
  // 5. MENÚ LATERAL (DRAWER)
  // ===========================================================================

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header de Cuenta
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: _rumboRed,
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                'H',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _rumboRed,
                ),
              ),
            ),
            accountName: const Text(
              'Henry Desarrollador',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: const Row(
              children: [
                Text('henry.riobamba@gmail.com'),
                SizedBox(width: 8),
                Text('· ⭐ 4.95'),
              ],
            ),
          ),

          // Opciones de Menú
          ListTile(
            leading: const Icon(Icons.history_rounded, color: _textPrimary),
            title: const Text('Historial de Viajes', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _textMuted),
            onTap: () {
              Navigator.pop(context);
              _showNotification('Historial de viajes en desarrollo.');
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment_rounded, color: _textPrimary),
            title: const Text('Métodos de Pago', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _textMuted),
            onTap: () {
              Navigator.pop(context);
              _showNotification('Pagos en efectivo habilitados en Riobamba.');
            },
          ),
          ListTile(
            leading: const Icon(Icons.headset_mic_rounded, color: _textPrimary),
            title: const Text('Soporte y Ayuda', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _textMuted),
            onTap: () {
              Navigator.pop(context);
              _showNotification('Centro de soporte Riobamba Moto.');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: _textPrimary),
            title: const Text('Configuración', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _textMuted),
            onTap: () {
              Navigator.pop(context);
              _showNotification('Configuraciones generales.');
            },
          ),

          const Divider(indent: 16, endIndent: 16),

          // Cerrar Sesión
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: _rumboRed),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(fontWeight: FontWeight.bold, color: _rumboRed),
            ),
            onTap: () async {
              Navigator.pop(context);
              try {
                await supabase.auth.signOut();
              } catch (_) {}

              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
