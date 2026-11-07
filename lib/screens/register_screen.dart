import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import 'driver_home_screen.dart';
import 'login_screen.dart'; // Contiene enum UserRole
import 'passenger_home_screen.dart';

/// Pantalla de Registro de Nuevos Usuarios (RegisterScreen - Estilo "Rumbo")
///
/// Soporta dos estados dinámicos completos:
/// 1. Modo Pasajero (Rojo Carmesí #FE2C55):
///    - Botón "Soy Pasajero" activo
///    - Acento "A tu ritmo." en rojo
///    - Subtítulo: "Muévete en moto por Riobamba."
///    - Formulario base (Nombre, Correo, Celular, Contraseña)
///    - Botón: "Crear cuenta de Pasajero ->"
///    - Enlace inferior en rojo
///
/// 2. Modo Conductor (Azul Eléctrico #2962FF):
///    - Botón "Soy Conductor" activo en azul
///    - Acento "A tu ritmo." en azul
///    - Subtítulo: "Conduce en Riobamba. Tú eliges el ritmo."
///    - Formulario ampliado con campo animado de "Cédula de Identidad"
///    - Botón: "Crear cuenta de Conductor ->"
///    - Enlace inferior en azul
class RegisterScreen extends StatefulWidget {
  final UserRole initialRole;

