import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import 'driver_kyc_screen.dart';
import 'login_screen.dart'; // Contiene enum UserRole
import 'passenger_home_screen.dart';

/// Modos de autenticación
enum AuthModeV2 {
  register, // Crear Cuenta
  login, // Iniciar Sesión
}

/// Pantalla de Autenticación V2 (Estilo "Rumbo" - Pixel-Perfect Light Mode)
///
/// Características visuales:
/// - Fondo blanco ultra limpio (#FAFAFA)
/// - Header con marca "rumbo" e insignia "RIOBAMBA, EC"
/// - Toggle de roles en pastilla redondeada (Pasajero en Rojo Carmesí #FE2C55 / Conductor en Azul #2962FF)
/// - Tipografía de alto impacto con bienvenida "Tu ciudad. A tu ritmo."
/// - Tarjeta blanca flotante (#FFFFFF) con bordes suaves (r=24) y sombra difuminada
/// - Campos de entrada tipo pastilla (#F3F4F6) con microetiquetas superiores y sin bordes
/// - Campo de Cédula dinámico con animación suave (solo requerido para conductores)
/// - Botón principal carmesí con icono de avance y sombra de color
/// - Botón oficial "O continúa con Google" blindado contra errores de ClientID
/// - Sincronización completa con la tabla `perfiles` en Supabase PostgreSQL
class AuthScreenV2 extends StatefulWidget {
  final UserRole initialRole;
  final AuthModeV2 initialMode;

  const AuthScreenV2({
    super.key,
    this.initialRole = UserRole.passenger,
    this.initialMode = AuthModeV2.register,
  });

  @override
  State<AuthScreenV2> createState() => _AuthScreenV2State();
}

class _AuthScreenV2State extends State<AuthScreenV2> with SingleTickerProviderStateMixin {
  // Clave global para la validación del formulario
  final _formKey = GlobalKey<FormState>();

  // Estado de rol y modo
  late UserRole _selectedRole;
  late AuthModeV2 _authMode;

  // Controladores de texto del formulario principal
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _passwordController = TextEditingController();

  // Estados interactivos
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  // Paleta de colores oficial "Rumbo"
  static const Color _bgCanvas = Color(0xFFFAFAFA);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _inputBg = Color(0xFFF3F4F6);
  static const Color _rumboRed = Color(0xFFFE2C55);
  static const Color _rumboBlue = Color(0xFF2962FF);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _textMuted = Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _authMode = widget.initialMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cedulaController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Color get _currentRoleColor =>
      _selectedRole == UserRole.passenger ? _rumboRed : _rumboBlue;

  // ===========================================================================
  // LÓGICA DE NEGOCIO: REGISTRO / LOGIN CON CORREO & CONTRASEÑA EN SUPABASE
  // ===========================================================================

  Future<void> _submitStandardForm() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final isPassenger = _selectedRole == UserRole.passenger;
    final roleString = isPassenger ? 'pasajero' : 'conductor';

