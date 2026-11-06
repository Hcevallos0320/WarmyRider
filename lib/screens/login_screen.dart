import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../widgets/google_auth_sheet.dart';
import 'driver_home_screen.dart';
import 'register_screen.dart';

/// Roles disponibles para la autenticación en "Riobamba Moto".
enum UserRole {
  passenger, // Pasajero: Acento Rojo Carmesí Riobamba
  driver, // Conductor: Acento Azul Eléctrico Riobamba
}

/// Pantalla de Inicio de Sesión y Registro (LoginScreen).
/// Aplica la "Identidad Riobamba" con Dark Mode Premium y cambios dinámicos
/// según el rol seleccionado (Rojo Carmesí para Pasajero, Azul Eléctrico para Conductor).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Rol activo por defecto: Pasajero
  UserRole _selectedRole = UserRole.passenger;

  // Controlador del número telefónico ecuatoriano
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Retorna el color de acento activo según el rol seleccionado
  Color get _activeAccentColor {
    return _selectedRole == UserRole.passenger
        ? AppColors.riobambaRed
        : AppColors.riobambaBlue;
  }

  /// Maneja la acción del botón principal "Continuar"
  void _handleContinue() {
    final phone = _phoneController.text.trim();

    // Feedback al usuario y navegación contextual
    if (_selectedRole == UserRole.driver) {
      // Si es conductor, navegamos directamente a la pantalla principal del conductor
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const DriverHomeScreen(),
        ),
      );
    } else {
      // Modo pasajero: Mostramos confirmación de acceso en esta fase de UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppColors.riobambaRed, width: 1.5),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.riobambaRed),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  phone.isNotEmpty
                      ? 'Código SMS enviado a +593 $phone (Modo Pasajero)'
                      : '¡Bienvenido Pasajero a Riobamba Moto!',
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
    }
  }

  /// Maneja el inicio de sesión secundario con Google
  void _handleGoogleSignIn() async {
    final selectedEmail = await GoogleAuthSheet.show(
      context: context,
      role: _selectedRole,
    );

    if (selectedEmail != null && mounted) {
      if (_selectedRole == UserRole.driver) {
        // Acceso exitoso como Conductor
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.riobambaBlue, width: 1.5),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.riobambaBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '¡Bienvenido de vuelta! Conectado con $selectedEmail',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );

        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
        );
      } else {
        // Acceso exitoso como Pasajero
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.riobambaRed, width: 1.5),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.riobambaRed),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '¡Bienvenido a Riobamba Moto! ($selectedEmail)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _activeAccentColor;
    final isPassenger = _selectedRole == UserRole.passenger;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Fondo degradado sutil con el brillo del color de rol en la parte superior
          Positioned(
            top: -120,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              height: 380,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    accentColor.withValues(alpha: 0.22),
                    AppColors.background.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 2. Contenido principal con scroll y safe area
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // Header con Identidad: Ícono con brillo dinámico
                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.35),
                            blurRadius: 32,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.two_wheeler_rounded,
                        size: 46,
                        color: accentColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Título principal
                  const Text(
                    'Riobamba Moto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtítulo dinámico con transición suave
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      isPassenger
                          ? 'Tu viaje rápido, seguro y al mejor precio en dos ruedas.'
                          : 'Conduce en la Sultana y maximiza tus ingresos diarios.',
                      key: ValueKey<UserRole>(_selectedRole),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Selector de Rol Interactivo (Switch Pasajero / Conductor)
                  _buildRoleSelector(accentColor),

                  const SizedBox(height: 28),

                  // Input de Teléfono Ecuatoriano
                  _buildPhoneInput(accentColor),

                  const SizedBox(height: 20),

                  // Botón Principal ("Continuar")
                  _buildContinueButton(accentColor),

                  const SizedBox(height: 24),

                  // Divisor sutil "O continúa con"
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'O continúa con',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Botón Secundario ("Continuar con Google")
                  _buildGoogleButton(),

                  const SizedBox(height: 28),

                  // Enlace para ir a la pantalla de Registro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿No tienes una cuenta? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RegisterScreen(initialRole: _selectedRole),
                            ),
                          );
                        },
                        child: Text(
                          'Regístrate aquí',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Footer con identidad local y términos
                  const Text(
                    'Hecho en Riobamba • Al continuar aceptas nuestros Términos y Condiciones',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el selector de rol interactivo ("Soy Pasajero" / "Soy Conductor")
  Widget _buildRoleSelector(Color accentColor) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Pestaña Pasajero
          Expanded(
            child: _buildRoleTabItem(
              role: UserRole.passenger,
              label: 'Soy Pasajero',
              icon: Icons.person_rounded,
              isSelected: _selectedRole == UserRole.passenger,
              selectedColor: AppColors.riobambaRed,
            ),
          ),

          // Pestaña Conductor
          Expanded(
            child: _buildRoleTabItem(
              role: UserRole.driver,
              label: 'Soy Conductor',
              icon: Icons.sports_motorsports_rounded,
              isSelected: _selectedRole == UserRole.driver,
              selectedColor: AppColors.riobambaBlue,
            ),
          ),
        ],
      ),
    );
  }

  /// Elemento individual de la pestaña de rol con animación suave de 250ms
  Widget _buildRoleTabItem({
    required UserRole role,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color selectedColor,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Campo de texto para teléfono celular ecuatoriano (9 dígitos)
  Widget _buildPhoneInput(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NÚMERO CELULAR',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Prefijo Fijo Ecuatoriano: 🇪🇨 +593 con separador vertical
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🇪🇨',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '+593',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 24,
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ],
                ),
              ),

              // Campo de entrada numérica
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.2,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  cursorColor: accentColor,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                    hintText: '987 654 321',
                    hintStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Botón principal "Continuar" con altura de 56px, color de rol y resplandor neón
  Widget _buildContinueButton(Color accentColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      height: 56,
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.38),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _handleContinue,
          splashColor: Colors.white.withValues(alpha: 0.2),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continuar',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Botón secundario "Continuar con Google"
  Widget _buildGoogleButton() {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logotipo vectorial minimalista de Google
            _buildGoogleLogo(),
            const SizedBox(width: 12),
            const Text(
              'Continuar con Google',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renderiza el isotipo de cuatro colores de Google
  Widget _buildGoogleLogo() {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

/// Dibuja el logotipo emblemático de cuatro colores de Google usando Canvas nativo
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Pintar los 4 arcos de Google
    final redPaint = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.stroke..strokeWidth = 3.6;
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.stroke..strokeWidth = 3.6;
    final greenPaint = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.stroke..strokeWidth = 3.6;
    final bluePaint = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.stroke..strokeWidth = 3.6;

    final rect = Rect.fromCircle(center: center, radius: radius - 2);

    // Arcos de color
    canvas.drawArc(rect, -0.75, 1.5, false, redPaint); // Rojo superior
    canvas.drawArc(rect, 0.75, 1.4, false, yellowPaint); // Amarillo izquierdo
    canvas.drawArc(rect, 2.15, 1.5, false, greenPaint); // Verde inferior
    canvas.drawArc(rect, 3.65, 0.9, false, bluePaint); // Azul derecho

    // Barra horizontal azul central de la 'G'
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
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
