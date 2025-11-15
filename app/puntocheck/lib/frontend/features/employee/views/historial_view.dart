import 'package:flutter/material.dart';
import 'package:puntocheck/core/theme/app_colors.dart';
import 'package:puntocheck/frontend/features/shared/widgets/history_item_card.dart';

class HistorialView extends StatefulWidget {
  const HistorialView({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<HistorialView> createState() => _HistorialViewState();
}

class _HistorialViewState extends State<HistorialView> {
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final histories = [
      {
        'dayNumber': '18',
        'dayLabel': 'Sábado, 18 de Enero',
        'registros': '1 registro',
        'entrada': '08:00 AM',
        'salida': '17:45 PM',
        'total': '9h 15m',
        'estado': 'Puntual',
        'color': AppColors.successGreen,
        'ubicacion': 'Loja, Av. 18 Noviembre, Mercadillo',
      },
      {
        'dayNumber': '17',
        'dayLabel': 'Viernes, 17 de Enero',
        'registros': '1 registro',
        'entrada': '08:10 AM',
        'salida': '17:40 PM',
        'total': '9h 30m',
        'estado': 'Tarde',
        'color': AppColors.warningOrange,
        'ubicacion': 'Loja, Av. 18 Noviembre, Mercadillo',
      },
      {
        'dayNumber': '16',
        'dayLabel': 'Jueves, 16 de Enero',
        'registros': '1 registro',
        'entrada': '07:55 AM',
        'salida': '17:00 PM',
        'total': '9h 05m',
        'estado': 'Puntual',
        'color': AppColors.successGreen,
        'ubicacion': 'Loja, Av. 18 Noviembre, Mercadillo',
      },
    ];

    Widget content = ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, widget.embedded ? 100 : 16),
      children: [
        _buildMonthHeader(),
        const SizedBox(height: 18),
        _buildSummaryRow(),
        const SizedBox(height: 18),
        _buildSearchField(),
        const SizedBox(height: 12),
        _buildFilters(),
        const SizedBox(height: 8),
        for (final item in histories)
          HistoryItemCard(
            dayNumber: item['dayNumber']! as String,
            dayLabel: item['dayLabel']! as String,
            registrosLabel: item['registros']! as String,
            entrada: item['entrada']! as String,
            salida: item['salida']! as String,
            total: item['total']! as String,
            estado: item['estado']! as String,
            ubicacion: item['ubicacion']! as String,
            estadoColor: item['color']! as Color,
          ),
        const SizedBox(height: 20),
        // TODO(backend): alimentar esta lista desde una API paginada (meses/filtros).
      ],
    );

    if (widget.embedded) {
      return SafeArea(child: content);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.black),
        title: const Text(
          'Historial',
          style: TextStyle(
            color: AppColors.backgroundDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: content,
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_left)),
        Column(
          children: const [
            Text(
              'Octubre',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.backgroundDark,
              ),
            ),
            SizedBox(height: 2),
            Text('2025', style: TextStyle(color: AppColors.grey)),
          ],
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }

  Widget _buildSummaryRow() {
    Widget infoCard(String title, String value, Color color, IconData icon) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(color: AppColors.black.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        infoCard('Días', '4', AppColors.primaryRed, Icons.calendar_today),
        infoCard(
          'Puntuales',
          '3',
          AppColors.successGreen,
          Icons.verified_outlined,
        ),
        infoCard(
          'Tardanzas',
          '1',
          AppColors.warningOrange,
          Icons.error_outline,
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Buscar por ubicación o fecha...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: AppColors.lightGrey,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) {
        // TODO(backend): conectar con filtro real de historial.
      },
    );
  }

  Widget _buildFilters() {
    final filters = ['Todos', 'Puntuales', 'Tardanzas'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(filters.length, (index) {
        final bool isSelected = _selectedFilter == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == filters.length - 1 ? 0 : 8,
            ),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryRed
                      : AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  filters[index],
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.white
                        : AppColors.black.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

