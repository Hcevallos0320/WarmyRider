import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Simula visualmente el mapa de Google Maps en Modo Oscuro (Dark Theme) para Riobamba.
/// Incluye renderizado de calles principales, punto de ubicación con pulso a 120Hz
/// y marcadores clave (ESPOCH, Terminal, etc.) mientras se integra Google Maps Platform.
class MockMapView extends StatefulWidget {
  final bool isOnline;

  const MockMapView({
    super.key,
    required this.isOnline,
  });

  @override
  State<MockMapView> createState() => _MockMapViewState();
}

class _MockMapViewState extends State<MockMapView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Controlador de animación continuo para el radar del conductor (60-120fps fluidos)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOutQuad,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo y cuadrícula de calles de Riobamba simuladas con CustomPaint
        Positioned.fill(
          child: CustomPaint(
            painter: _RiobambaMapPainter(),
          ),
        ),

        // Pin de ubicación del Conductor (Motocicleta) con efecto radar pulsante
        Center(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Anillo exterior de radar (solo visible cuando está en línea)
                  if (widget.isOnline)
                    Container(
                      width: 50 + (_pulseAnimation.value * 70),
                      height: 50 + (_pulseAnimation.value * 70),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryNeon.withValues(
                          alpha: (1 - _pulseAnimation.value) * 0.35,
                        ),
                        border: Border.all(
                          color: AppColors.primaryNeon.withValues(
                            alpha: (1 - _pulseAnimation.value) * 0.7,
                          ),
                          width: 1.5,
                        ),
                      ),
                    ),

                  // Halo interior brillante
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isOnline
                          ? AppColors.primaryNeon.withValues(alpha: 0.2)
                          : AppColors.statusOffline.withValues(alpha: 0.2),
                    ),
                  ),

                  // Marcador circular con icono de moto
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isOnline
                          ? AppColors.primaryNeon
                          : AppColors.surfaceElevated,
                      border: Border.all(
                        color: Colors.white,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isOnline
                                  ? AppColors.primaryNeon
                                  : Colors.black)
                              .withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.two_wheeler_rounded,
                      size: 26,
                      color: widget.isOnline
                          ? AppColors.textOnNeon
                          : AppColors.statusOffline,
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Etiqueta flotante con el estado del radar sobre el mapa
        Positioned(
          left: 0,
          right: 0,
          top: MediaQuery.of(context).size.height * 0.42,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isOnline
                      ? AppColors.primaryNeon.withValues(alpha: 0.3)
                      : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isOnline
                          ? AppColors.primaryNeon
                          : AppColors.statusOffline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isOnline
                        ? 'Radar activo • Zona Riobamba Norte'
                        : 'GPS en espera • Sin conexión',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Botón flotante para recientes de GPS / Centrar mapa
        Positioned(
          right: 18,
          bottom: 120,
          child: Material(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            elevation: 4,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ubicación centrada en Riobamba Centro'),
                    duration: Duration(milliseconds: 1200),
                  ),
                );
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.primaryNeon,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dibuja la cuadrícula y las arterias viales simuladas para la estética de Google Maps Dark
class _RiobambaMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fondo oscuro profundo del mapa
    final bgPaint = Paint()..color = AppColors.mapBackground;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final roadPaint = Paint()
      ..color = AppColors.mapRoad
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final arteryPaint = Paint()
      ..color = AppColors.mapMainArtery
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Trazado de calles secundarias (cuadrícula diagonal y ortogonal urbana)
    for (double y = 40; y < size.height; y += 70) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 30), roadPaint);
    }
    for (double x = 30; x < size.width; x += 80) {
      canvas.drawLine(Offset(x, 0), Offset(x - 20, size.height), roadPaint);
    }

    // Arterias principales (Simulando Av. Canónigo Ramos y Av. Daniel León Borja)
    final path1 = Path()
      ..moveTo(0, size.height * 0.3)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.38,
        size.width * 0.65,
        size.height * 0.55,
        size.width,
        size.height * 0.68,
      );
    canvas.drawPath(path1, arteryPaint);

    final path2 = Path()
      ..moveTo(size.width * 0.2, 0)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.45,
        size.width * 0.7,
        size.height * 0.65,
        size.width * 0.85,
        size.height,
      );
    canvas.drawPath(path2, arteryPaint);

    // Pintar referencias geográficas (Puntos de interés)
    _drawLandmark(
      canvas: canvas,
      center: Offset(size.width * 0.28, size.height * 0.32),
      label: 'ESPOCH',
      iconColor: AppColors.accentOrange,
    );

    _drawLandmark(
      canvas: canvas,
      center: Offset(size.width * 0.75, size.height * 0.72),
      label: 'Terminal Terrestre',
      iconColor: AppColors.primaryNeon,
    );
  }

  void _drawLandmark({
    required Canvas canvas,
    required Offset center,
    required String label,
    required Color iconColor,
  }) {
    // Halo del marcador
    final dotPaint = Paint()..color = iconColor;
    canvas.drawCircle(center, 5, dotPaint);

    // Etiqueta del lugar
    final textSpan = TextSpan(
      text: label,
      style: TextStyle(
        color: iconColor.withValues(alpha: 0.9),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.4,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - (textPainter.width / 2), center.dy + 8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
