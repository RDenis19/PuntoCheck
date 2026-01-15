import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:puntocheck/presentation/common/widgets/confirm_dialog.dart';
import 'package:puntocheck/utils/device_identity.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class DeviceSetupView extends StatefulWidget {
  const DeviceSetupView({super.key});

  @override
  State<DeviceSetupView> createState() => _DeviceSetupViewState();
}

class _DeviceSetupViewState extends State<DeviceSetupView> {
  bool _loading = true;
  bool _saving = false;
  late final TextEditingController _idCtrl;
  DeviceIdentity? _identity;

  @override
  void initState() {
    super.initState();
    _idCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final identity = await getDeviceIdentity();
      final currentId = await readAppDeviceId() ?? identity.id;
      if (!mounted) return;
      setState(() {
        _identity = identity;
        _idCtrl.text = currentId;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final identity = _identity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar dispositivo'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                children: [
                  const Text(
                    'Idea clave',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.neutral900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Este Device ID lo genera y guarda PuntoCheck en este dispositivo. '
                    'No es IMEI. Si amarras una sucursal a este ID, solo este equipo '
                    'debería poder usar el QR fijo de esa sucursal.',
                    style: TextStyle(color: AppColors.neutral700),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Device ID (PuntoCheck)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutral900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _idCtrl,
                          enabled: !_saving,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.phonelink_setup_outlined),
                            hintText: 'Ej: UTPL-RECEP-01 o un UUID',
                            helperText:
                                'Usa letras/números y guiones. Debe ser único por tablet.',
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _saving
                                    ? null
                                    : () async {
                                        final id = _idCtrl.text.trim();
                                        if (id.isEmpty) return;
                                        await Clipboard.setData(
                                          ClipboardData(text: id),
                                        );
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Device ID copiado'),
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.copy_rounded),
                                label: const Text('Copiar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryRed,
                                  foregroundColor: Colors.white,
                                ),
                                icon: _saving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.save,
                                        color: Colors.white,
                                      ),
                                label: Text(
                                  _saving ? 'Guardando...' : 'Guardar',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (identity != null)
                    Text(
                      'Equipo: ${identity.model} (${identity.platform})',
                      style: const TextStyle(color: AppColors.neutral600),
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _resetToNewUuid,
                    icon: const Icon(Icons.autorenew_rounded),
                    label: const Text('Generar nuevo ID (avanzado)'),
                  ),
                ],
              ),
      ),
    );
  }
  Future<void> _save() async {
    final id = _idCtrl.text.trim();
    final normalized = id.toUpperCase();

    if (normalized.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El Device ID no puede estar vacio')),
      );
      return;
    }

    if (!isValidAppDeviceId(normalized)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Formato invalido. Usa letras, numeros, guion y guion bajo.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await setAppDeviceId(normalized);
      final refreshed = await getDeviceIdentity();
      if (!mounted) return;
      setState(() => _identity = refreshed);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Device ID actualizado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetToNewUuid() async {
    final confirm = await showConfirmDialog(
      context: context,
      title: 'Generar nuevo Device ID',
      message:
          'Esto cambia el ID de este dispositivo. Si ya esta vinculado a una sucursal, '
          'tendras que copiar el nuevo ID y actualizar la sucursal.',
      confirmText: 'Generar',
      cancelText: 'Cancelar',
      isDestructive: true,
    );
    if (!confirm || !mounted) return;

    setState(() => _saving = true);
    try {
      final newId = await resetAppDeviceId();
      final refreshed = await getDeviceIdentity();
      if (!mounted) return;
      setState(() {
        _idCtrl.text = newId;
        _identity = refreshed;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nuevo Device ID generado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo generar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
