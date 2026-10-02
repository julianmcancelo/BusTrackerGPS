import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:printing/printing.dart';

import '../../public_transit/data/models/transit_models.dart';
import '../services/cartographic_pdf_service.dart';
import '../services/map_tile_composer.dart';

class CartographicExportDialog extends StatefulWidget {
  final CartographicRouteData? routeData;
  final List<CartographicRouteData>? branchesData;
  final String? lineNumber;
  final String? lineName;
  final int? initialSelectedBranchIndex;
  final TransitDirectionFilter initialDirectionFilter;

  const CartographicExportDialog({
    super.key,
    this.routeData,
    this.branchesData,
    this.lineNumber,
    this.lineName,
    this.initialSelectedBranchIndex,
    this.initialDirectionFilter = TransitDirectionFilter.both,
  }) : assert(routeData != null || branchesData != null, 'routeData o branchesData deben ser provistos');

  /// Muestra el diálogo para una única traza o recorrido individual (compatibilidad total)
  static Future<void> show(
    BuildContext context, {
    required CartographicRouteData routeData,
    TransitDirectionFilter initialDirectionFilter = TransitDirectionFilter.both,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CartographicExportDialog(
        routeData: routeData,
        initialDirectionFilter: initialDirectionFilter,
      ),
    );
  }

  /// Muestra el diálogo permitiendo elegir entre múltiples ramales
  static Future<void> showMultiBranch(
    BuildContext context, {
    required List<CartographicRouteData> branchesData,
    String? lineNumber,
    String? lineName,
    int? initialSelectedBranchIndex,
    TransitDirectionFilter initialDirectionFilter = TransitDirectionFilter.both,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CartographicExportDialog(
        branchesData: branchesData,
        lineNumber: lineNumber,
        lineName: lineName,
        initialSelectedBranchIndex: initialSelectedBranchIndex,
        initialDirectionFilter: initialDirectionFilter,
      ),
    );
  }

  /// Conveniente para abrir el diálogo directamente desde cualquier pantalla de transporte público
  static Future<void> showLine(
    BuildContext context, {
    required TransitLineSummary line,
    TransitBranchSummary? initialBranch,
    TransitDirectionFilter directionFilter = TransitDirectionFilter.both,
  }) {
    final branchesData = <CartographicRouteData>[];
    int? initialIndex;

    for (int i = 0; i < line.branches.length; i++) {
      final b = line.branches[i];
      if (initialBranch != null && b.branch.id == initialBranch.branch.id) {
        initialIndex = i;
      }
      var idaPts = List<LatLng>.from(b.idaPoints);
      var vueltaPts = List<LatLng>.from(b.vueltaPoints);
      var idaKm = b.idaDistanceKm;
      var vueltaKm = b.vueltaDistanceKm;

      // Si una rama solo tiene registrada una dirección en BD, deducir la contraria para permitir ver ambos sentidos
      if (idaPts.isEmpty && vueltaPts.isNotEmpty) {
        idaPts = vueltaPts.reversed.toList();
        idaKm = vueltaKm;
      } else if (vueltaPts.isEmpty && idaPts.isNotEmpty) {
        vueltaPts = idaPts.reversed.toList();
        vueltaKm = idaKm;
      }

      final distKm = (idaKm + vueltaKm) > 0
          ? (idaKm + vueltaKm)
          : ((idaPts.length + vueltaPts.length) * 0.05);

      branchesData.add(
        CartographicRouteData(
          lineNumber: line.number,
          lineName: line.name,
          branchName: b.branch.name,
          direction: 'AMBOS',
          polylinePoints: [...idaPts, ...vueltaPts],
          idaPoints: idaPts,
          vueltaPoints: vueltaPts,
          stopPoints: const [],
          distanceKm: distKm,
          idaDistanceKm: idaKm,
          vueltaDistanceKm: vueltaKm,
          date: DateTime.now(),
          routeNotes: 'Red de Transporte Público Oficial · Municipio de Lanús',
        ),
      );
    }

    if (branchesData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta línea no posee ramales con recorrido registrado.')),
      );
      return Future.value();
    }

