import 'package:flutter/material.dart';
import 'package:puntocheck/core/theme/app_colors.dart';
import 'package:puntocheck/frontend/vistas/admin/widgets/announcement_type_chip.dart';
import 'package:puntocheck/frontend/widgets/primary_button.dart';

class NuevoAnuncioView extends StatefulWidget {
  const NuevoAnuncioView({super.key});

  @override
  State<NuevoAnuncioView> createState() => _NuevoAnuncioViewState();
}

class _NuevoAnuncioViewState extends State<NuevoAnuncioView> {
  final _tituloController = TextEditingController();
  final _mensajeController = TextEditingController();
  int _selectedType = 0;

  final _chips = ['Información', 'Aviso', 'Urgente', 'Evento'];

  @override
  void dispose() {
    _tituloController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Anuncio'),
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
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  AppColors.backgroundDark,
                  AppColors.black.withValues(alpha: 0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Comunicados Importantes',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Envíe avisos a todos los empleados.',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              _chips.length,
              (index) => AnnouncementTypeChip(
                label: _chips[index],
                selected: _selectedType == index,
                onTap: () => setState(() => _selectedType = index),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildLabeledField(
            label: 'Título del anuncio',
            child: TextField(
              controller: _tituloController,
              maxLength: 60,
              decoration: _inputDecoration(
                'Ej: Reunión general, Cambio de horario…',
              ),
              onChanged: (_) => setState(() {}),
            ),
            counter: '${_tituloController.text.length}/60',
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Mensaje',
            child: TextField(
              controller: _mensajeController,
              maxLength: 300,
              maxLines: 6,
              decoration: _inputDecoration(
                'Escribe el mensaje para los empleados',
              ),
              onChanged: (_) => setState(() {}),
            ),
            counter: '${_mensajeController.text.length}/300',
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Publicar',
            onPressed: () {
              // TODO(backend): enviar anuncio al backend para distribuirlo a los empleados.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Anuncio publicado (mock).')),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required Widget child,
    required String counter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.backgroundDark,
          ),
        ),
        const SizedBox(height: 8),
        child,
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            counter,
            style: TextStyle(
              color: AppColors.black.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: AppColors.black.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: AppColors.black.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.primaryRed),
      ),
      counterText: '',
    );
  }
}
