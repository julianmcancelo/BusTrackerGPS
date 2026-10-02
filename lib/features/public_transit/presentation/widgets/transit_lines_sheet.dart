import 'package:flutter/material.dart';
import '../../data/models/transit_models.dart';
import '../../../../core/utils/transport_utils.dart';
import '../../../cartography/presentation/cartographic_export_dialog.dart';

/// Modal interactivo para explorar, buscar y gestionar la visibilidad de todas las líneas de transporte.
class TransitLinesSheet extends StatefulWidget {
  final List<TransitLineSummary> lines;
  final Set<int> enabledLineIds;
  final int? focusedLineId;
  final ValueChanged<int> onLineToggled;
  final ValueChanged<int> onLineFocused;
  final VoidCallback onShowAll;
  final VoidCallback onHideAll;
  final VoidCallback? onActivateNational;

  const TransitLinesSheet({
    super.key,
    required this.lines,
    required this.enabledLineIds,
    required this.focusedLineId,
    required this.onLineToggled,
    required this.onLineFocused,
    required this.onShowAll,
    required this.onHideAll,
    this.onActivateNational,
  });

  static Future<void> show(
    BuildContext context, {
    required List<TransitLineSummary> lines,
    required Set<int> enabledLineIds,
    required int? focusedLineId,
    required ValueChanged<int> onLineToggled,
    required ValueChanged<int> onLineFocused,
    required VoidCallback onShowAll,
    required VoidCallback onHideAll,
    VoidCallback? onActivateNational,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransitLinesSheet(
        lines: lines,
        enabledLineIds: enabledLineIds,
        focusedLineId: focusedLineId,
        onLineToggled: onLineToggled,
        onLineFocused: onLineFocused,
        onShowAll: onShowAll,
        onHideAll: onHideAll,
        onActivateNational: onActivateNational,
      ),
    );
  }

  @override
  State<TransitLinesSheet> createState() => _TransitLinesSheetState();
}