    return showMultiBranch(
      context,
      branchesData: branchesData,
      lineNumber: line.number,
      lineName: line.name,
      initialSelectedBranchIndex: initialIndex,
      initialDirectionFilter: directionFilter,
    );
  }

  @override
  State<CartographicExportDialog> createState() => _CartographicExportDialogState();
}

class _CartographicExportDialogState extends State<CartographicExportDialog> {
  CartographicSheetFormat _selectedFormat = CartographicSheetFormat.a3;
  MapboxStyle _selectedMapboxStyle = MapboxStyle.streetsColor;
  bool _isLandscape = true;
  bool _includeBasemap = true;
  bool _includeLanusBoundary = true;
  bool _includeOperationalMetrics = true;
  bool _includeStops = true;
  bool _isExporting = false;
  String? _exportProgressMessage;

  late TransitDirectionFilter _selectedDirection;
  late List<CartographicRouteData> _allBranches;
  late Set<int> _selectedIndices;
  MultiBranchExportMode _exportMode = MultiBranchExportMode.multiPageBooklet;

  @override
  void initState() {
    super.initState();
    _selectedDirection = widget.initialDirectionFilter;
    if (widget.branchesData != null && widget.branchesData!.isNotEmpty) {
      _allBranches = widget.branchesData!;
      // Si se especificó un ramal inicial, seleccionamos todos por defecto pero aseguramos foco
      _selectedIndices = List.generate(_allBranches.length, (i) => i).toSet();
    } else {
      var rd = widget.routeData!;
      if (rd.idaPoints.isEmpty && rd.vueltaPoints.isEmpty && rd.polylinePoints.isNotEmpty) {
        final halfKm = rd.distanceKm > 0 ? (rd.distanceKm / 2) : 0.0;
        rd = CartographicRouteData(
          lineNumber: rd.lineNumber,
          lineName: rd.lineName,
          branchName: rd.branchName,
          direction: 'AMBOS',
          polylinePoints: rd.polylinePoints,
          idaPoints: rd.polylinePoints,
          vueltaPoints: rd.polylinePoints.reversed.toList(),
          stopPoints: rd.stopPoints,
          distanceKm: rd.distanceKm,
          idaDistanceKm: rd.idaDistanceKm ?? halfKm,
          vueltaDistanceKm: rd.vueltaDistanceKm ?? halfKm,
          idaStreets: rd.idaStreets,
          vueltaStreets: rd.vueltaStreets,
          inspectorName: rd.inspectorName,
          internalNumber: rd.internalNumber,
          domain: rd.domain,
          date: rd.date,
          routeNotes: rd.routeNotes,
        );
      }
      _allBranches = [rd];
      _selectedIndices = {0};
    }
  }

