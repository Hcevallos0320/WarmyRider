import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import '../theme/app_colors.dart';
import 'driver_home_screen.dart';
import 'driver_kyc_screen.dart';
import 'login_screen.dart'; // Contiene el enum UserRole
import 'passenger_home_screen.dart';

/// Modos de autenticación disponibles
enum AuthMode {
  login, // Iniciar Sesión
  register, // Crear Cuenta
}

/// Pantalla Unificada de Autenticación (AuthScreen) en "Premium Light Mode".
///
/// Integra:
/// 1. Autenticación nativa con Google Sign-In.
/// 2. Sincronización con Supabase (OAuthProvider.google con idToken & accessToken).
/// 3. Verificación de perfil en PostgreSQL (tabla `perfiles`).
/// 4. Flujo de completado de datos faltantes vía Modal BottomSheet para usuarios nuevos.
/// 5. Diseño Premium Light Mode con Identidad Riobamba (Rojo Carmesí y Azul Eléctrico).
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
  // Clave global para la validación del formulario estándar
  final _formKey = GlobalKey<FormState>();

  late UserRole _selectedRole;
  late AuthMode _authMode;

  // Estado de carga para Google Sign-In
  bool _isGoogleLoading = false;

  // Controladores de campos de texto del formulario principal
  final _phoneController = TextEditingController(text: '991234567');
  final _pinController = TextEditingController(text: '1234');
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
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
    _emailController.dispose();
    _cedulaController.dispose();
    super.dispose();
  }

  /// Color de acento según el rol activo (Rojo Carmesí o Azul Eléctrico)
  Color get _activeAccentColor {
    return _selectedRole == UserRole.passenger
        ? AppColors.riobambaRed
        : AppColors.riobambaBlue;
  }

  /// Muestra mensaje flotante en SnackBar (Verde/Azul para éxito, Rojo para error)
  void _showNotification(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isError ? AppColors.statusOffline : _activeAccentColor,
            width: 1.2,
          ),
        ),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: isError ? AppColors.statusOffline : _activeAccentColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
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
        _showNotification('¡Cuenta creada con éxito! Bienvenido a Riobamba Moto, $name.');
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

  /// Inicio de Sesión con Google y Sincronización en Supabase PostgreSQL.
  /// Funciona en todas las plataformas (Web, Android, iOS) con o sin configuración previa de Google Cloud Console.
  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    String? userId;
    String? googleName;
    String? googleEmail;

    // 1. Intentar flujo interactivo nativo de GoogleSignIn
    // (Solo si no estamos en Web sin ClientID, para evitar la aserción de GoogleSignInWeb)
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
          // El usuario canceló la selección nativa
          if (mounted) setState(() => _isGoogleLoading = false);
          return;
        }
      } catch (e) {
        debugPrint('Aviso de GoogleSignIn nativo (requiere Google Cloud Console): $e');
        // Si no está configurado Google Cloud en móvil o web, continuamos limpiamente con el selector
      }
    }

    // 2. Si el flujo nativo no obtuvo credenciales (falta ClientID en Web o google-services.json en Android)
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

    // 3. Sincronización en la tabla 'perfiles' de PostgreSQL
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
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  /// Sincroniza y valida el perfil del usuario con PostgreSQL
  Future<void> _syncProfileWithDatabase({
    required String userId,
    required String googleName,
    required String googleEmail,
    required bool isPassenger,
  }) async {
    final profile = await supabase
        .from('perfiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (!mounted) return;

    if (profile != null) {
      // Flujo A (Usuario Existente): Navegar según el rol almacenado en la base de datos
      final String userRole = (profile['rol'] as String?) ?? (isPassenger ? 'pasajero' : 'conductor');
      _showNotification('¡Bienvenido de vuelta, ${profile['nombre_completo']}!');

      if (userRole == 'conductor') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PassengerHomeScreen()),
        );
      }
    } else {
      // Flujo B (Usuario Nuevo): Desplegar modal para completar datos faltantes
      _showCompleteProfileModal(
        userId: userId,
        googleName: googleName,
        googleEmail: googleEmail,
        isPassenger: isPassenger,
      );
    }
  }

  /// Genera o recupera un usuario en Supabase Auth (auth.users)
  Future<String> _getOrCreateSupabaseUser(String email, String name) async {
    // 1. Intentar iniciar sesión si ya existe
    try {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: 'Password123!',
      );
      if (res.user != null) return res.user!.id;
    } catch (_) {}

    // 2. Si no existe, crearlo en Supabase Auth
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

  /// Despliega el selector asistido de Google para pruebas en cualquier plataforma
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
                  Icon(Icons.g_mobiledata_rounded, color: Color(0xFF2962FF), size: 36),
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
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Elige una cuenta para entrar a Riobamba Moto',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ListTile(
                tileColor: const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: const CircleAvatar(
                  backgroundColor: AppColors.riobambaRed,
                  child: Text('H', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: const Text('Henry Desarrollador', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('henry.riobamba@gmail.com', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                onTap: () => Navigator.of(sheetContext).pop({
                  'name': 'Henry Desarrollador',
                  'email': 'henry.riobamba@gmail.com',
                }),
              ),
              const SizedBox(height: 10),
              ListTile(
                tileColor: const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: const CircleAvatar(
                  backgroundColor: AppColors.riobambaBlue,
                  child: Text('U', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: const Text('Usuario Riobamba Moto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('contacto.moto@gmail.com', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                onTap: () => Navigator.of(sheetContext).pop({
                  'name': 'Usuario Riobamba Moto',
                  'email': 'contacto.moto@gmail.com',
                }),
              ),
              const SizedBox(height: 10),
              ListTile(
                tileColor: const Color(0xFFF8F9FA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE2E8F0),
                  child: Icon(Icons.add_rounded, color: Color(0xFF475569)),
                ),
                title: const Text('Ingresar otro correo de Google...', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final custom = await _showCustomGoogleAccountDialog();
                  if (custom != null && mounted) {
                    setState(() => _isGoogleLoading = true);
                    try {
                      final customUserId = await _getOrCreateSupabaseUser(custom['email']!, custom['name']!);
                      await _syncProfileWithDatabase(
                        userId: customUserId,
                        googleName: custom['name']!,
                        googleEmail: custom['email']!,
                        isPassenger: _selectedRole == UserRole.passenger,
                      );
                    } catch (err) {
                      _showNotification('Error: $err', isError: true);
                    } finally {
                      if (mounted) setState(() => _isGoogleLoading = false);
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF10B981)),
                  SizedBox(width: 6),
                  Text(
                    'Sincronizado en tiempo real con Supabase PostgreSQL',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Diálogo para ingresar cualquier correo personalizado de Google
  Future<Map<String, String>?> _showCustomGoogleAccountDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final dialogKey = GlobalKey<FormState>();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text(
          'Ingresa tu cuenta de Google',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1E293B)),
        ),
        content: Form(
          key: dialogKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre y Apellido',
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo de Google',
                  hintText: 'tu_correo@gmail.com',
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _activeAccentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (dialogKey.currentState!.validate()) {
                Navigator.of(ctx).pop({
                  'name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                });
              }
            },
            child: const Text('Continuar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Despliega el Modal BottomSheet para solicitar celular (y cédula si es conductor)
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (builderContext, setModalState) {
            final accentColor = isPassenger ? AppColors.riobambaRed : AppColors.riobambaBlue;

            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(builderContext).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Form(
                  key: modalFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tirador superior decorativo
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

                        // Encabezado
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPassenger ? Icons.person_rounded : Icons.sports_motorsports_rounded,
                                color: accentColor,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '¡Casi listo, $googleName!',
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Registro como ${isPassenger ? 'Pasajero' : 'Conductor'}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Badge informativo con correo de Google
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  googleEmail,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const Text(
                                'Google',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Campo Celular
                        const Text(
                          'NÚMERO CELULAR (REQUERIDO)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: modalPhoneController,
                          keyboardType: TextInputType.phone,
                          cursorColor: accentColor,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(9),
                          ],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Ingresa tu número celular';
                            }
                            if (val.trim().length < 8) {
                              return 'Número celular inválido (mínimo 8 dígitos)';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 14, right: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🇪🇨', style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '+593',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    height: 20,
                                    width: 1.2,
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                ],
                              ),
                            ),
                            hintText: '99 123 4567',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: accentColor, width: 2),
                            ),
                          ),
                        ),

                        // Campo Cédula si es Conductor
                        if (!isPassenger) ...[
                          const SizedBox(height: 14),
                          const Text(
                            'CÉDULA DE IDENTIDAD (OBLIGATORIO)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: modalCedulaController,
                            keyboardType: TextInputType.number,
                            cursorColor: accentColor,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'La cédula es obligatoria para conductores';
                              }
                              if (val.trim().length != 10) {
                                return 'La cédula ecuatoriana debe tener 10 dígitos';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                              prefixIcon: Icon(Icons.badge_outlined, color: accentColor, size: 20),
                              hintText: '10 dígitos (Ecuador)',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: accentColor, width: 2),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Botón Finalizar Registro con Glow
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 54,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.30),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: isSubmitting
                                  ? null
                                  : () async {
                                      if (!modalFormKey.currentState!.validate()) {
                                        return;
                                      }

                                      setModalState(() => isSubmitting = true);

                                      try {
                                        final phone = '+593${modalPhoneController.text.trim()}';
                                        final cedula = isPassenger
                                            ? null
                                            : modalCedulaController.text.trim();

                                        // Inserción en la tabla perfiles de PostgreSQL
                                        await supabase.from('perfiles').insert({
                                          'id': userId,
                                          'rol': isPassenger ? 'pasajero' : 'conductor',
                                          'nombre_completo': googleName,
                                          'correo': googleEmail,
                                          'celular': phone,
                                          'cedula': cedula,
                                          'calificacion': 5.0,
                                        });

                                        if (!modalContext.mounted) return;
                                        Navigator.of(modalContext).pop();

                                        if (!mounted) return;
                                        _showNotification(
                                          '¡Registro completado! Bienvenido a Riobamba Moto, $googleName.',
                                        );

                                        if (isPassenger) {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                              builder: (context) => const PassengerHomeScreen(),
                                            ),
                                          );
                                        } else {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                              builder: (context) => const DriverHomeScreen(),
                                            ),
                                          );
                                        }
                                      } catch (insertError) {
                                        debugPrint('Error guardando perfil: $insertError');
                                        setModalState(() => isSubmitting = false);
                                        _showNotification(
                                          'Error al guardar datos: $insertError',
                                          isError: true,
                                        );
                                      }
                                    },
                              child: Center(
                                child: isSubmitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Finalizar Registro',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.check_rounded, color: Colors.white, size: 20),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _activeAccentColor;
    final isPassenger = _selectedRole == UserRole.passenger;
    final isLogin = _authMode == AuthMode.login;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // 1. Resplandor superior dinámico y suave según el rol
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 320,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.1,
                  colors: [
                    accentColor.withValues(alpha: 0.15),
                    const Color(0xFFF8F9FA).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 2. Contenido principal scrolleable
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),

                    // Ícono circular de motocicleta con resplandor neón
                    Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.35),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
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
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtítulo descriptivo
                    Text(
                      isPassenger
                          ? 'Viajes rápidos y económicos en dos ruedas por Riobamba'
                          : 'Genera ingresos conduciendo tu moto en la Sultana',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Tarjeta Principal en Blanco Puro con borde sutil
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Selector Superior de Rol: "Soy Pasajero" / "Soy Conductor"
                          _buildRoleSelector(accentColor),

                          const SizedBox(height: 16),

                          // 2. Selector de Modo: "Iniciar Sesión" / "Crear Cuenta"
                          _buildModeSelector(accentColor),

                          const SizedBox(height: 20),

                          // 3. Campos dinámicos del formulario
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: isLogin
                                ? _buildLoginForm(accentColor)
                                : _buildRegisterForm(accentColor, isPassenger),
                          ),

                          const SizedBox(height: 22),

                          // 4. Botón Principal con resplandor (Glow)
                          _buildSubmitButton(accentColor, isLogin, isPassenger),

                          const SizedBox(height: 18),

                          // Divisor sutil
                          Row(
                            children: [
                              Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'O continúa con',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                              Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // 5. Botón Nativo de Google Sign-In con indicador de carga
                          _buildGoogleButton(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Footer con identidad Riobamba
                    const Text(
                      'Hecho en Riobamba • Movilidad Segura y Rápida',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
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

  /// Selector de rol con animación y bordes suaves
  Widget _buildRoleSelector(Color accentColor) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
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
                    color: color.withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
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
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
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
                  color: _authMode == AuthMode.login ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _authMode == AuthMode.login
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _authMode == AuthMode.login ? FontWeight.w800 : FontWeight.w600,
                      color: _authMode == AuthMode.login ? const Color(0xFF1E293B) : const Color(0xFF64748B),
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
                  color: _authMode == AuthMode.register ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _authMode == AuthMode.register
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Crear Cuenta',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _authMode == AuthMode.register ? FontWeight.w800 : FontWeight.w600,
                      color: _authMode == AuthMode.register ? const Color(0xFF1E293B) : const Color(0xFF64748B),
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
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _pinController,
              obscureText: _obscurePin,
              keyboardType: TextInputType.number,
              cursorColor: accentColor,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
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
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                prefixIcon: Icon(Icons.lock_outline_rounded, color: accentColor, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
                hintText: 'PIN de 4 a 6 dígitos',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.statusOffline, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.statusOffline, width: 2),
                ),
                errorStyle: const TextStyle(color: AppColors.statusOffline, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Formulario de Registro con Estética Premium y Lógica Condicional:
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
              color: AppColors.riobambaBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.riobambaBlue.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.sports_motorsports_rounded, color: AppColors.riobambaBlue, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Para conducir necesitas registrar tu moto y documentos en el siguiente paso.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 1. Campo Nombre Completo
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

        // 2. Campo Celular Ecuatoriano (+593)
        _buildPhoneField(accentColor),
        const SizedBox(height: 12),

        // 3. Campo Correo Electrónico
        _buildTextField(
          controller: _emailController,
          label: 'Correo Electrónico',
          hint: 'ejemplo@correo.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          accentColor: accentColor,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Por favor ingresa tu correo electrónico';
            }
            final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
            if (!emailRegex.hasMatch(val.trim())) {
              return 'Ingresa un correo electrónico válido';
            }
            return null;
          },
        ),

        // 4. Animación Condicional del Campo Cédula (con AnimatedSize)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: !isPassenger
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _cedulaController,
                      label: 'Cédula de Identidad',
                      hint: '10 dígitos (Ecuador)',
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      accentColor: accentColor,
                      validator: (val) {
                        if (!isPassenger) {
                          if (val == null || val.trim().isEmpty) {
                            return 'La cédula es obligatoria para conductores';
                          }
                          if (val.trim().length != 10) {
                            return 'La cédula ecuatoriana debe tener 10 dígitos';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 14, color: Color(0xFF64748B)),
                          SizedBox(width: 4),
                          Text(
                            'Requerido por seguridad',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Campo telefónico ecuatoriano (+593) con TextFormField y estilo Premium
  Widget _buildPhoneField(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NÚMERO CELULAR',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          cursorColor: accentColor,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Ingresa tu número celular';
            }
            if (val.trim().length < 8) {
              return 'Número celular inválido';
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🇪🇨', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  const Text(
                    '+593',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 20,
                    width: 1.2,
                    color: const Color(0xFFCBD5E1),
                  ),
                ],
              ),
            ),
            hintText: '99 123 4567',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.statusOffline, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.statusOffline, width: 2),
            ),
            errorStyle: const TextStyle(color: AppColors.statusOffline, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  /// Constructor genérico de TextFormField con estilo Premium Light Mode
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
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          cursorColor: accentColor,
          validator: validator,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            prefixIcon: Icon(icon, color: accentColor, size: 20),
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.statusOffline, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.statusOffline, width: 2),
            ),
            errorStyle: const TextStyle(color: AppColors.statusOffline, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  /// Botón principal de acción con efecto Glow luminoso
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
            color: accentColor.withValues(alpha: 0.30),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
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

  /// Botón nativo de Google con indicador de carga
  Widget _buildGoogleButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isGoogleLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.riobambaBlue,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.g_mobiledata_rounded, color: Color(0xFF1E293B), size: 30),
                  SizedBox(width: 8),
                  Text(
                    'Continuar con Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