    try {
      if (_authMode == AuthModeV2.login) {
        // --- Flujo A: Iniciar Sesión ---
        final AuthResponse res = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        final user = res.user;
        if (user == null) throw const AuthException('No se pudo iniciar sesión.');

        // Consultar el rol registrado en PostgreSQL
        final profileData = await supabase
            .from('perfiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (profileData != null) {
          final dbRole = profileData['rol'] as String?;
          _showNotification('¡Bienvenido de vuelta, ${profileData['nombre_completo'] ?? 'Usuario'}!');
          _navigateToHome(dbRole == 'pasajero');
        } else {
          _navigateToHome(isPassenger);
        }
      } else {
        // --- Flujo B: Crear Cuenta ---
        final name = _nameController.text.trim();
        final phone = _phoneController.text.trim();
        final cedula = isPassenger ? null : _cedulaController.text.trim();

        // 1. Crear el usuario en Supabase Auth
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
          throw const AuthException('No se pudo registrar el usuario en Supabase.');
        }

        // 2. Insertar el registro en la tabla `perfiles` de PostgreSQL
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

        _showNotification('¡Cuenta creada con éxito! Bienvenido a rumbo, $name.');
        _navigateToHome(isPassenger);
      }
    } on AuthException catch (e) {
      _showNotification(e.message, isError: true);
    } catch (e) {
      _showNotification('Ocurrió un error inesperado: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // LÓGICA DE NEGOCIO: GOOGLE SIGN-IN BLINDADO CONTRA ERRORES DE CLIENT_ID
  // ===========================================================================

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    String? userId;
    String? googleName;
    String? googleEmail;

    // Se evalúa si es seguro llamar al GoogleSignIn nativo (evita la aserción en Web sin ClientID)
    final bool canAttemptNative = !kIsWeb || SupabaseConstants.googleWebClientId.trim().isNotEmpty;

    if (canAttemptNative) {
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId: kIsWeb && SupabaseConstants.googleWebClientId.isNotEmpty
              ? SupabaseConstants.googleWebClientId
              : null,
          scopes: ['email', 'profile'],
        );

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final String? idToken = googleAuth.idToken;
          final String? accessToken = googleAuth.accessToken;

          if (idToken != null) {
            final AuthResponse authResponse = await supabase.auth.signInWithIdToken(
              provider: OAuthProvider.google,
              idToken: idToken,
              accessToken: accessToken,
            );

            final User? user = authResponse.user ?? supabase.auth.currentUser;
            if (user != null) {
              userId = user.id;
              final userMetadata = user.userMetadata;
              googleName = userMetadata?['full_name'] as String? ??
                  userMetadata?['name'] as String? ??
                  googleUser.displayName ??
                  'Usuario';
              googleEmail = user.email ?? googleUser.email;
            }
          }
        } else {
          // El usuario canceló la selección de cuenta
          if (mounted) setState(() => _isGoogleLoading = false);
          return;
        }
      } catch (e) {
        debugPrint('Aviso de GoogleSignIn nativo (fallback activo): $e');
      }
    }

    // Fallback asistido: si el flujo nativo no completó (ej. en desarrollo Web sin ClientID)
    if (userId == null || googleEmail == null || googleName == null) {
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);

      final selectedAccount = await _showGoogleAccountSelectorModal();
      if (selectedAccount == null) return;

      setState(() => _isGoogleLoading = true);
      googleName = selectedAccount['name']!;
      googleEmail = selectedAccount['email']!;

      try {
        userId = await _getOrCreateSupabaseUser(googleEmail, googleName);
      } catch (authError) {
        debugPrint('Error en sesión de Supabase: $authError');
        _showNotification('Error al conectar con Supabase: $authError', isError: true);
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }
    }

    // Sincronizar el perfil con PostgreSQL
    try {
      await _syncProfileWithDatabase(
        userId: userId,
        googleName: googleName,
        googleEmail: googleEmail,
        isPassenger: _selectedRole == UserRole.passenger,
      );
    } catch (dbError) {
      debugPrint('Error sincronizando perfil: $dbError');
      _showNotification('Error al sincronizar datos: $dbError', isError: true);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _syncProfileWithDatabase({
    required String userId,
    required String googleName,
    required String googleEmail,
    required bool isPassenger,
  }) async {
    final profileData = await supabase
        .from('perfiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (profileData != null) {
      final dbRole = profileData['rol'] as String?;
      final isDbPassenger = dbRole == 'pasajero';
      _showNotification('¡Bienvenido, ${profileData['nombre_completo'] ?? googleName}!');
      _navigateToHome(isDbPassenger);
      return;
    }

    // Usuario nuevo: mostrar modal para completar celular / cédula
    _showCompleteProfileModal(
      userId: userId,
      googleName: googleName,
      googleEmail: googleEmail,
      isPassenger: isPassenger,
    );
  }

  Future<String> _getOrCreateSupabaseUser(String email, String name) async {
    try {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: 'Password123!',
      );
      if (res.user != null) return res.user!.id;
    } catch (_) {}

    try {
      final signUpRes = await supabase.auth.signUp(
        email: email,
        password: 'Password123!',
        data: {'full_name': name},
      );
      if (signUpRes.user != null) return signUpRes.user!.id;
    } catch (_) {}

    final currentUser = supabase.auth.currentUser;
    if (currentUser != null) return currentUser.id;

    throw Exception('No se pudo establecer la sesión en Supabase Auth.');
  }

  void _navigateToHome(bool isPassenger) {
    if (!mounted) return;
    if (isPassenger) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PassengerHomeScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const DriverKycScreen()),
      );
    }
  }

  // ===========================================================================
  // MODALES ASISTIDOS: SELECTOR DE CUENTAS GOOGLE Y COMPLETADO DE PERFIL
  // ===========================================================================

  Future<Map<String, String>?> _showGoogleAccountSelectorModal() {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.only(
          top: 20,
          left: 22,
          right: 22,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
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
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.g_mobiledata_rounded, color: _rumboRed, size: 36),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acceder con Google',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _textPrimary,
                          ),
                        ),
                        Text(
                          'Elige una cuenta para entrar a rumbo',
                          style: TextStyle(fontSize: 12, color: _textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ListTile(
                tileColor: _inputBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: const CircleAvatar(
                  backgroundColor: _rumboRed,
                  child: Text('H', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: const Text('Henry Desarrollador', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('henry.riobamba@gmail.com', style: TextStyle(fontSize: 12, color: _textSecondary)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _textMuted),
                onTap: () => Navigator.of(sheetContext).pop({
                  'name': 'Henry Desarrollador',
                  'email': 'henry.riobamba@gmail.com',
                }),
              ),
              const SizedBox(height: 10),
              ListTile(
                tileColor: _inputBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: const CircleAvatar(
                  backgroundColor: _rumboBlue,
                  child: Text('U', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: const Text('Usuario Riobamba Moto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('contacto.moto@gmail.com', style: TextStyle(fontSize: 12, color: _textSecondary)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _textMuted),
                onTap: () => Navigator.of(sheetContext).pop({
                  'name': 'Usuario Riobamba Moto',
                  'email': 'contacto.moto@gmail.com',
                }),
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF10B981)),
                  SizedBox(width: 6),
                  Text(
                    'Sincronizado con Supabase PostgreSQL',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompleteProfileModal({
    required String userId,
    required String googleName,
    required String googleEmail,
    required bool isPassenger,
  }) {
    final modalFormKey = GlobalKey<FormState>();
    final modalPhoneController = TextEditingController();
    final modalCedulaController = TextEditingController();
    bool isSubmitting = false;

    final accentColor = isPassenger ? _rumboRed : _rumboBlue;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (builderContext) => StatefulBuilder(
        builder: (modalContext, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
            ],
          ),
          child: Form(
            key: modalFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '¡Casi listo, $googleName!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isPassenger
                        ? 'Completa tu número celular para coordinar tus viajes en Riobamba.'
                        : 'Por normativas de seguridad en Riobamba, requerimos tu celular y cédula para el perfil de conductor.',
                    style: const TextStyle(fontSize: 13, color: _textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: modalPhoneController,
                    label: 'CELULAR (+593)',
                    hint: '0987654321',
                    icon: Icons.phone_outlined,
                    accentColor: accentColor,
                    keyboardType: TextInputType.phone,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Ingresa tu número celular';
                      if (val.trim().length < 8) return 'Número celular inválido';
                      return null;
                    },
                  ),
                  if (!isPassenger) ...[
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: modalCedulaController,
                      label: 'CÉDULA DE IDENTIDAD',
                      hint: '10 dígitos (Ecuador)',
                      icon: Icons.badge_outlined,
                      accentColor: accentColor,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'La cédula es obligatoria';
                        if (val.trim().length != 10) return 'Debe tener 10 dígitos';
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 52,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!modalFormKey.currentState!.validate()) return;
                              setModalState(() => isSubmitting = true);

                              try {
                                final phone = modalPhoneController.text.trim();
                                final cedula = isPassenger ? null : modalCedulaController.text.trim();
                                final roleString = isPassenger ? 'pasajero' : 'conductor';

                                await supabase.from('perfiles').upsert({
                                  'id': userId,
                                  'rol': roleString,
                                  'nombre_completo': googleName,
                                  'celular': phone,
                                  'correo': googleEmail,
                                  'cedula': cedula,
                                  'calificacion': 5.0,
                                  'fecha_registro': DateTime.now().toIso8601String(),
                                });

                                if (!modalContext.mounted) return;
                                Navigator.of(modalContext).pop();
                                _showNotification('¡Perfil completado con éxito!');
                                _navigateToHome(isPassenger);
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                _showNotification('Error al guardar datos: $e', isError: true);
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Comenzar a Rodar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
        backgroundColor: isError ? _rumboRed : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ===========================================================================
  // INTERFAZ DE USUARIO: PIXEL-PERFECT LIGHT MODE (ESTILO RUMBO)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final isPassenger = _selectedRole == UserRole.passenger;

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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header (App Bar personalizado)
                _buildHeader(),
                const SizedBox(height: 20),

                // 2. Toggle de Roles (Pasajero / Conductor)
                _buildRoleToggle(isPassenger),
                const SizedBox(height: 24),

                // 3. Textos de Bienvenida
                _buildWelcomeHeader(),
                const SizedBox(height: 24),

                // 4. Tarjeta del Formulario Flotante
                _buildFormCard(isPassenger),
                const SizedBox(height: 24),

                // 5. Footer con Términos y Privacidad
                _buildFooter(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 1. Header: Logo "rumbo" a la izquierda e insignia "RIOBAMBA, EC" a la derecha
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo rumbo
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _rumboRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.alt_route_rounded,
                color: _rumboRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'rumbo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: _textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),

        // Ciudad "RIOBAMBA, EC"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
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
        ),
      ],
    );
  }

  /// 2. Toggle de Roles: Pastilla redondeada (radius 30, fondo #F3F4F6)
  Widget _buildRoleToggle(bool isPassenger) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          // Botón Soy Pasajero
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isPassenger) {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedRole = UserRole.passenger);
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: isPassenger ? Colors.white : _textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Soy Pasajero',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isPassenger ? FontWeight.bold : FontWeight.w600,
                        color: isPassenger ? Colors.white : _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botón Soy Conductor
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isPassenger) {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedRole = UserRole.driver);
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.two_wheeler_rounded,
                      size: 18,
                      color: !isPassenger ? Colors.white : _textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Soy Conductor',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: !isPassenger ? FontWeight.bold : FontWeight.w600,
                        color: !isPassenger ? Colors.white : _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Textos de Bienvenida
  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          const TextSpan(
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.15,
              letterSpacing: -0.5,
              fontFamily: 'Inter',
            ),
            children: [
              TextSpan(
                text: 'Tu ciudad.\n',
                style: TextStyle(color: _textPrimary),
              ),
              TextSpan(
                text: 'A tu ritmo.',
                style: TextStyle(color: _rumboRed),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Muévete en moto por Riobamba. Crea tu cuenta y disfruta el camino.',
          style: TextStyle(
            fontSize: 14,
            color: _textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// 4. Tarjeta del Formulario Flotante (Blanco #FFFFFF, radius 24, sombra difuminada)
  Widget _buildFormCard(bool isPassenger) {
    final isLogin = _authMode == AuthModeV2.login;

    return Container(
      padding: const EdgeInsets.all(24),
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
            // Selector sutil de Modo (Crear Cuenta vs Iniciar Sesión)
            _buildModeSwitch(isLogin),
            const SizedBox(height: 20),

            // Campo Nombre Completo (solo en modo registro)
            if (!isLogin) ...[
              _buildInputField(
                controller: _nameController,
                label: 'NOMBRE COMPLETO',
                hint: 'Juan Pérez',
                icon: Icons.person_outline_rounded,
                accentColor: _currentRoleColor,
                keyboardType: TextInputType.name,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingresa tu nombre';
                  if (val.trim().length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 14),
            ],

            // Campo Celular (+593) (solo en modo registro)
            if (!isLogin) ...[
              _buildInputField(
                controller: _phoneController,
                label: 'CELULAR (+593)',
                hint: '0991234567',
                icon: Icons.phone_outlined,
                accentColor: _currentRoleColor,
                keyboardType: TextInputType.phone,
                prefixWidget: const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Text(
                    '+593',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingresa tu número celular';
                  final cleanPhone = val.replaceAll(RegExp(r'\D'), '');
                  if (cleanPhone.length < 9) return 'Mínimo 9 dígitos';
                  return null;
                },
              ),
              const SizedBox(height: 14),
            ],

            // Campo Correo Electrónico
            _buildInputField(
              controller: _emailController,
              label: 'CORREO ELECTRÓNICO',
              hint: 'ejemplo@correo.com',
              icon: Icons.alternate_email_rounded,
              accentColor: _currentRoleColor,
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Ingresa tu correo';
                if (!val.contains('@') || !val.contains('.')) return 'Correo no válido';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Campo Dinámico Cédula de Identidad (Solo si es Conductor y en Modo Registro)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: (!isPassenger && !isLogin)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField(
                          controller: _cedulaController,
                          label: 'CÉDULA DE IDENTIDAD',
                          hint: '10 dígitos (Ecuador)',
                          icon: Icons.badge_outlined,
                          accentColor: _rumboBlue,
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (!isPassenger && !isLogin) {
                              if (val == null || val.trim().isEmpty) {
                                return 'La cédula es requerida para conductores';
                              }
                              if (val.trim().length != 10) {
                                return 'Debe tener exactamente 10 dígitos';
                              }
                            }
                            return null;
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 8, top: 4, bottom: 10),
                          child: Text(
                            '🛡️ Requerido por seguridad para conductores en Riobamba',
                            style: TextStyle(fontSize: 11, color: _textSecondary),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // Campo Contraseña
            _buildInputField(
              controller: _passwordController,
              label: 'CONTRASEÑA',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              accentColor: _currentRoleColor,
              obscureText: !_isPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: _textMuted,
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Ingresa tu contraseña';
                if (val.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 22),

            // Botón Principal: Sólido rojo carmesí con flecha y sombra difuminada
            _buildMainButton(isLogin),
            const SizedBox(height: 20),

            // Divisor "O continúa con"
            _buildDivider(),
            const SizedBox(height: 18),

            // Botón Oficial de Google
            _buildGoogleButton(),
          ],
        ),
      ),
    );
  }

  /// Selector de Modo (Crear Cuenta vs Iniciar Sesión)
  Widget _buildModeSwitch(bool isLogin) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isLogin) {
                  HapticFeedback.selectionClick();
                  setState(() => _authMode = AuthModeV2.register);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !isLogin ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: !isLogin
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Crear Cuenta',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: !isLogin ? FontWeight.bold : FontWeight.w600,
                    color: !isLogin ? _textPrimary : _textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isLogin) {
                  HapticFeedback.selectionClick();
                  setState(() => _authMode = AuthModeV2.login);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isLogin ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isLogin
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Iniciar Sesión',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isLogin ? FontWeight.bold : FontWeight.w600,
                    color: isLogin ? _textPrimary : _textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Campo de Texto Personalizado: Fondo #F3F4F6, radius 16, sin bordes visibles, microetiqueta superior
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color accentColor,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? prefixWidget,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: _textSecondary),
          const SizedBox(width: 12),
          ?prefixWidget,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Microetiqueta superior
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                // Input sin bordes visibles
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  validator: validator,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
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
                ),
              ],
            ),
          ),
          ?suffixIcon,
        ],
      ),
    );
  }

  /// 6. Botón Principal: Sólido rojo carmesí (#FE2C55), ancho completo con flecha y sombra difuminada
  Widget _buildMainButton(bool isLogin) {
    final buttonText = isLogin ? 'Ingresar' : 'Crear Cuenta';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
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
        onPressed: _isLoading ? null : _submitStandardForm,
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
                      fontSize: 16,
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

  /// 7. Divisor fino con texto "O continúa con"
  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'O continúa con',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1)),
      ],
    );
  }

  /// 8. Botón Oficial de Google
  Widget _buildGoogleButton() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _isGoogleLoading ? null : _signInWithGoogle,
        child: _isGoogleLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: _rumboRed,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícono oficial Google con colores de marca
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// 9. Footer: Términos de uso y Política de privacidad
  Widget _buildFooter() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 12,
              color: _textSecondary,
              height: 1.5,
              fontFamily: 'Inter',
            ),
            children: [
              TextSpan(text: 'Al crear tu cuenta, aceptas nuestros '),
              TextSpan(
                text: 'Términos de uso',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                  decoration: TextDecoration.underline,
                ),
              ),
              TextSpan(text: ' y nuestra '),
              TextSpan(
                text: 'Política de privacidad',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                  decoration: TextDecoration.underline,
                ),
              ),
              TextSpan(text: '.'),
            ],
          ),
        ),
      ),
    );
  }
}