  List<CartographicRouteData> get _effectiveSelectedBranches {
    return _selectedIndices.map((i) {
      final raw = _allBranches[i];
      switch (_selectedDirection) {
        case TransitDirectionFilter.both:
          return raw;
        case TransitDirectionFilter.ida:
          final pts = raw.idaPoints.isNotEmpty ? raw.idaPoints : raw.polylinePoints;
          final dist = raw.effectiveIdaDistanceKm;
          return CartographicRouteData(
            lineNumber: raw.lineNumber,
            lineName: raw.lineName,
            branchName: raw.branchName,
            direction: 'IDA',
            polylinePoints: pts,
            idaPoints: pts,
            vueltaPoints: const [],
            stopPoints: raw.stopPoints,
            distanceKm: dist,
            idaDistanceKm: dist,
            vueltaDistanceKm: 0.0,
            idaStreets: raw.idaStreets,
            vueltaStreets: const [],
            inspectorName: raw.inspectorName,
            internalNumber: raw.internalNumber,
            domain: raw.domain,
            date: raw.date,
            routeNotes: raw.routeNotes,
          );
        case TransitDirectionFilter.vuelta:
          final pts = raw.vueltaPoints.isNotEmpty
              ? raw.vueltaPoints
              : (raw.idaPoints.isNotEmpty ? raw.idaPoints.reversed.toList() : raw.polylinePoints.reversed.toList());
          final dist = raw.effectiveVueltaDistanceKm > 0 ? raw.effectiveVueltaDistanceKm : raw.effectiveIdaDistanceKm;
          return CartographicRouteData(
            lineNumber: raw.lineNumber,
            lineName: raw.lineName,
            branchName: raw.branchName,
            direction: 'VUELTA',
            polylinePoints: pts,
            idaPoints: const [],
            vueltaPoints: pts,
            stopPoints: raw.stopPoints,
            distanceKm: dist,
            idaDistanceKm: 0.0,
            vueltaDistanceKm: dist,
            idaStreets: const [],
            vueltaStreets: raw.vueltaStreets,
            inspectorName: raw.inspectorName,
            internalNumber: raw.internalNumber,
            domain: raw.domain,
            date: raw.date,
            routeNotes: raw.routeNotes,
          );
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const granate = Color(0xFF7B1828);
    const azulArq = Color(0xFF0F172A);
    const celeste = Color(0xFF00AEEF);

    final lineNum = widget.lineNumber ?? _allBranches.first.lineNumber;
    final lineName = widget.lineName ?? _allBranches.first.lineName;
    final hasMultiple = _allBranches.length > 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header con logotipo oficial y títulos de Planificación Urbana
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: celeste, width: 2),
                    ),
                    padding: const EdgeInsets.all(5),
                    child: Image.asset(
                      'assets/images/lanus_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.architecture, color: celeste, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MUNICIPIO DE LANÚS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: azulArq,
                          ),
                        ),
                        const Text(
                          'Subsecretaría de Planificación Urbana',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: granate,
                          ),
                        ),
                        Text(
                          'Dirección Gral. de Movilidad y Transporte',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Ficha de Línea
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: azulArq,
                      child: Text(
                        lineNum,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Línea $lineNum · $lineName',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasMultiple
                                ? '${_allBranches.length} ramales disponibles · ${_selectedIndices.length} seleccionados · Sentido: ${_selectedDirection.label}'
                                : 'Ramal ${_allBranches.first.branchName} · ${_allBranches.first.distanceKm.toStringAsFixed(1)} km · Sentido: ${_selectedDirection.label}',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Selector de Ramales (Si hay más de 1 ramal)
              if (hasMultiple) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SELECCIÓN DE RAMALES',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          icon: const Icon(Icons.select_all, size: 16),
                          label: const Text('TODOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            setState(() {
                              _selectedIndices = List.generate(_allBranches.length, (i) => i).toSet();
                            });
                          },
                        ),
                        if (widget.initialSelectedBranchIndex != null)
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: const Text('SOLO ESTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              setState(() {
                                _selectedIndices = {widget.initialSelectedBranchIndex!};
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(_allBranches.length, (i) {
                    final b = _allBranches[i];
                    final isSelected = _selectedIndices.contains(i);
                    final col = CartographicPdfService.multiBranchPalette[i % CartographicPdfService.multiBranchPalette.length];
                    final chipBorderColor = Color(col.toInt());

                    return FilterChip(
                      avatar: CircleAvatar(
                        radius: 6,
                        backgroundColor: chipBorderColor,
                      ),
                      label: Text(
                        '${b.branchName} (${b.distanceKm.toStringAsFixed(1)} km)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: azulArq,
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.grey.shade100,
                      side: BorderSide(
                        color: isSelected ? azulArq : Colors.grey.shade300,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedIndices.add(i);
                          } else {
                            if (_selectedIndices.length > 1) {
                              _selectedIndices.remove(i);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Debe seleccionar al menos un ramal.'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          }
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 14),

                // Formato de Entrega (Multi-página vs Lámina Consolidada)
                if (_selectedIndices.length > 1) ...[
                  const Text(
                    'MODALIDAD DE ENTREGA MULTI-RAMAL',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 6),
                  SegmentedButton<MultiBranchExportMode>(
                    segments: [
                      ButtonSegment(
                        value: MultiBranchExportMode.multiPageBooklet,
                        icon: const Icon(Icons.auto_stories_outlined, size: 16),
                        label: Text('Cuadernillo (${_selectedIndices.length} Págs)', style: const TextStyle(fontSize: 11)),
                      ),
                      const ButtonSegment(
                        value: MultiBranchExportMode.singleConsolidatedSheet,
                        icon: Icon(Icons.layers_outlined, size: 16),
                        label: Text('Plano Consolidado (1 Lámina)', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                    selected: {_exportMode},
                    onSelectionChanged: (val) => setState(() => _exportMode = val.first),
                  ),
                  const SizedBox(height: 14),
                ],
              ],

              // 3.5 Selector de Sentido del Recorrido (Ida, Vuelta, Ambos)
              const Text(
                'SENTIDO DEL RECORRIDO',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 6),
              SegmentedButton<TransitDirectionFilter>(
                segments: const [
                  ButtonSegment(
                    value: TransitDirectionFilter.both,
                    icon: Icon(Icons.sync_alt, size: 16),
                    label: Text('Ambos (Ida y Vuelta)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ),
                  ButtonSegment(
                    value: TransitDirectionFilter.ida,
                    icon: Icon(Icons.arrow_forward, size: 16),
                    label: Text('Solo Ida', style: TextStyle(fontSize: 11.5)),
                  ),
                  ButtonSegment(
                    value: TransitDirectionFilter.vuelta,
                    icon: Icon(Icons.arrow_back, size: 16),
                    label: Text('Solo Vuelta', style: TextStyle(fontSize: 11.5)),
                  ),
                ],
                selected: {_selectedDirection},
                onSelectionChanged: (val) => setState(() => _selectedDirection = val.first),
              ),
              const SizedBox(height: 14),

              // 4. Selección de Formato de Papel (A4 a A0)
              const Text(
                'TAMAÑO DE HOJA / ESCALA TÉCNICA',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CartographicSheetFormat.values.map((f) {
                  final isSelected = _selectedFormat == f;
                  final isPlotter = f == CartographicSheetFormat.a0 || f == CartographicSheetFormat.a1;
                  return ChoiceChip(
                    label: Text(
                      '${f.name.toUpperCase()} ${isPlotter ? "★ Plotter" : ""}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: azulArq,
                    backgroundColor: Colors.grey.shade100,
                    onSelected: (val) {
                      if (val) setState(() => _selectedFormat = f);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // 5. Estilo de Mapa Mapbox y Orientación
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ESTILO CARTOGRÁFICO MAPBOX',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<MapboxStyle>(
                          initialValue: _selectedMapboxStyle,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: MapboxStyle.streetsColor,
                              child: Text('Mapbox Streets (Callejero Completo con Calles)', style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: MapboxStyle.outdoors,
                              child: Text('Mapbox Outdoors (Calles y Topografía)', style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: MapboxStyle.lightArchitectural,
                              child: Text('Mapbox Light (Plano Blanco y Gris)', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedMapboxStyle = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ORIENTACIÓN',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        ),
                        const SizedBox(height: 6),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: true, label: Text('Horizontal', style: TextStyle(fontSize: 11))),
                            ButtonSegment(value: false, label: Text('Vertical', style: TextStyle(fontSize: 11))),
                          ],
                          selected: {_isLandscape},
                          onSelectionChanged: (val) => setState(() => _isLandscape = val.first),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 6. Capas y Elementos del Plano (Toggles interactivos)
              const Text(
                'CAPAS Y ELEMENTOS DEL PLANO',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 4),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Límite del Partido de Lanús', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                subtitle: const Text('Demarcación perimetral oficial del municipio en plano', style: TextStyle(fontSize: 11)),
                value: _includeLanusBoundary,
                activeThumbColor: granate,
                onChanged: (val) => setState(() => _includeLanusBoundary = val),
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Frecuencias y tiempos de viaje', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                subtitle: const Text('Muestra cómputo de ciclo y frecuencias en carátula técnica', style: TextStyle(fontSize: 11)),
                value: _includeOperationalMetrics,
                activeThumbColor: azulArq,
                onChanged: (val) => setState(() => _includeOperationalMetrics = val),
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Paradas registradas', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                subtitle: const Text('Muestra puntos de parada en mapa y cómputo técnico', style: TextStyle(fontSize: 11)),
                value: _includeStops,
                activeThumbColor: azulArq,
                onChanged: (val) => setState(() => _includeStops = val),
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Fondo cartográfico Mapbox HD', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                subtitle: const Text('Descarga teselas HD para contexto de calles y arquitectura urbana', style: TextStyle(fontSize: 11)),
                value: _includeBasemap,
                activeThumbColor: azulArq,
                onChanged: (val) => setState(() => _includeBasemap = val),
              ),

              // Indicador de Progreso
              if (_isExporting) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(color: azulArq, backgroundColor: Colors.grey.shade200),
                const SizedBox(height: 6),
                Text(
                  _exportProgressMessage ?? 'Procesando láminas cartográficas...',
                  style: const TextStyle(fontSize: 11.5, color: granate, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 16),

              // 7. Botones de Acción
              Row(
                children: [
                  // Compartir archivo PDF
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: azulArq),
                        foregroundColor: azulArq,
                      ),
                      icon: _isExporting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: azulArq))
                          : const Icon(Icons.share_outlined, size: 20),
                      label: const Text('COMPARTIR PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: (_isExporting || _selectedIndices.isEmpty) ? null : _handleShare,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Previsualizar e Imprimir
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: azulArq,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.print, size: 20),
                      label: const Text('IMPRIMIR / VISTA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: (_isExporting || _selectedIndices.isEmpty) ? null : _handlePrint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleShare() async {
    setState(() {
      _isExporting = true;
      _exportProgressMessage = 'Iniciando generación de plano...';
    });

    final selected = _effectiveSelectedBranches;
    try {
      if (selected.length == 1) {
        await CartographicPdfService.exportAndShare(
          data: selected.first,
          format: _selectedFormat,
          isLandscape: _isLandscape,
          includeBasemap: _includeBasemap,
          mapboxStyle: _selectedMapboxStyle,
          includeStops: _includeStops,
          includeOperationalMetrics: _includeOperationalMetrics,
          includeLanusBoundary: _includeLanusBoundary,
        );
      } else {
        await CartographicPdfService.exportAndShareMultiBranch(
          branchesData: selected,
          format: _selectedFormat,
          isLandscape: _isLandscape,
          includeBasemap: _includeBasemap,
          mapboxStyle: _selectedMapboxStyle,
          mode: _exportMode,
          includeStops: _includeStops,
          includeOperationalMetrics: _includeOperationalMetrics,
          includeLanusBoundary: _includeLanusBoundary,
          onProgress: (current, total, status) {
            if (mounted) {
              setState(() => _exportProgressMessage = '$status ($current/$total)');
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar lámina: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handlePrint() async {
    final nav = Navigator.of(context);
    nav.pop();

    final selected = _effectiveSelectedBranches;
    final lineNum = widget.lineNumber ?? selected.first.lineNumber;
    final titleSuffix = selected.length > 1
        ? (_exportMode == MultiBranchExportMode.multiPageBooklet ? 'Cuadernillo' : 'RedConsolidada')
        : selected.first.branchName;

    await Printing.layoutPdf(
      name: 'Plano_${lineNum}_${titleSuffix}_${_selectedFormat.name.toUpperCase()}.pdf',
      onLayout: (pageFormat) async {
        if (selected.length == 1) {
          return CartographicPdfService.generateSheetBytes(
            data: selected.first,
            format: _selectedFormat,
            isLandscape: _isLandscape,
            includeBasemap: _includeBasemap,
            mapboxStyle: _selectedMapboxStyle,
            includeStops: _includeStops,
            includeOperationalMetrics: _includeOperationalMetrics,
            includeLanusBoundary: _includeLanusBoundary,
          );
        } else {
          return CartographicPdfService.generateMultiBranchBytes(
            branchesData: selected,
            format: _selectedFormat,
            isLandscape: _isLandscape,
            includeBasemap: _includeBasemap,
            mapboxStyle: _selectedMapboxStyle,
            mode: _exportMode,
            includeStops: _includeStops,
            includeOperationalMetrics: _includeOperationalMetrics,
            includeLanusBoundary: _includeLanusBoundary,
          );
        }
      },
    );
  }
}
