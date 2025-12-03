import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:puntocheck/models/organization_model.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/presentation/shared/widgets/outlined_dark_button.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/utils/safe_image_picker.dart';
class AparienciaAppView extends ConsumerStatefulWidget {
  const AparienciaAppView({super.key});
  @override
  ConsumerState<AparienciaAppView> createState() => _AparienciaAppViewState();
}
class _AparienciaAppViewState extends ConsumerState<AparienciaAppView> {
  final _nombreAppController = TextEditingController(text: 'PuntoCheck');
  final _colorController = TextEditingController(text: '#EB283D');
  final _imagePicker = SafeImagePicker();
  bool _initialized = false;
  bool _isUploadingLogo = false;
  String? _currentLogo;
  String? _orgId;
  String? _orgName;
  String? _orgLogoPath;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(currentOrganizationProvider);
    });
    _recoverLostLogo();
  }
  @override
  void dispose() {
    _nombreAppController.dispose();
    _colorController.dispose();
    super.dispose();
  }
  Future<void> _recoverLostLogo() async {
    final file = await _imagePicker.recoverLostImage();
    if (file == null) return;
    final profile = await ref.read(profileProvider.future);
    final orgId = profile?.organizationId;
    final userId = profile?.id;
    if (orgId == null || userId == null) {
      return;
    }
    await _uploadLogoFile(file, orgId, userId);
  }

  Future<void> _hydrateFromOrg(Organization org) async {
    final isSameOrg = _orgId == org.id;
    final isSameLogo = _orgLogoPath == org.logoUrl;
    if (_initialized && isSameOrg && isSameLogo && _currentLogo != null) {
      return;
    }

    final storage = ref.read(storageServiceProvider);
    final resolvedLogo = (org.logoUrl?.isNotEmpty ?? false)
        ? await storage.resolveOrgLogoUrl(org.logoUrl!, expiresInSeconds: 3600)
        : null;

    if (!mounted) return;
    setState(() {
      _initialized = true;
      _orgId = org.id;
      _orgName = org.name;
      _orgLogoPath = org.logoUrl;
      _nombreAppController.text = org.name;
      _colorController.text = org.brandColor;
      _currentLogo = resolvedLogo ?? org.logoUrl;
    });
  }
  Future<void> _saveAppearance() async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null || profile.organizationId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo obtener la organizacion'),
        ),
      );
      return;
    }
    final updates = {
      'name': _nombreAppController.text,
      'brand_color': _colorController.text,
    };
    final controller = ref.read(organizationControllerProvider.notifier);
    await controller.updateOrgConfig(profile.organizationId!, updates);
    final state = ref.read(organizationControllerProvider);
    ref.invalidate(currentOrganizationProvider);
    ref.invalidate(allOrganizationsProvider);
    if (!mounted) return;
    if (state.hasError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
    } else {
      _showSuccessModal(context, 'Apariencia guardada');
    }
  }
  @override
  Widget build(BuildContext context) {
    final orgState = ref.watch(organizationControllerProvider);
    final orgAsync = ref.watch(currentOrganizationProvider);
    final isLoading = orgState.isLoading;
    orgAsync.when(
      data: (org) {
        if (org != null) {
          _hydrateFromOrg(org);
        }
      },
      loading: () {},
      error: (_, __) {},
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apariencia App'),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _colorFromText(_colorController.text).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personalizacion de Marca',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryRed,
                  ),
                ),
                const SizedBox(height: 12),
                _BrandHeader(
                  orgName: _orgName ?? 'Tu organizacion',
                  brandColor: _colorFromText(_colorController.text),
                  logoUrl: _currentLogo,
                  isUploading: _isUploadingLogo,
                  onUpload: _isUploadingLogo ? null : _pickAndUploadLogo,
                ),
                const SizedBox(height: 20),
          const Text(
            'Nombre de la aplicacion',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.backgroundDark,
            ),
          ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nombreAppController,
                  decoration: _inputDecoration('Mi Asistencia'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Color principal de la marca',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.backgroundDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _openColorPicker,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _colorFromText(_colorController.text),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _colorController,
                        decoration: _inputDecoration('#EB283D'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _colorPreview(
                        _colorFromText(
                          _colorController.text,
                        ).withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _colorPreview(
                        _colorFromText(_colorController.text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _colorPreview(
                        _colorFromText(
                          _colorController.text,
                        ).withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Vista previa de tonos derivados.',
                  style: TextStyle(
                    color: AppColors.black.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedDarkButton(
            text: 'Cancelar',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            text: isLoading ? 'Guardando...' : 'Guardar Cambios',
            enabled: !isLoading,
            onPressed: _saveAppearance,
          ),
        ],
      ),
    );
  }
  Widget _colorPreview(Color color) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.black.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.black.withValues(alpha: 0.1)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primaryRed),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    );
  }
  Color _colorFromText(String value) {
    final clean = value.replaceAll('#', '');
    try {
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primaryRed;
    }
  }
  void _openColorPicker() {
    final textController = TextEditingController(text: _colorController.text);
    final presets = ['#EB283D', '#1ABC9C', '#1E88E5', '#F5A623', '#8D99AE'];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecciona un color',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.backgroundDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: presets
                    .map(
                      (hex) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            _colorController.text = hex;
                            setState(() {});
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _colorFromText(hex),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.black.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ingresa un color HEX',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.backgroundDark,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                decoration: _inputDecoration('#EB283D'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                text: 'Aplicar',
                onPressed: () {
                  _colorController.text = textController.text;
                  setState(() {});
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
  Future<void> _pickAndUploadLogo() async {
    final profile = await ref.read(profileProvider.future);
    final orgId = profile?.organizationId;
    final userId = profile?.id;
    if (orgId == null || userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la organizacion.')),
      );
      return;
    }
    final result = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
    );
    if (result.permissionDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Permiso denegado. Habilitalo en ajustes.')),
        );
        if (result.permanentlyDenied) {
          openAppSettings();
        }
      }
      return;
    }
    if (result.errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('No se pudo abrir la galeria: ${result.errorMessage}')),
        );
      }
      return;
    }
    final file = result.file;
    if (file == null) return;
    await _uploadLogoFile(file, orgId, userId);
  }
  Future<void> _uploadLogoFile(File file, String orgId, String userId) async {
    setState(() => _isUploadingLogo = true);
    try {
      final storage = ref.read(storageServiceProvider);
      final url = await storage.uploadOrganizationLogo(
        file,
        orgId,
        userId: userId,
      );
      _orgLogoPath = url;
      final resolved =
          await storage.resolveOrgLogoUrl(url, expiresInSeconds: 3600);
      final controller = ref.read(organizationControllerProvider.notifier);
      await controller.updateOrgConfig(orgId, {'logo_url': url});
      ref.invalidate(currentOrganizationProvider);
      ref.invalidate(allOrganizationsProvider);
      if (!mounted) return;
      setState(() {
        _currentLogo = resolved;
      });
      _showSuccessModal(context, 'Logo actualizado');
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('Unauthorized')
          ? 'No hay permisos para subir logo (403). Revisa policies en backend.'
          : 'Error al subir logo: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }
  void _showSuccessModal(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.successGreen,
                  size: 40,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.backgroundDark,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Los cambios se aplicaron correctamente.',
                style: TextStyle(color: AppColors.black.withValues(alpha: 0.6)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                text: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _LogoPreview extends ConsumerWidget {
  const _LogoPreview({
    this.url,
    required this.orgName,
    required this.brandColor,
    this.size = 64,
  });
  final String? url;
  final String orgName;
  final Color brandColor;
  final double size;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (url == null || url!.isEmpty) {
      return _placeholder();
    }
    final storage = ref.read(storageServiceProvider);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: FutureBuilder<String>(
        future: storage.resolveOrgLogoUrl(url!, expiresInSeconds: 3600),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final resolved = snapshot.data ?? url!;
          return Image.network(
            resolved,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          );
        },
      ),
    );
  }
  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            brandColor.withValues(alpha: 0.8),
            brandColor.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        orgName.isNotEmpty ? orgName[0].toUpperCase() : 'C',
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
    );
  }
}
class _BrandHeader extends ConsumerWidget {
  const _BrandHeader({
    required this.orgName,
    required this.brandColor,
    required this.logoUrl,
    required this.isUploading,
    required this.onUpload,
  });
  final String orgName;
  final Color brandColor;
  final String? logoUrl;
  final bool isUploading;
  final VoidCallback? onUpload;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: brandColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          _LogoPreview(
            url: logoUrl,
            orgName: orgName,
            brandColor: brandColor,
            size: 72,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orgName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.backgroundDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Logo y color se reflejan en la app',
                  style: TextStyle(
                    color: AppColors.black.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onUpload,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: brandColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUploading
                              ? Icons.cloud_upload
                              : Icons.file_upload_outlined,
                          color: brandColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isUploading ? 'Subiendo...' : 'Actualizar logo',
                          style: TextStyle(
                            color: brandColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