class _TransitLinesSheetState extends State<TransitLinesSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filterQuery = '';
  _LineCategoryFilter _category = _LineCategoryFilter.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<TransitLineSummary> get _filteredList {
    var list = widget.lines;

    // Filtro por categoría de jurisdicción
    if (_category == _LineCategoryFilter.national) {
      list = list.where((l) => TransportUtils.isNationalLine(l.number)).toList();
    } else if (_category == _LineCategoryFilter.municipal) {
      list = list.where((l) => TransportUtils.isMunicipalLine(l.number)).toList();
    } else if (_category == _LineCategoryFilter.provincial) {
      list = list.where((l) => TransportUtils.isProvincialLine(l.number)).toList();
    }

    // Filtro por texto de búsqueda
    if (_filterQuery.trim().isNotEmpty) {
      final q = _filterQuery.trim().toLowerCase();
      list = list.where((l) {
        return l.number.toLowerCase().contains(q) ||
            l.name.toLowerCase().contains(q) ||
            l.branches.any((b) =>
                b.branch.name.toLowerCase().contains(q) ||
                (b.branch.description ?? '').toLowerCase().contains(q));
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final displayedLines = _filteredList;
    final totalEnabled = widget.enabledLineIds.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.40,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Barra superior de agarre (Handle)
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Encabezado
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: Color(0xFF1D4ED8),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Líneas de Transporte',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            '${widget.lines.length} líneas en red · $totalEnabled activas en mapa',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Buscador
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar número, recorrido, destino o ramal...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Colors.blueGrey),
                    suffixIcon: _filterQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _filterQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _filterQuery = val);
                  },
                ),
              ),

              // Chips de Categoría & Acciones globales
              Builder(
                builder: (context) {
                  final totalNat = widget.lines.where((l) => TransportUtils.isNationalLine(l.number)).length;
                  final totalMun = widget.lines.where((l) => TransportUtils.isMunicipalLine(l.number)).length;
                  final totalProv = widget.lines.where((l) => TransportUtils.isProvincialLine(l.number)).length;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text('Todas (${widget.lines.length})'),
                          selected: _category == _LineCategoryFilter.all,
                          onSelected: (_) => setState(() => _category = _LineCategoryFilter.all),
                          selectedColor: const Color(0xFF1D4ED8),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _category == _LineCategoryFilter.all ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: const Icon(Icons.alt_route_rounded, size: 14, color: Colors.blue),
                          label: Text('Nacionales ($totalNat)'),
                          selected: _category == _LineCategoryFilter.national,
                          onSelected: (_) => setState(() => _category = _LineCategoryFilter.national),
                          selectedColor: const Color(0xFF0284C7),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _category == _LineCategoryFilter.national ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('Municipales ($totalMun)'),
                          selected: _category == _LineCategoryFilter.municipal,
                          onSelected: (_) => setState(() => _category = _LineCategoryFilter.municipal),
                          selectedColor: const Color(0xFF1D4ED8),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _category == _LineCategoryFilter.municipal ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('Provinciales ($totalProv)'),
                          selected: _category == _LineCategoryFilter.provincial,
                          onSelected: (_) => setState(() => _category = _LineCategoryFilter.provincial),
                          selectedColor: const Color(0xFF7C3AED),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _category == _LineCategoryFilter.provincial ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (widget.onActivateNational != null) ...[
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: const Color(0xFF0284C7),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            icon: const Icon(Icons.add_road_rounded, size: 16),
                            label: const Text('+ Nacionales', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              widget.onActivateNational!();
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 6),
                        ],
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          icon: const Icon(Icons.select_all_rounded, size: 16),
                          label: const Text('Activar todas', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            widget.onShowAll();
                            setState(() {});
                          },
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          icon: const Icon(Icons.deselect_rounded, size: 16),
                          label: const Text('Ocultar todas', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            widget.onHideAll();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),

              const Divider(height: 1),

              // Lista de Líneas
              Expanded(
                child: displayedLines.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'No se encontraron líneas coincidentes',
                              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: displayedLines.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final line = displayedLines[index];
                          final isEnabled = widget.enabledLineIds.contains(line.id);
                          final isFocused = widget.focusedLineId == line.id;
                          final hasRoutes = line.hasRoutes;

                          return Material(
                            color: isFocused
                                ? line.color.withValues(alpha: 0.08)
                                : (isEnabled ? Colors.grey.shade50 : Colors.white),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                widget.onLineFocused(line.id);
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isFocused
                                        ? line.color
                                        : (isEnabled ? Colors.grey.shade300 : Colors.grey.shade200),
                                    width: isFocused ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Badge Línea
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: line.color,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: line.color.withValues(alpha: 0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        line.number,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Info Línea
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  line.name,
                                                  style: TextStyle(
                                                    fontWeight: isFocused ? FontWeight.w800 : FontWeight.w700,
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (hasRoutes)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade50,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: Colors.green.shade300, width: 0.8),
                                                  ),
                                                  child: Text(
                                                    'Traza Oficial',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.green.shade800,
                                                    ),
                                                  ),
                                                ),
                                              Builder(
                                                builder: (context) {
                                                  final isNat = TransportUtils.isNationalLine(line.number);
                                                  final isMun = TransportUtils.isMunicipalLine(line.number);
                                                  final jurLabel = TransportUtils.getJurisdictionLabel(line.number);
                                                  return Container(
                                                    margin: const EdgeInsets.only(left: 4),
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isNat
                                                          ? Colors.blue.shade50
                                                          : (isMun ? Colors.teal.shade50 : Colors.purple.shade50),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(
                                                        color: isNat
                                                            ? Colors.blue.shade300
                                                            : (isMun ? Colors.teal.shade300 : Colors.purple.shade300),
                                                        width: 0.8,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      jurLabel,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                        color: isNat
                                                            ? Colors.blue.shade800
                                                            : (isMun ? Colors.teal.shade800 : Colors.purple.shade800),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${line.branches.length} ${line.branches.length == 1 ? 'ramal' : 'ramales'}'
                                            '${line.branches.isNotEmpty ? ' · ${line.branches.map((b) => b.branch.name).take(3).join(', ')}' : ''}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.print_outlined, size: 20, color: Color(0xFF0F172A)),
                                      tooltip: 'Imprimir Plano / Cuadernillo',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        Navigator.pop(context);
                                        CartographicExportDialog.showLine(context, line: line);
                                      },
                                    ),

                                    // Switch de visibilidad en mapa
                                    Switch.adaptive(
                                      value: isEnabled,
                                      activeTrackColor: line.color.withValues(alpha: 0.5),
                                      activeThumbColor: line.color,
                                      onChanged: (_) {
                                        widget.onLineToggled(line.id);
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _LineCategoryFilter {
  all,
  national,
  municipal,
  provincial,
}
