import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../theme/app_colors.dart';

/// Modal estilo Google OAuth que simula la selección de cuenta de Google.
/// Permite al usuario elegir una cuenta existente o vincular una nueva.
class GoogleAuthSheet extends StatefulWidget {
  final UserRole role;
  final ValueChanged<String> onAccountSelected;

  const GoogleAuthSheet({
    super.key,
    required this.role,
    required this.onAccountSelected,
  });

  /// Método estático auxiliar para invocar el BottomSheet desde cualquier pantalla
  static Future<String?> show({
    required BuildContext context,
    required UserRole role,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => GoogleAuthSheet(
        role: role,
        onAccountSelected: (email) {
          Navigator.of(ctx).pop(email);
        },
      ),
    );
  }

  @override
  State<GoogleAuthSheet> createState() => _GoogleAuthSheetState();
}

class _GoogleAuthSheetState extends State<GoogleAuthSheet> {
  bool _isLoading = false;
  String? _selectedEmail;

  final List<Map<String, String>> _mockAccounts = [
    {
      'name': 'Henry Desarrollador',
      'email': 'henry.riobamba@gmail.com',
      'avatar': 'H',
    },
    {
      'name': 'Usuario Riobamba Moto',
      'email': 'contacto.moto@gmail.com',
      'avatar': 'U',
    },
  ];

  void _selectAccount(String email) async {
    setState(() {
      _isLoading = true;
      _selectedEmail = email;
    });

    // Simula la latencia de verificación con los servidores de Google (800ms)
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      widget.onAccountSelected(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.role == UserRole.passenger
        ? AppColors.riobambaRed
        : AppColors.riobambaBlue;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 30,
            spreadRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tirador central superior
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Encabezado de Google con logo oficial simulado
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CustomPaint(painter: _MiniGooglePainter()),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Acceder con Google',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              'Elige una cuenta para continuar en Riobamba Moto (${widget.role == UserRole.passenger ? "Pasajero" : "Conductor"}):',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 20),

            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: accentColor,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sincronizando con $_selectedEmail...',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Lista de cuentas guardadas de Google
              ..._mockAccounts.map((account) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    onTap: () => _selectAccount(account['email']!),
                    leading: CircleAvatar(
                      backgroundColor: accentColor.withValues(alpha: 0.25),
                      child: Text(
                        account['avatar']!,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    title: Text(
                      account['name']!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      account['email']!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: AppColors.textMuted,
                    ),
                  ),
                );
              }),

              // Opción "Usar otra cuenta"
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: ListTile(
                  onTap: () => _selectAccount('nuevo.usuario@gmail.com'),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.surfaceElevated,
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Usar otra cuenta',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],

            // Aviso de privacidad oficial
            const Text(
              'Para continuar, Google compartirá tu nombre, dirección de correo electrónico y foto de perfil con Riobamba Moto. Consulta su Política de Privacidad.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dibuja el logo de Google de forma nativa sin paquetes externos
class _MiniGooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final redPaint = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.stroke..strokeWidth = 3.2;
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.stroke..strokeWidth = 3.2;
    final greenPaint = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.stroke..strokeWidth = 3.2;
    final bluePaint = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.stroke..strokeWidth = 3.2;

    final rect = Rect.fromCircle(center: center, radius: radius - 2);

    canvas.drawArc(rect, -0.75, 1.5, false, redPaint);
    canvas.drawArc(rect, 0.75, 1.4, false, yellowPaint);
    canvas.drawArc(rect, 2.15, 1.5, false, greenPaint);
    canvas.drawArc(rect, 3.65, 0.9, false, bluePaint);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius - 2, center.dy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
