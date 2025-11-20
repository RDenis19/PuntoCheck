import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/presentation/shared/widgets/notice_card.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';

class AnunciosAdminView extends StatefulWidget {
  const AnunciosAdminView({super.key});

  @override
  State<AnunciosAdminView> createState() => _AnunciosAdminViewState();
}

class _AnunciosAdminViewState extends State<AnunciosAdminView> {
  final List<Map<String, Object>> _anuncios = [
    {
      'titulo': 'Feriado - Salida Anticipada',
      'descripcion': 'Por motivo del feriado de mañana...',
      'fecha': 'Hoy · 9:15 AM',
      'color': AppColors.primaryRed,
      'detalle': 'Detalle completo del anuncio 1',
      'unread': true,
    },
    {
      'titulo': 'Reunión General de Equipo',
      'descripcion': 'Se convoca reunión este viernes',
      'fecha': 'Hoy · 8:30 AM',
      'color': AppColors.infoBlue,
      'detalle': 'Detalle completo del anuncio 2',
      'unread': false,
    },
    {
      'titulo': 'Cumpleaños del Mes',
      'descripcion': '¡Celebremos los cumpleaños!',
      'fecha': 'Ayer · 2:00 PM',
      'color': AppColors.successGreen,
      'detalle': 'Detalle completo del anuncio 3',
      'unread': false,
    },
  ];

  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anuncios'),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
        actions: [
          IconButton(
            onPressed: _selected.isEmpty
                ? null
                : () {
                    setState(() {
                      _selected.toList()..sort((a, b) => b.compareTo(a));
                      for (final index
                          in _selected.toList()
                            ..sort((a, b) => b.compareTo(a))) {
                        _anuncios.removeAt(index);
                      }
                      _selected.clear();
                    });
                    // TODO(backend): eliminar los anuncios seleccionados desde el backend.
                  },
            icon: Icon(
              Icons.delete_outline,
              color: _selected.isEmpty ? AppColors.grey : AppColors.primaryRed,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _anuncios.length,
                itemBuilder: (context, index) {
                  final anuncio = _anuncios[index];
                  return Stack(
                    children: [
                      NoticeCard(
                        titulo: anuncio['titulo']! as String,
                        descripcionCorta: anuncio['descripcion']! as String,
                        fechaTexto: anuncio['fecha']! as String,
                        color: anuncio['color']! as Color,
                        unread: anuncio['unread']! as bool,
                        onTap: () {
                          // TODO(backend): mostrar detalle completo del anuncio desde backend.
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(anuncio['detalle']! as String),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        right: 24,
                        top: 20,
                        child: Checkbox(
                          value: _selected.contains(index),
                          onChanged: (_) {
                            setState(() {
                              if (_selected.contains(index)) {
                                _selected.remove(index);
                              } else {
                                _selected.add(index);
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: PrimaryButton(
                text: 'Nuevo Anuncio',
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.adminNuevoAnuncio),
              ),
            ),
            // TODO(backend): sincronizar anuncios con la API (crear/editar/eliminar).
          ],
        ),
      ),
    );
  }
}


