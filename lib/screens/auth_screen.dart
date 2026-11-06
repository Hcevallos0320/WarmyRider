import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../widgets/google_auth_sheet.dart';
import 'driver_home_screen.dart';
import 'driver_kyc_screen.dart';
import 'login_screen.dart'; // Contiene el enum UserRole
import 'passenger_home_screen.dart';

/// Modos de autenticación disponibles
enum AuthMode {
  login, // Iniciar Sesión
  register, // Crear Cuenta
}

/// Pantalla Unificada de Autenticación (AuthScreen).
///
/// Implementa la arquitectura de "Identidad Riobamba" en Dark Mode:
/// - Fondo Azul Noche Profundo (#0A0F1D) con radial glow superior.
/// - Superficies Azul Pizarra Oscuro (#141C2F) con bordes translúcidos.
/// - Color dinámico reactivo:
///   * Pasajero: Rojo Carmesí Vibrante (#FF2E4C)
///   * Conductor: Azul Eléctrico Real (#2962FF)
/// - Formulario con validación mediante Form y TextFormField:
///   * Pasajero: SOLO Nombre Completo y Celular (cero fricción).
///   * Conductor: Nombre Completo, Celular y Cédula de Identidad (obligatoria).
class AuthScreen extends StatefulWidget {
  final UserRole initialRole;
  final AuthMode initialMode;

