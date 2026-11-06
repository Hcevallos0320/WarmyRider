import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../widgets/google_auth_sheet.dart';
import 'driver_home_screen.dart';
import 'login_screen.dart';

/// Pantalla de Registro de Nuevos Usuarios (RegisterScreen).
/// Permite el registro de Pasajeros y Conductores con campos específicos
/// para cada rol (documentos, datos de la motocicleta para conductores, etc.).
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
  late UserRole _selectedRole;

  // Controladores de campos personales
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cedulaController = TextEditingController();

  // Controladores de conductor y motocicleta
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();

  // Aceptación de términos
  bool _acceptTerms = true;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cedulaController.dispose();
    _plateController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  /// Color de acento según el rol activo
  Color get _activeAccentColor {
    return _selectedRole == UserRole.passenger
        ? AppColors.riobambaRed
        : AppColors.riobambaBlue;
  }

  /// Procesa el registro del usuario
  void _handleRegister() {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.statusOffline,
          behavior: SnackBarBehavior.floating,
          content: Text('Debes aceptar los Términos y Condiciones para continuar.'),
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final displayName = name.isNotEmpty ? name : 'Usuario';

    if (_selectedRole == UserRole.driver) {
      // Registro de Conductor completado exitosamente -> Navega a DriverHomeScreen
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
                  '¡Registro exitoso como Conductor, $displayName!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
        (route) => false,
      );
    } else {
      // Registro de Pasajero completado
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
                  '¡Cuenta de Pasajero creada para $displayName!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );

      Navigator.of(context).pop();
    }
  }

  /// Despliega el modal de Google para registro rápido
  void _openGoogleSheet() async {
    final selectedEmail = await GoogleAuthSheet.show(
      context: context,
      role: _selectedRole,
    );

    if (selectedEmail != null && mounted) {
      setState(() {
        _emailController.text = selectedEmail;
        if (_nameController.text.isEmpty) {
          _nameController.text = selectedEmail.split('@').first.replaceAll('.', ' ').toUpperCase();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: _activeAccentColor),
          ),
          content: Text('Datos importados desde Google ($selectedEmail)'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _activeAccentColor;
    final isDriver = _selectedRole == UserRole.driver;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Crear Cuenta',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Resplandor superior dinámico
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              height: 320,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.1,
                  colors: [
                    accentColor.withValues(alpha: 0.18),
                    AppColors.background.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Selector de Rol (Pasajero / Conductor)
                  _buildRoleSelector(accentColor),

                  const SizedBox(height: 24),

                  // Botón rápido de registro con Google
                  _buildGoogleRegisterButton(),

                  const SizedBox(height: 20),

                  // Separador
                  Row(
                    children: [
                      Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.08))),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'O completa tus datos',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.08))),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Sección: Datos Personales
                  _buildSectionTitle('DATOS PERSONALES', Icons.badge_rounded, accentColor),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _nameController,
                    label: 'Nombre y Apellido',
                    hint: 'Ej: Juan Pérez',
                    icon: Icons.person_outline_rounded,
                    accentColor: accentColor,
                  ),

                  const SizedBox(height: 14),

                  _buildTextField(
                    controller: _emailController,
                    label: 'Correo Electrónico',
                    hint: 'ejemplo@correo.com',
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    accentColor: accentColor,
                  ),

                  const SizedBox(height: 14),

                  _buildPhoneField(accentColor),

                  const SizedBox(height: 14),

                  _buildTextField(
                    controller: _cedulaController,
                    label: 'Cédula de Identidad',
                    hint: '10 dígitos (Ecuador)',
                    icon: Icons.credit_card_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    accentColor: accentColor,
                  ),

                  // Sección Exclusiva para Conductores: Datos de la Motocicleta
                  if (isDriver) ...[
                    const SizedBox(height: 28),
                    _buildSectionTitle('DATOS DE LA MOTOCICLETA', Icons.two_wheeler_rounded, accentColor),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: _buildTextField(
                            controller: _plateController,
                            label: 'Placa de la Moto',
                            hint: 'Ej: IA-450X',
                            icon: Icons.numbers_rounded,
                            textCapitalization: TextCapitalization.characters,
                            accentColor: accentColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: _buildTextField(
                            controller: _yearController,
                            label: 'Año',
                            hint: '2023',
                            icon: Icons.calendar_today_rounded,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            accentColor: accentColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: _modelController,
                      label: 'Marca y Modelo',
                      hint: 'Ej: Bajaj Pulsar NS 200',
                      icon: Icons.motorcycle_rounded,
                      accentColor: accentColor,
                    ),

                    const SizedBox(height: 14),

                    // Badge de validación de Licencia Tipo A
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.riobambaBlue.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: AppColors.riobambaBlue, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Requisito Obligatorio: Licencia Tipo A',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Válida para conducción de motocicletas en Ecuador',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  // Checkbox de Términos y Condiciones
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        activeColor: accentColor,
                        checkColor: Colors.white,
                        onChanged: (val) {
                          setState(() {
                            _acceptTerms = val ?? true;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Acepto los Términos de Servicio y la Política de Privacidad de Riobamba Moto.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Botón Principal: "Crear Cuenta"
                  _buildSubmitButton(accentColor),

                  const SizedBox(height: 20),

                  // Enlace a Iniciar Sesión
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿Ya tienes una cuenta? ',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          'Inicia Sesión',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Selector de rol
  Widget _buildRoleSelector(Color accentColor) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildRoleOption(
              role: UserRole.passenger,
              label: 'Pasajero',
              icon: Icons.person_rounded,
              color: AppColors.riobambaRed,
            ),
          ),
          Expanded(
            child: _buildRoleOption(
              role: UserRole.driver,
              label: 'Conductor',
              icon: Icons.sports_motorsports_rounded,
              color: AppColors.riobambaBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption({
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
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
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

  /// Título de sección con ícono temático
  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Campo de texto genérico estilizado para Dark Mode
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color accentColor,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            cursorColor: accentColor,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  /// Campo telefónico con prefijo ecuatoriano fijo
  Widget _buildPhoneField(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NÚMERO CELULAR',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🇪🇨', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    const Text(
                      '+593',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 10),
                    Container(height: 22, width: 1, color: Colors.white.withValues(alpha: 0.12)),
                  ],
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  cursorColor: accentColor,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    hintText: '987 654 321',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Botón para registrarse con Google
  Widget _buildGoogleRegisterButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: _openGoogleSheet,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text(
              'Autocompletar con Google',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  /// Botón principal "Crear Cuenta" con resplandor
  Widget _buildSubmitButton(Color accentColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 56,
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.38),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _handleRegister,
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Crear Cuenta',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
