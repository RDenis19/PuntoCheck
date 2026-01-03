import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/utils/device_identity.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrgAdminBranchForm extends StatefulWidget {
  final Sucursales initial;
  final bool isSaving;
  final Future<void> Function(Sucursales branch) onSubmit;

  const OrgAdminBranchForm({
    super.key,
    required this.initial,
    required this.isSaving,
    required this.onSubmit,
  });

  @override
  State<OrgAdminBranchForm> createState() => _OrgAdminBranchFormState();
}

class _OrgAdminBranchFormState extends State<OrgAdminBranchForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lonCtrl;
  late TextEditingController _radioCtrl;
  late TextEditingController _deviceIdCtrl;
  bool _qrEnabled = true;
  bool _loadingDeviceId = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial.nombre);
    _addressCtrl = TextEditingController(text: widget.initial.direccion ?? '');
    final coords = _extractLonLat(widget.initial.ubicacionCentral);
    final lat = coords?[1];
    final lon = coords?[0];
    _latCtrl = TextEditingController(text: lat?.toStringAsFixed(6) ?? '');
    _lonCtrl = TextEditingController(text: lon?.toStringAsFixed(6) ?? '');
    _radioCtrl = TextEditingController(
      text: (widget.initial.radioMetros ?? 100).toString(),
    );
    _qrEnabled = widget.initial.tieneQrHabilitado ?? false;
    _deviceIdCtrl = TextEditingController(
      text: widget.initial.deviceIdQrAsignado ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _radioCtrl.dispose();
    _deviceIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalles',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.neutral900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.store_mall_directory_outlined),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Nombre requerido' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _addressCtrl,
            decoration: const InputDecoration(
              labelText: 'Direccion',
              prefixIcon: Icon(Icons.place_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Latitud',
                    prefixIcon: Icon(Icons.my_location_rounded),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _lonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Longitud',
                    prefixIcon: Icon(Icons.my_location_rounded),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _radioCtrl,
            decoration: const InputDecoration(
              labelText: 'Radio (m)',
              prefixIcon: Icon(Icons.radar_rounded),
            ),
            keyboardType: TextInputType.number,
            validator: (v) => v == null || v.isEmpty ? 'Radio requerido' : null,
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Habilitar QR'),
            value: _qrEnabled,
            onChanged: (v) => setState(() => _qrEnabled = v),
          ),
          if (_qrEnabled) ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: _deviceIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Device ID (PuntoCheck) asignado (opcional)',
                prefixIcon: Icon(Icons.phone_android_rounded),
                helperText:
                    'Es un ID generado por la app (no es IMEI). Si lo asignas, puedes amarrar el QR fijo a un equipo especifico.',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.isSaving || _loadingDeviceId
                        ? null
                        : _fillWithMyDeviceId,
                    icon: _loadingDeviceId
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.smartphone_rounded),
                    label: const Text('Usar mi Device ID'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Copiar',
                  onPressed: _deviceIdCtrl.text.trim().isEmpty
                      ? null
                      : () async {
                           await Clipboard.setData(
                             ClipboardData(text: _deviceIdCtrl.text.trim()),
                           );
                           if (!context.mounted) return;
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Device ID copiado')),
                           );
                         },
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.isSaving
                      ? null
                      : () => Navigator.of(context).maybePop(false),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded, color: Colors.white),
                  onPressed: widget.isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                  ),
                  label: Text(widget.isSaving ? 'Guardando...' : 'Guardar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final lat = double.tryParse(_latCtrl.text);
    final lon = double.tryParse(_lonCtrl.text);
    final radio = int.tryParse(_radioCtrl.text);
    final deviceId = _deviceIdCtrl.text.trim().isEmpty
        ? null
        : _deviceIdCtrl.text.trim();

    final updated = Sucursales(
      id: widget.initial.id,
      organizacionId: widget.initial.organizacionId,
      nombre: _nameCtrl.text.trim(),
      direccion: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      ubicacionCentral: (lat != null && lon != null)
          ? {
              'type': 'Point',
              'coordinates': [lon, lat],
            }
          : widget.initial.ubicacionCentral,
      radioMetros: radio ?? widget.initial.radioMetros,
      tieneQrHabilitado: _qrEnabled,
      deviceIdQrAsignado: _qrEnabled ? deviceId : null,
    );
    await widget.onSubmit(updated);
  }

  Future<void> _fillWithMyDeviceId() async {
    setState(() => _loadingDeviceId = true);
    try {
      final identity = await getDeviceIdentity();
      if (!mounted) return;
      setState(() => _deviceIdCtrl.text = identity.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Detectado: ${identity.model}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo obtener Device ID: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingDeviceId = false);
    }
  }

  List<double>? _extractLonLat(dynamic geo) {
    if (geo is Map && geo['coordinates'] is List) {
      final coords = geo['coordinates'] as List;
      if (coords.length == 2) {
        final lon = (coords[0] as num?)?.toDouble();
        final lat = (coords[1] as num?)?.toDouble();
        if (lon != null && lat != null) {
          return [lon, lat];
        }
      }
    }
    if (geo is String && geo.contains('POINT')) {
      final start = geo.indexOf('(');
      final end = geo.indexOf(')');
      if (start != -1 && end != -1 && end > start + 1) {
        final parts = geo.substring(start + 1, end).split(' ');
        if (parts.length == 2) {
          final lon = double.tryParse(parts[0]);
          final lat = double.tryParse(parts[1]);
          if (lon != null && lat != null) {
            return [lon, lat];
          }
        }
      }
    }
    return null;
  }
}
