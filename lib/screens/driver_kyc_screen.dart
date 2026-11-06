import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'driver_home_screen.dart';

/// Formulario multipaso de verificación (KYC) y papeles de la motocicleta para Conductores.
/// Paso 1: Ficha técnica y casco homologado.
/// Paso 2: Subida de documentos obligatorios mediante tarjetas interactivas.
class DriverKycScreen extends StatefulWidget {
  const DriverKycScreen({super.key});

  @override
  State<DriverKycScreen> createState() => _DriverKycScreenState();
}

class _DriverKycScreenState extends State<DriverKycScreen> {
  int _currentStep = 0; // 0 = Datos de la Moto, 1 = Documentos

  // Controladores Paso 1: Ficha de la Moto
  final _modelController = TextEditingController(text: 'Bajaj Pulsar NS 200');
  final _yearController = TextEditingController(text: '2023');
  final _colorController = TextEditingController(text: 'Negro con vivos azules');
  final _plateController = TextEditingController(text: 'HA123B');
  bool _hasSecondHelmet = true;

  // Estado de carga de documentos (Paso 2)
  final Map<String, bool> _uploadedDocuments = {
    'cedula': false,
    'licencia': false,
    'matricula': false,
    'foto_moto': false,
    'selfie': false,
  };

  @override
  void dispose() {
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  /// Alterna el estado interactivo de subida de un documento al tocarlo
  void _toggleDocument(String key) {
    setState(() {
      _uploadedDocuments[key] = !(_uploadedDocuments[key] ?? false);
    });

    final isUploaded = _uploadedDocuments[key] ?? false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isUploaded ? AppColors.primaryNeon : AppColors.statusOffline,
          ),
        ),
        content: Text(
          isUploaded ? 'Documento cargado correctamente ✅' : 'Documento removido',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Procesa el envío final de los documentos
  void _submitKyc() {
    // Si no ha marcado el casco
    if (!_hasSecondHelmet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.statusOffline,
          content: Text('Es obligatorio contar con un segundo casco para el pasajero.'),
        ),
      );
      return;
    }