  const RegisterScreen({
    super.key,
    this.initialRole = UserRole.passenger,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1. MANEJO DE ESTADO DINÁMICO
  bool isPassenger = true;

  // Controladores de campos del formulario
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _passwordController = TextEditingController();

  // Estados interactivos
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Paleta de colores oficial de la maqueta Rumbo
  static const Color _bgCanvas = Color(0xFFFAFAFA);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _inputBg = Color(0xFFF3F4F6);
  static const Color _rumboRed = Color(0xFFFE2C55);
  static const Color _rumboBlue = Color(0xFF2962FF);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _textMuted = Color(0xFF9CA3AF);

  // Color de acento reactivo al estado
  Color get _activeColor => isPassenger ? _rumboRed : _rumboBlue;

  @override
  void initState() {
    super.initState();
    isPassenger = widget.initialRole == UserRole.passenger;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cedulaController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // LÓGICA DE REGISTRO EN SUPABASE POSTGRESQL
  // ===========================================================================

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final roleString = isPassenger ? 'pasajero' : 'conductor';
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final cedula = isPassenger ? null : _cedulaController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // 1. Registro del usuario en Supabase Auth
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'phone': phone,
          'role': roleString,
        },
      );

      final user = res.user;
      if (user == null) {
        throw const AuthException('No se pudo completar el registro del usuario.');
      }

      // 2. Inserción relacional en la tabla `public.perfiles` de PostgreSQL
      await supabase.from('perfiles').upsert({
        'id': user.id,
        'rol': roleString,
        'nombre_completo': name,
        'celular': phone,
        'correo': email,
        'cedula': cedula,
        'calificacion': 5.0,
        'fecha_registro': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      _showNotification(
        '¡Cuenta creada con éxito! Bienvenido a rumbo, $name.',
        color: _activeColor,
      );

      // 3. Redirección contextual según el rol registrado
      if (isPassenger) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const PassengerHomeScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      _showNotification(e.message, isError: true);
    } catch (e) {
      _showNotification('Error inesperado al registrar cuenta: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNotification(String message, {bool isError = false, Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? _rumboRed : (color ?? const Color(0xFF10B981)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ===========================================================================
  // INTERFAZ DE USUARIO: PIXEL-PERFECT REACTIVA
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCanvas,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header (Logo rumbo a la izquierda, Pin RIOBAMBA, EC a la derecha)
                _buildHeader(),
                const SizedBox(height: 20),

                // 2. Toggle de Roles Dinámico (Pasajero vs Conductor)
                _buildRoleToggle(),
                const SizedBox(height: 24),

                // 3. Hero Texts Reactivos
                _buildHeroText(),
                const SizedBox(height: 24),

                // 4. Tarjeta Flotante Blanca con Formulario Inteligente
                _buildFormCard(),
                const SizedBox(height: 24),

                // 5. Footer "¿Ya tienes cuenta? Inicia sesión."
                _buildFooter(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 1. Header: Cuadro rojo con flecha de navegación + "rumbo" a la izquierda, Pin y "RIOBAMBA, EC" a la derecha
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Isotipo oficial rumbo
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _rumboRed,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _rumboRed.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.near_me_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'rumbo',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: _textPrimary,
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),

        // Insignia Ciudad "RIOBAMBA, EC"
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.location_on_outlined,
              size: 15,
              color: _textSecondary,
            ),
            SizedBox(width: 4),
            Text(
              'RIOBAMBA, EC',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 2. Toggle de Roles Dinámico:
  /// - Si `isPassenger == true`: "Soy Pasajero" se ilumina en Rojo Carmesí (#FE2C55).
  /// - Si `isPassenger == false`: "Soy Conductor" se ilumina en Azul Eléctrico (#2962FF).
  Widget _buildRoleToggle() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          // Píldora: Soy Pasajero
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isPassenger) {
                  HapticFeedback.lightImpact();
                  setState(() => isPassenger = true);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isPassenger ? _rumboRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: isPassenger
                      ? [
                          BoxShadow(
                            color: _rumboRed.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Soy Pasajero',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isPassenger ? FontWeight.bold : FontWeight.w600,
                    color: isPassenger ? Colors.white : _textSecondary,
                  ),
                ),
              ),
            ),
          ),

          // Píldora: Soy Conductor
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isPassenger) {
                  HapticFeedback.lightImpact();
                  setState(() => isPassenger = false);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: !isPassenger ? _rumboBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: !isPassenger
                      ? [
                          BoxShadow(
                            color: _rumboBlue.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Soy Conductor',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: !isPassenger ? FontWeight.bold : FontWeight.w600,
                    color: !isPassenger ? Colors.white : _textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Hero Texts Reactivos:
  /// - Título secundario: Pasa de rojo (#FE2C55) a azul (#2962FF).
  /// - Subtítulo: "Muévete en moto por Riobamba." vs "Conduce en Riobamba. Tú eliges el ritmo."
  Widget _buildHeroText() {
    final subtitle = isPassenger
        ? 'Muévete en moto por Riobamba.'
        : 'Conduce en Riobamba. Tú eliges el ritmo.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tu ciudad.',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: _textPrimary,
            height: 1.1,
            letterSpacing: -0.8,
          ),
        ),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: _activeColor,
            height: 1.1,
            letterSpacing: -0.8,
            fontFamily: 'Inter',
          ),
          child: const Text('A tu ritmo.'),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            subtitle,
            key: ValueKey<bool>(isPassenger),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _textSecondary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  /// 4. Tarjeta Flotante Blanca con Formulario Inteligente
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo 1: Nombre Completo (Siempre visible)
            _buildInputField(
              controller: _nameController,
              label: 'Nombre Completo',
              hint: 'Tu nombre completo',
              icon: Icons.person_outline_rounded,
              keyboardType: TextInputType.name,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Ingresa tu nombre completo';
                }
                if (val.trim().length < 3) {
                  return 'El nombre debe tener al menos 3 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Campo 2: Correo electrónico (Siempre visible)
            _buildInputField(
              controller: _emailController,
              label: 'Correo electrónico',
              hint: 'hola@ejemplo.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Ingresa tu correo electrónico';
                }
                if (!val.contains('@') || !val.contains('.')) {
                  return 'Correo electrónico no válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Campo 3: Celular (+593) (Siempre visible)
            _buildInputField(
              controller: _phoneController,
              label: 'Celular (+593)',
              hint: '099 123 4567',
              icon: Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Ingresa tu número celular';
                }
                final cleanPhone = val.replaceAll(RegExp(r'\D'), '');
                if (cleanPhone.length < 9) {
                  return 'Número celular inválido (mínimo 9 dígitos)';
                }
                return null;
              },
            ),

            // Campo 4: Cédula de Identidad (Animado: SOLO visible en modo Conductor)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: !isPassenger
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),
                        _buildInputField(
                          controller: _cedulaController,
                          label: 'Cédula de Identidad',
                          hint: '0601234567',
                          icon: Icons.badge_outlined,
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (!isPassenger) {
                              if (val == null || val.trim().isEmpty) {
                                return 'La cédula es obligatoria para conductores';
                              }
                              if (val.trim().length != 10) {
                                return 'Debe tener exactamente 10 dígitos';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),

            // Campo 5: Contraseña (Siempre visible)
            _buildInputField(
              controller: _passwordController,
              label: 'Contraseña',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: !_isPasswordVisible,
              suffixIcon: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _textSecondary,
                  size: 20,
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Ingresa una contraseña';
                }
                if (val.length < 6) {
                  return 'Mínimo 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Botón Principal Reactivo (Rojo o Azul según rol)
            _buildPrimaryButton(),
          ],
        ),
      ),
    );
  }

  /// Campo de Texto Base (#F3F4F6, radius 12, InputBorder.none, microetiqueta superior)
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: _textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: _textMuted,
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                  validator: validator,
                ),
              ],
            ),
          ),
          ?suffixIcon,
        ],
      ),
    );
  }

  /// Botón Principal Reactivo:
  /// - Si `isPassenger == true`: Fondo Rojo Carmesí (#FE2C55), texto "Crear cuenta de Pasajero ->"
  /// - Si `isPassenger == false`: Fondo Azul Eléctrico (#2962FF), texto "Crear cuenta de Conductor ->"
  Widget _buildPrimaryButton() {
    final buttonText = isPassenger
        ? 'Crear cuenta de Pasajero'
        : 'Crear cuenta de Conductor';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 54,
      decoration: BoxDecoration(
        color: _activeColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _activeColor.withValues(alpha: 0.38),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _isLoading ? null : _handleRegister,
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ],
              ),
      ),
    );
  }

  /// 5. Footer Inferior:
  /// "¿Ya tienes cuenta? Inicia sesión."
  /// El texto interactivo "Inicia sesión." cambia dinámicamente a Rojo o Azul según el estado.
  Widget _buildFooter() {
    return Center(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
              children: [
                const TextSpan(text: '¿Ya tienes cuenta? '),
                TextSpan(
                  text: 'Inicia sesión.',
                  style: TextStyle(
                    color: _activeColor,
                    fontWeight: FontWeight.w800,
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