  const AuthScreen({
    super.key,
    this.initialRole = UserRole.passenger,
    this.initialMode = AuthMode.login,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Clave global para validación del formulario
  final _formKey = GlobalKey<FormState>();

  late UserRole _selectedRole;
  late AuthMode _authMode;

  // Controladores de formulario
  final _phoneController = TextEditingController(text: '991234567');
  final _pinController = TextEditingController(text: '1234');
  final _nameController = TextEditingController();
  final _cedulaController = TextEditingController();

  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _authMode = widget.initialMode;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _nameController.dispose();
    _cedulaController.dispose();
    super.dispose();
  }

  /// Color de acento según el rol activo (Rojo Carmesí o Azul Eléctrico)
  Color get _activeAccentColor {
    return _selectedRole == UserRole.passenger
        ? AppColors.riobambaRed
        : AppColors.riobambaBlue;
  }

  /// Muestra mensaje flotante en SnackBar
  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isError ? AppColors.statusOffline : _activeAccentColor,
          ),
        ),
        content: Row(
          children: [
            Icon(
              isError ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              color: isError ? AppColors.statusOffline : _activeAccentColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Procesa la acción del botón principal según el modo y rol
  void _handleSubmit() {
    // Validar formulario en modo registro
    if (_authMode == AuthMode.register) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    final isPassenger = _selectedRole == UserRole.passenger;

    if (_authMode == AuthMode.login) {
      // INICIAR SESIÓN
      if (isPassenger) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PassengerHomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
        );
      }
    } else {
      // CREAR CUENTA
      final name = _nameController.text.trim();

      if (isPassenger) {
        _showNotification('¡Cuenta de pasajero creada con éxito! Bienvenido, $name.');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PassengerHomeScreen()),
        );
      } else {
        // Conductor debe pasar por el KYC de documentos y moto
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const DriverKycScreen()),
        );
      }
    }
  }

  /// Flujo con Google OAuth
  void _handleGoogleSignIn() async {
    final selectedEmail = await GoogleAuthSheet.show(
      context: context,
      role: _selectedRole,
    );

    if (selectedEmail != null && mounted) {
      if (_selectedRole == UserRole.passenger) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PassengerHomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _activeAccentColor;
    final isPassenger = _selectedRole == UserRole.passenger;
    final isLogin = _authMode == AuthMode.login;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Resplandor superior dinámico según el rol
          Positioned(
            top: -120,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 380,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    accentColor.withValues(alpha: 0.24),
                    AppColors.background.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 2. Contenido scrolleable
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    // Ícono de moto con halo neón de la marca
                    Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 82,
                        height: 82,
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
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.two_wheeler_rounded,
                          size: 42,
                          color: accentColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Título principal de la marca
                    const Text(
                      'Riobamba Moto',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtítulo con identidad local
                    Text(
                      isPassenger
                          ? 'Viajes rápidos y económicos en dos ruedas por Riobamba'
                          : 'Genera ingresos conduciendo tu moto en la Sultana',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),

                    const SizedBox(height: 24),

                    // 1. Selector Superior de Rol: "Soy Pasajero" / "Soy Conductor"
                    _buildRoleSelector(accentColor),

                    const SizedBox(height: 16),

                    // 2. Selector de Modo: "Iniciar Sesión" / "Crear Cuenta"
                    _buildModeSelector(accentColor),

                    const SizedBox(height: 22),

                    // 3. Campos dinámicos del formulario
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: isLogin
                          ? _buildLoginForm(accentColor)
                          : _buildRegisterForm(accentColor, isPassenger),
                    ),

                    const SizedBox(height: 20),

                    // 4. Botón Principal de Acción
                    _buildSubmitButton(accentColor, isLogin, isPassenger),

                    const SizedBox(height: 20),

                    // Divisor sutil
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'O continúa con',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

                    const SizedBox(height: 18),

                    // 5. Botón Secundario con Google
                    _buildGoogleButton(),

                    const SizedBox(height: 24),

                    // Footer con identidad Riobamba
                    const Text(
                      'Hecho en Riobamba • Movilidad Segura y Rápida',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Selector de rol con animación suave
  Widget _buildRoleSelector(Color accentColor) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildRoleTabItem(
              role: UserRole.passenger,
              label: 'Soy Pasajero',
              icon: Icons.person_rounded,
              color: AppColors.riobambaRed,
            ),
          ),
          Expanded(
            child: _buildRoleTabItem(
              role: UserRole.driver,
              label: 'Soy Conductor',
              icon: Icons.sports_motorsports_rounded,
              color: AppColors.riobambaBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTabItem({
    required UserRole role,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
          // Limpiar validaciones previas al cambiar de rol
          _formKey.currentState?.reset();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.textSecondary),
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

  /// Selector de Modo: Iniciar Sesión vs Crear Cuenta
  Widget _buildModeSelector(Color accentColor) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _authMode = AuthMode.login;
                  _formKey.currentState?.reset();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _authMode == AuthMode.login ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: _authMode == AuthMode.login
                      ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _authMode == AuthMode.login ? FontWeight.w800 : FontWeight.w500,
                      color: _authMode == AuthMode.login ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _authMode = AuthMode.register;
                  _formKey.currentState?.reset();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _authMode == AuthMode.register ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: _authMode == AuthMode.register
                      ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Crear Cuenta',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _authMode == AuthMode.register ? FontWeight.w800 : FontWeight.w500,
                      color: _authMode == AuthMode.register ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formulario de Login: Celular + PIN
  Widget _buildLoginForm(Color accentColor) {
    return Column(
      key: const ValueKey('login_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPhoneField(accentColor),
        const SizedBox(height: 14),

        // Campo PIN / Contraseña
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PIN O CONTRASEÑA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TextFormField(
                controller: _pinController,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                cursorColor: accentColor,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingresa tu PIN';
                  }
                  if (val.trim().length < 4) {
                    return 'El PIN debe tener al menos 4 dígitos';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  ),
                  hintText: 'PIN de 4 a 6 dígitos',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  errorStyle: const TextStyle(color: AppColors.statusOffline, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Formulario de Registro con LÓGICA CONDICIONAL POR ROL:
  /// - Pasajero (Rojo): SOLO Nombre Completo y Celular. Cédula completamente oculta.
  /// - Conductor (Azul): Nombre Completo, Celular y Cédula de Identidad (obligatoria con validador).
  Widget _buildRegisterForm(Color accentColor, bool isPassenger) {
    return Column(
      key: ValueKey('register_form_${isPassenger ? 'passenger' : 'driver'}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Banner informativo exclusivo para conductores
        if (!isPassenger)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.riobambaBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.riobambaBlue.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.sports_motorsports_rounded, color: AppColors.riobambaBlue, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Para conducir necesitas registrar tu moto y documentos en el siguiente paso.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

        // 1. Campo Nombre Completo (Pasajero y Conductor)
        _buildTextField(
          controller: _nameController,
          label: 'Nombres y Apellidos Completos',
          hint: 'Ej: Carlos Moreno',
          icon: Icons.person_outline_rounded,
          accentColor: accentColor,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Por favor ingresa tus nombres y apellidos';
            }
            if (val.trim().length < 3) {
              return 'El nombre debe tener al menos 3 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // 2. Campo Cédula de Identidad (OBLIGATORIA ÚNICAMENTE PARA CONDUCTOR)
        if (!isPassenger) ...[
          _buildTextField(
            controller: _cedulaController,
            label: 'Cédula de Identidad (Obligatorio)',
            hint: '10 dígitos (Ecuador)',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            accentColor: accentColor,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'La cédula es obligatoria para conductores';
              }
              if (val.trim().length != 10) {
                return 'La cédula ecuatoriana debe tener 10 dígitos';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
        ],

        // 3. Campo Celular Ecuatoriano (+593)
        _buildPhoneField(accentColor),
      ],
    );
  }

  /// Campo telefónico ecuatoriano (+593) con TextFormField y validador
  Widget _buildPhoneField(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NÚMERO CELULAR',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🇪🇨', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    const Text('+593', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(width: 10),
                    Container(height: 22, width: 1, color: Colors.white.withValues(alpha: 0.12)),
                  ],
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  cursorColor: accentColor,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Ingresa tu número celular';
                    }
                    if (val.trim().length < 8) {
                      return 'Número celular inválido';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                    hintText: '99 123 4567',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                    errorStyle: TextStyle(color: AppColors.statusOffline, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Constructor genérico de TextFormField estilizado
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color accentColor,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            cursorColor: accentColor,
            validator: validator,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              errorStyle: const TextStyle(color: AppColors.statusOffline, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  /// Botón principal con texto dinámico y sombra neón
  Widget _buildSubmitButton(Color accentColor, bool isLogin, bool isPassenger) {
    String buttonText;
    if (isLogin) {
      buttonText = 'Ingresar';
    } else {
      buttonText = isPassenger ? 'Registrarme y Viajar' : 'Continuar al Registro de Moto';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 56,
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _handleSubmit,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  buttonText,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Botón secundario con Google
  Widget _buildGoogleButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 30),
            SizedBox(width: 8),
            Text(
              'Continuar con Google',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