    // Diálogo de verificación aprobada
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.riobambaBlue, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: AppColors.riobambaBlue, size: 28),
            SizedBox(width: 10),
            Text('¡Perfil en Revisión!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tus documentos han sido recibidos para validación oficial en Riobamba.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              'Entrando al panel de conducción en modo demostración...',
              style: TextStyle(color: AppColors.primaryNeon, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.riobambaBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Comenzar a Conducir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Registro de Moto y Papeles',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior indicadora de progreso multipaso
            _buildStepIndicator(),

            // Contenido dinámico según el paso activo
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: _currentStep == 0 ? _buildStep1MotoDetails() : _buildStep2Documents(),
              ),
            ),

            // Botón de acción inferior fijo
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
              child: _buildBottomActionButton(),
            ),
          ],
        ),
      ),
    );
  }

  /// Barra de progreso superior en Azul Eléctrico
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PASO 1: DATOS DE LA MOTO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _currentStep == 0 ? AppColors.riobambaBlue : AppColors.primaryNeon,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: _currentStep >= 0 ? AppColors.riobambaBlue : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PASO 2: DOCUMENTOS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _currentStep == 1 ? AppColors.riobambaBlue : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: _currentStep == 1 ? AppColors.riobambaBlue : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// PASO 1: Formulario de la Motocicleta
  Widget _buildStep1MotoDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Banner informativo
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.riobambaBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.riobambaBlue.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.riobambaBlue, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ingresa los datos exactos de tu moto tal como figuran en la matrícula para autorizar tu cuenta.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildInputField(
          label: 'Marca y Modelo',
          hint: 'Ej: Loncin 250, Daytona, Pulsar NS 200',
          controller: _modelController,
          icon: Icons.motorcycle_rounded,
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              flex: 5,
              child: _buildInputField(
                label: 'Número de Placa',
                hint: 'Ej: HA123B',
                controller: _plateController,
                icon: Icons.badge_outlined,
                capitalization: TextCapitalization.characters,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: _buildInputField(
                label: 'Año',
                hint: '2023',
                controller: _yearController,
                icon: Icons.calendar_month_rounded,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        _buildInputField(
          label: 'Color Principal',
          hint: 'Ej: Negro, Azul, Rojo',
          controller: _colorController,
          icon: Icons.palette_outlined,
        ),
        const SizedBox(height: 22),

        // Switch obligatorio: Segundo Casco Homologado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hasSecondHelmet ? AppColors.riobambaBlue : AppColors.statusOffline,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.sports_motorsports_rounded,
                color: _hasSecondHelmet ? AppColors.riobambaBlue : AppColors.statusOffline,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Segundo Casco para Pasajero',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    Text(
                      'Cuento con un segundo casco homologado y limpio para mis clientes.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _hasSecondHelmet,
                activeThumbColor: AppColors.riobambaBlue,
                onChanged: (val) {
                  setState(() => _hasSecondHelmet = val);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// PASO 2: Subida de Documentos (Tarjetas Interactivas)
  Widget _buildStep2Documents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'DOCUMENTOS REQUERIDOS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Toca cada tarjeta para simular la carga y verificación de tus documentos:',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),

        _buildDocumentUploadCard(
          keyName: 'cedula',
          title: 'Cédula de Identidad',
          subtitle: 'Ambos lados en formato legible',
          icon: Icons.credit_card_rounded,
        ),
        const SizedBox(height: 12),

        _buildDocumentUploadCard(
          keyName: 'licencia',
          title: 'Licencia de Conducir Tipo A',
          subtitle: 'Vigente para motocicletas en Ecuador',
          icon: Icons.card_membership_rounded,
        ),
        const SizedBox(height: 12),

        _buildDocumentUploadCard(
          keyName: 'matricula',
          title: 'Matrícula de la Moto',
          subtitle: 'Revisión vehicular y matrícula al día',
          icon: Icons.article_rounded,
        ),
        const SizedBox(height: 12),

        _buildDocumentUploadCard(
          keyName: 'foto_moto',
          title: 'Fotografía de la Motocicleta',
          subtitle: 'Donde se aprecie el estado y placa visible',
          icon: Icons.camera_alt_rounded,
        ),
        const SizedBox(height: 12),

        _buildDocumentUploadCard(
          keyName: 'selfie',
          title: 'Selfie de Seguridad con Licencia',
          subtitle: 'Fotografía de tu rostro sosteniendo la licencia',
          icon: Icons.face_retouching_natural_rounded,
        ),
      ],
    );
  }

  /// Tarjeta interactiva de carga de documento
  Widget _buildDocumentUploadCard({
    required String keyName,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isUploaded = _uploadedDocuments[keyName] ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _toggleDocument(keyName),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUploaded ? AppColors.primaryNeon : Colors.white.withValues(alpha: 0.08),
              width: isUploaded ? 1.5 : 1,
            ),
            boxShadow: isUploaded
                ? [
                    BoxShadow(
                      color: AppColors.primaryNeon.withValues(alpha: 0.15),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isUploaded
                      ? AppColors.primaryNeon.withValues(alpha: 0.15)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isUploaded ? AppColors.primaryNeon : AppColors.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isUploaded ? 'Documento cargado correctamente' : subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isUploaded ? FontWeight.w700 : FontWeight.w400,
                        color: isUploaded ? AppColors.primaryNeon : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isUploaded ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                color: isUploaded ? AppColors.primaryNeon : AppColors.textMuted,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Campo de texto genérico para la ficha técnica
  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.words,
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
            textCapitalization: capitalization,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
            cursorColor: AppColors.riobambaBlue,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  /// Botón de acción inferior (Siguiente / Enviar Documentos)
  Widget _buildBottomActionButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.riobambaBlue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.riobambaBlue.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (_currentStep == 0) {
              setState(() => _currentStep = 1);
            } else {
              _submitKyc();
            }
          },
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentStep == 0 ? 'Siguiente: Subir Documentos' : 'Enviar Documentos y Entrar',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.4,
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
}
