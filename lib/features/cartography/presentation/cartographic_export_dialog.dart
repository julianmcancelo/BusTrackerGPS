import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../services/cartographic_pdf_service.dart';
import '../services/map_tile_composer.dart';

class CartographicExportDialog extends StatefulWidget {
  final CartographicRouteData routeData;

  const CartographicExportDialog({
    super.key,
    required this.routeData,
  });

  static Future<void> show(BuildContext context, {required CartographicRouteData routeData}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CartographicExportDialog(routeData: routeData),
    );
  }

  @override
  State<CartographicExportDialog> createState() => _CartographicExportDialogState();
}

class _CartographicExportDialogState extends State<CartographicExportDialog> {
  CartographicSheetFormat _selectedFormat = CartographicSheetFormat.a3;
  MapboxStyle _selectedMapboxStyle = MapboxStyle.lightArchitectural;
  bool _isLandscape = true;
  bool _includeBasemap = true;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    const granate = Color(0xFF7B1828);
    const azulArq = Color(0xFF0F172A);
    const celeste = Color(0xFF00AEEF);
    final data = widget.routeData;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
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
                      errorBuilder: (_, __, _) => const Icon(Icons.architecture, color: celeste, size: 24),
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Ficha de Línea y Recorrido
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
                        data.lineNumber,
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
                            'Línea ${data.lineNumber} · ${data.branchName}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sentido ${data.direction} · ${data.distanceKm.toStringAsFixed(2)} km · ${data.polylinePoints.length} puntos WGS-84',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Selección de Formato de Papel (A4 a A0)
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

              // 4. Estilo de Mapa Mapbox y Orientación
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
                              value: MapboxStyle.lightArchitectural,
                              child: Text('Mapbox Light (Arquitectónico)', style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: MapboxStyle.streetsColor,
                              child: Text('Mapbox Streets (Callejero Color)', style: TextStyle(fontSize: 12)),
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
              const SizedBox(height: 12),

              // Toggle fondo callejero Mapbox
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Renderizar fondo cartográfico Mapbox', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Descarga teselas HD para contexto de calles y arquitectura urbana', style: TextStyle(fontSize: 11)),
                value: _includeBasemap,
                activeThumbColor: azulArq,
                onChanged: (val) => setState(() => _includeBasemap = val),
              ),
              const SizedBox(height: 18),

              // 5. Botones de Acción
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
                      onPressed: _isExporting ? null : _handleShare,
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
                      onPressed: _isExporting ? null : _handlePrint,
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
    setState(() => _isExporting = true);
    try {
      await CartographicPdfService.exportAndShare(
        data: widget.routeData,
        format: _selectedFormat,
        isLandscape: _isLandscape,
        includeBasemap: _includeBasemap,
        mapboxStyle: _selectedMapboxStyle,
      );
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

    await Printing.layoutPdf(
      name: 'Plano_${widget.routeData.lineNumber}_${_selectedFormat.name.toUpperCase()}.pdf',
      onLayout: (pageFormat) async {
        return CartographicPdfService.generateSheetBytes(
          data: widget.routeData,
          format: _selectedFormat,
          isLandscape: _isLandscape,
          includeBasemap: _includeBasemap,
          mapboxStyle: _selectedMapboxStyle,
        );
      },
    );
  }
}
