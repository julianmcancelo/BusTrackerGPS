import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/transport_utils.dart';
import 'cartographic_projection.dart';
import 'map_tile_composer.dart';
import 'street_itinerary_service.dart';

enum CartographicSheetFormat {
  a4,
  a3,
  a2,
  a1,
  a0;

  String get label {
    switch (this) {
      case CartographicSheetFormat.a4:
        return 'A4 (210 x 297 mm)';
      case CartographicSheetFormat.a3:
        return 'A3 (297 x 420 mm)';
      case CartographicSheetFormat.a2:
        return 'A2 (420 x 594 mm)';
      case CartographicSheetFormat.a1:
        return 'A1 (594 x 841 mm)';
      case CartographicSheetFormat.a0:
        return 'A0 (841 x 1189 mm)';
    }
  }

  PdfPageFormat toPdfPageFormat({bool isLandscape = true}) {
    PdfPageFormat base;
    switch (this) {
      case CartographicSheetFormat.a4:
        base = PdfPageFormat.a4;
        break;
      case CartographicSheetFormat.a3:
        base = PdfPageFormat.a3;
        break;
      case CartographicSheetFormat.a2:
        base = const PdfPageFormat(42.0 * PdfPageFormat.cm, 59.4 * PdfPageFormat.cm);
        break;
      case CartographicSheetFormat.a1:
        base = const PdfPageFormat(59.4 * PdfPageFormat.cm, 84.1 * PdfPageFormat.cm);
        break;
      case CartographicSheetFormat.a0:
        base = const PdfPageFormat(84.1 * PdfPageFormat.cm, 118.9 * PdfPageFormat.cm);
        break;
    }
    return isLandscape ? base.landscape : base;
  }
}

class CartographicRouteData {
  final String lineNumber;
  final String lineName;
  final String branchName;
  final String direction;
  final List<LatLng> polylinePoints;
  final List<LatLng> idaPoints;
  final List<LatLng> vueltaPoints;
  final List<LatLng> stopPoints;
  final double distanceKm;
  final double? idaDistanceKm;
  final double? vueltaDistanceKm;
  final List<String> idaStreets;
  final List<String> vueltaStreets;
  final String? inspectorName;
  final String? internalNumber;
  final String? domain;
  final DateTime date;
  final String? routeNotes;

  const CartographicRouteData({
    required this.lineNumber,
    required this.lineName,
    required this.branchName,
    required this.direction,
    this.polylinePoints = const [],
    this.idaPoints = const [],
    this.vueltaPoints = const [],
    this.stopPoints = const [],
    required this.distanceKm,
    this.idaDistanceKm,
    this.vueltaDistanceKm,
    this.idaStreets = const [],
    this.vueltaStreets = const [],
    this.inspectorName,
    this.internalNumber,
    this.domain,
    required this.date,
    this.routeNotes,
  });

  List<LatLng> get effectiveIdaPoints {
    if (direction.trim().toUpperCase() == 'VUELTA') return const [];
    if (idaPoints.isNotEmpty) return idaPoints;
    if (direction.trim().toUpperCase() == 'IDA' ||
        direction.trim().toUpperCase().contains('AMBOS') ||
        direction.trim().toUpperCase().contains('TODO')) {
      return polylinePoints;
    }
    return polylinePoints;
  }

  List<LatLng> get effectiveVueltaPoints {
    if (direction.trim().toUpperCase() == 'IDA') return const [];
    if (vueltaPoints.isNotEmpty) return vueltaPoints;
    if (direction.trim().toUpperCase() == 'VUELTA') return polylinePoints;
    return const [];
  }

  List<LatLng> get allPoints {
    final list = <LatLng>[];
    list.addAll(effectiveIdaPoints);
    list.addAll(effectiveVueltaPoints);
    if (list.isEmpty) list.addAll(polylinePoints);
    return list;
  }

  bool get hasIda => effectiveIdaPoints.isNotEmpty;
  bool get hasVuelta => effectiveVueltaPoints.isNotEmpty;
}

enum MultiBranchExportMode {
  multiPageBooklet,       // 1 lámina individual por cada ramal en un único PDF
  singleConsolidatedSheet // Todos los ramales consolidados en una sola lámina de red
}

class CartographicPdfService {
  // Paleta oficial de Lanús y Arquitectura Técnica
  static const PdfColor granateLanus = PdfColor.fromInt(0xFF7B1828);
  static const PdfColor celesteLanus = PdfColor.fromInt(0xFF00AEEF);
  static const PdfColor azulArquitectura = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor grisPlano = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor grisLineaTecnica = PdfColor.fromInt(0xFF334155);
  static const PdfColor grisBordeSuave = PdfColor.fromInt(0xFFCBD5E1);

  // Paleta de contraste para diferenciar múltiples ramales en plano consolidado
  static const List<PdfColor> multiBranchPalette = [
    PdfColor.fromInt(0xFF0284C7), // Azul cielo / Ocean
    PdfColor.fromInt(0xFF16A34A), // Verde esmeralda
    PdfColor.fromInt(0xFFDC2626), // Rojo carmín
    PdfColor.fromInt(0xFFD97706), // Ámbar / Naranja
    PdfColor.fromInt(0xFF9333EA), // Violeta
    PdfColor.fromInt(0xFF0D9488), // Teal petróleo
    PdfColor.fromInt(0xFFE11D48), // Rosa intenso
    PdfColor.fromInt(0xFF4F46E5), // Índigo
  ];

  static List<LatLng>? _cachedLanusBoundary;

  /// Carga y cachea los puntos poligonales del límite oficial del Partido de Lanús desde assets/data/lanus_boundary.json
  static Future<List<LatLng>> loadLanusBoundaryPoints() async {
    if (_cachedLanusBoundary != null) return _cachedLanusBoundary!;
    try {
      String jsonStr = '';
      try {
        jsonStr = await rootBundle.loadString('assets/data/lanus_boundary.json');
      } catch (_) {
        try {
          final f = File('assets/data/lanus_boundary.json');
          if (f.existsSync()) {
            jsonStr = f.readAsStringSync();
          }
        } catch (_) {}
      }
      if (jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic> && decoded['coordinates'] is List) {
          final ring = decoded['coordinates'][0] as List;
          final pts = <LatLng>[];
          for (final coord in ring) {
            if (coord is List && coord.length >= 2) {
              final lon = (coord[0] as num).toDouble();
              final lat = (coord[1] as num).toDouble();
              pts.add(LatLng(lat, lon));
            }
          }
          if (pts.isNotEmpty) {
            _cachedLanusBoundary = pts;
            return pts;
          }
        }
      }
    } catch (_) {}
    return const [];
  }

  static Future<Uint8List?> _loadOfficialLogoBytes() async {
    try {
      final byteData = await rootBundle.load('assets/images/lanus_logo.png');
      return byteData.buffer.asUint8List();
    } catch (_) {
      try {
        final f = File('assets/images/lanus_logo.png');
        if (f.existsSync()) return f.readAsBytesSync();
      } catch (_) {}
    }
    return null;
  }

  /// Genera la lámina cartográfica oficial de arquitectura con proyección isométrica unificada.
  static Future<Uint8List> generateSheetBytes({
    required CartographicRouteData data,
    CartographicSheetFormat format = CartographicSheetFormat.a3,
    bool isLandscape = true,
    bool includeBasemap = true,
    MapboxStyle mapboxStyle = MapboxStyle.streetsColor,
    bool includeStops = true,
    bool includeOperationalMetrics = true,
    bool includeLanusBoundary = true,
  }) async {
    final pdf = pw.Document();
    final pageFormat = format.toPdfPageFormat(isLandscape: isLandscape);
    final margin = format == CartographicSheetFormat.a0 || format == CartographicSheetFormat.a1 ? 36.0 : 20.0;
    final logoBytes = await _loadOfficialLogoBytes();
    final lanusPoints = includeLanusBoundary ? await loadLanusBoundaryPoints() : const <LatLng>[];

    final page = await _buildBranchPage(
      data: data,
      format: format,
      pageFormat: pageFormat,
      margin: margin,
      includeBasemap: includeBasemap,
      mapboxStyle: mapboxStyle,
      logoBytes: logoBytes,
      lanusBoundaryPoints: lanusPoints,
      includeStops: includeStops,
      includeOperationalMetrics: includeOperationalMetrics,
      includeLanusBoundary: includeLanusBoundary,
    );

    pdf.addPage(page);
    return pdf.save();
  }

  /// Genera un documento PDF para uno, varios o todos los ramales de una línea.
  /// En modo `multiPageBooklet` genera 1 lámina independiente por cada ramal.
  /// En modo `singleConsolidatedSheet` genera una única lámina con todos los ramales integrados.
  static Future<Uint8List> generateMultiBranchBytes({
    required List<CartographicRouteData> branchesData,
    CartographicSheetFormat format = CartographicSheetFormat.a3,
    bool isLandscape = true,
    bool includeBasemap = true,
    MapboxStyle mapboxStyle = MapboxStyle.streetsColor,
    MultiBranchExportMode mode = MultiBranchExportMode.multiPageBooklet,
    bool includeStops = true,
    bool includeOperationalMetrics = true,
    bool includeLanusBoundary = true,
    void Function(int current, int total, String status)? onProgress,
  }) async {
    if (branchesData.isEmpty) {
      throw ArgumentError('branchesData no puede estar vacío');
    }
    if (branchesData.length == 1) {
      return generateSheetBytes(
        data: branchesData.first,
        format: format,
        isLandscape: isLandscape,
        includeBasemap: includeBasemap,
        mapboxStyle: mapboxStyle,
        includeStops: includeStops,
        includeOperationalMetrics: includeOperationalMetrics,
        includeLanusBoundary: includeLanusBoundary,
      );
    }

    final pdf = pw.Document();
    final pageFormat = format.toPdfPageFormat(isLandscape: isLandscape);
    final margin = format == CartographicSheetFormat.a0 || format == CartographicSheetFormat.a1 ? 36.0 : 20.0;
    final logoBytes = await _loadOfficialLogoBytes();
    final lanusPoints = includeLanusBoundary ? await loadLanusBoundaryPoints() : const <LatLng>[];

    if (mode == MultiBranchExportMode.singleConsolidatedSheet) {
      onProgress?.call(1, 1, 'Generando plano consolidado de conjunto...');
      final page = await _buildConsolidatedSheetPage(
        branchesData: branchesData,
        format: format,
        pageFormat: pageFormat,
        margin: margin,
        includeBasemap: includeBasemap,
        mapboxStyle: mapboxStyle,
        logoBytes: logoBytes,
        lanusBoundaryPoints: lanusPoints,
        includeStops: includeStops,
        includeOperationalMetrics: includeOperationalMetrics,
        includeLanusBoundary: includeLanusBoundary,
      );
      pdf.addPage(page);
    } else {
      // Cuadernillo Multi-página (1 página por ramal)
      for (var i = 0; i < branchesData.length; i++) {
        final b = branchesData[i];
        onProgress?.call(
          i + 1,
          branchesData.length,
          'Generando lámina del ${b.branchName} (${i + 1}/${branchesData.length})...',
        );
        final page = await _buildBranchPage(
          data: b,
          format: format,
          pageFormat: pageFormat,
          margin: margin,
          includeBasemap: includeBasemap,
          mapboxStyle: mapboxStyle,
          logoBytes: logoBytes,
          lanusBoundaryPoints: lanusPoints,
          includeStops: includeStops,
          includeOperationalMetrics: includeOperationalMetrics,
          includeLanusBoundary: includeLanusBoundary,
          pageNumber: i + 1,
          totalPages: branchesData.length,
        );
        pdf.addPage(page);
      }
    }

    return pdf.save();
  }

  /// Construye una página completa de lámina oficial para un ramal individual.
  static Future<pw.Page> _buildBranchPage({
    required CartographicRouteData data,
    required CartographicSheetFormat format,
    required PdfPageFormat pageFormat,
    required double margin,
    required bool includeBasemap,
    required MapboxStyle mapboxStyle,
    required Uint8List? logoBytes,
    List<LatLng> lanusBoundaryPoints = const [],
    bool includeStops = true,
    bool includeOperationalMetrics = true,
    bool includeLanusBoundary = true,
    int? pageNumber,
    int? totalPages,
  }) async {
    final allRoutePoints = data.allPoints;
    final bounds = _calculateSafeBounds(allRoutePoints);

    final pageWidth = pageFormat.width;
    final pageHeight = pageFormat.height;

    final contentWidth = pageWidth - (margin * 2);
    final contentHeight = pageHeight - (margin * 2);

    final isPlotterLarge = format == CartographicSheetFormat.a0 || format == CartographicSheetFormat.a1;
    final headerHeight = isPlotterLarge ? 90.0 : 66.0;
    final caratureHeight = isPlotterLarge ? 175.0 : 118.0;

    // Detección automática de arterias y avenidas vía OpenStreetMap si no fueron provistas
    List<String> idaStreets = data.idaStreets;
    if (idaStreets.isEmpty && data.effectiveIdaPoints.length >= 2) {
      try {
        idaStreets = await StreetItineraryService.extractStreetSequence(data.effectiveIdaPoints);
      } catch (_) {}
    }

    List<String> vueltaStreets = data.vueltaStreets;
    if (vueltaStreets.isEmpty && data.effectiveVueltaPoints.length >= 2) {
      try {
        vueltaStreets = await StreetItineraryService.extractStreetSequence(data.effectiveVueltaPoints);
      } catch (_) {}
    }

    final hasStreets = idaStreets.isNotEmpty || vueltaStreets.isNotEmpty;
    final hojaRutaHeight = hasStreets ? (isPlotterLarge ? 48.0 : 34.0) : 0.0;

    final mapWidth = contentWidth - 10.0;
    final mapHeight = contentHeight - headerHeight - caratureHeight - hojaRutaHeight - 16.0;

    final projection = MercatorViewportProjection(
      bounds: bounds,
      width: mapWidth,
      height: mapHeight,
    );

    Uint8List? basemapBytes;
    if (includeBasemap && allRoutePoints.isNotEmpty) {
      basemapBytes = await MapTileComposer.composeBasemap(
        bounds: bounds,
        targetWidthPx: (mapWidth * 2.0).toInt(),
        targetHeightPx: (mapHeight * 2.0).toInt(),
        style: mapboxStyle,
      );
    }

    final lineColorHex = TransportUtils.getLineColor(data.lineNumber).toARGB32();
    final linePdfColor = PdfColor.fromInt(lineColorHex);
    final isReddish = (linePdfColor.red > 0.65 && linePdfColor.green < 0.45);
    final vueltaPdfColor = isReddish
        ? const PdfColor(0.12, 0.45, 0.88)
        : const PdfColor(0.92, 0.40, 0.08);

    return pw.Page(
      pageFormat: pageFormat,
      margin: pw.EdgeInsets.all(margin),
      build: (pw.Context context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: azulArquitectura, width: 2.0),
            color: PdfColors.white,
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: grisLineaTecnica, width: 0.8),
              ),
              child: pw.Column(
                children: [
                  _buildInstitutionalHeader(
                    data,
                    format,
                    headerHeight,
                    logoBytes,
                    pageNumber: pageNumber,
                    totalPages: totalPages,
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      width: double.infinity,
                      margin: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: grisBordeSuave, width: 1.0),
                        color: grisPlano,
                      ),
                      child: pw.Stack(
                        children: [
                          if (basemapBytes != null)
                            pw.Positioned.fill(
                              child: pw.Image(
                                pw.MemoryImage(basemapBytes),
                                fit: pw.BoxFit.fill,
                              ),
                            ),
                          pw.Positioned.fill(
                            child: _buildArchitecturalCrosshairs(),
                          ),
                          pw.Positioned.fill(
                            child: _buildVectorPolyline(
                              data: data,
                              projection: projection,
                              idaColor: linePdfColor,
                              vueltaColor: vueltaPdfColor,
                              lanusBoundaryPoints: lanusBoundaryPoints,
                              includeStops: includeStops,
                            ),
                          ),
                          pw.Positioned(
                            top: 14,
                            right: 14,
                            child: _buildArchitecturalNorthArrow(isPlotterLarge),
                          ),
                          pw.Positioned(
                            bottom: 12,
                            left: 14,
                            child: _buildGraphicScale(bounds, projection),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (hasStreets)
                    _buildStreetItineraryBanner(
                      idaStreets: idaStreets,
                      vueltaStreets: vueltaStreets,
                      idaColor: linePdfColor,
                      vueltaColor: vueltaPdfColor,
                      height: hojaRutaHeight,
                      isLarge: isPlotterLarge,
                    ),
                  _buildArchitecturalCarature(
                    data,
                    format,
                    caratureHeight,
                    linePdfColor,
                    vueltaPdfColor,
                    includeStops: includeStops,
                    includeOperationalMetrics: includeOperationalMetrics,
                    includeLanusBoundary: includeLanusBoundary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Construye una lámina única consolidada con todos los ramales superpuestos.
  static Future<pw.Page> _buildConsolidatedSheetPage({
    required List<CartographicRouteData> branchesData,
    required CartographicSheetFormat format,
    required PdfPageFormat pageFormat,
    required double margin,
    required bool includeBasemap,
    required MapboxStyle mapboxStyle,
    required Uint8List? logoBytes,
    List<LatLng> lanusBoundaryPoints = const [],
    bool includeStops = true,
    bool includeOperationalMetrics = true,
    bool includeLanusBoundary = true,
  }) async {
    final allRoutePoints = [for (final b in branchesData) ...b.allPoints];
    final bounds = _calculateSafeBounds(allRoutePoints);

    final pageWidth = pageFormat.width;
    final pageHeight = pageFormat.height;

    final contentWidth = pageWidth - (margin * 2);
    final contentHeight = pageHeight - (margin * 2);

    final isPlotterLarge = format == CartographicSheetFormat.a0 || format == CartographicSheetFormat.a1;
    final headerHeight = isPlotterLarge ? 90.0 : 66.0;
    final caratureHeight = isPlotterLarge ? 180.0 : 124.0;
    final summaryBannerHeight = isPlotterLarge ? 38.0 : 26.0;

    final mapWidth = contentWidth - 10.0;
    final mapHeight = contentHeight - headerHeight - caratureHeight - summaryBannerHeight - 16.0;

    final projection = MercatorViewportProjection(
      bounds: bounds,
      width: mapWidth,
      height: mapHeight,
    );

    Uint8List? basemapBytes;
    if (includeBasemap && allRoutePoints.isNotEmpty) {
      basemapBytes = await MapTileComposer.composeBasemap(
        bounds: bounds,
        targetWidthPx: (mapWidth * 2.0).toInt(),
        targetHeightPx: (mapHeight * 2.0).toInt(),
        style: mapboxStyle,
      );
    }

    final branchColors = <PdfColor>[];
    for (var i = 0; i < branchesData.length; i++) {
      branchColors.add(multiBranchPalette[i % multiBranchPalette.length]);
    }

    final firstBranch = branchesData.first;

    return pw.Page(
      pageFormat: pageFormat,
      margin: pw.EdgeInsets.all(margin),
      build: (pw.Context context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: azulArquitectura, width: 2.0),
            color: PdfColors.white,
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: grisLineaTecnica, width: 0.8),
              ),
              child: pw.Column(
                children: [
                  _buildInstitutionalHeader(
                    firstBranch,
                    format,
                    headerHeight,
                    logoBytes,
                    customSubtitle: 'PLANO DE CONJUNTO · RED CONSOLIDADA (${branchesData.length} RAMALES)',
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      width: double.infinity,
                      margin: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: grisBordeSuave, width: 1.0),
                        color: grisPlano,
                      ),
                      child: pw.Stack(
                        children: [
                          if (basemapBytes != null)
                            pw.Positioned.fill(
                              child: pw.Image(
                                pw.MemoryImage(basemapBytes),
                                fit: pw.BoxFit.fill,
                              ),
                            ),
                          pw.Positioned.fill(
                            child: _buildArchitecturalCrosshairs(),
                          ),
                          pw.Positioned.fill(
                            child: _buildMultiBranchVectorPolyline(
                              branchesData: branchesData,
                              branchColors: branchColors,
                              projection: projection,
                              lanusBoundaryPoints: lanusBoundaryPoints,
                            ),
                          ),
                          pw.Positioned(
                            top: 14,
                            right: 14,
                            child: _buildArchitecturalNorthArrow(isPlotterLarge),
                          ),
                          pw.Positioned(
                            bottom: 12,
                            left: 14,
                            child: _buildGraphicScale(bounds, projection),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildConsolidatedSummaryBanner(
                    branchesData: branchesData,
                    branchColors: branchColors,
                    height: summaryBannerHeight,
                    isLarge: isPlotterLarge,
                  ),
                  _buildConsolidatedCarature(
                    branchesData: branchesData,
                    branchColors: branchColors,
                    format: format,
                    height: caratureHeight,
                    includeStops: includeStops,
                    includeOperationalMetrics: includeOperationalMetrics,
                    includeLanusBoundary: includeLanusBoundary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Encabezado Institucional Oficial con logotipo y dependencias del Municipio de Lanús
  static pw.Widget _buildInstitutionalHeader(
    CartographicRouteData data,
    CartographicSheetFormat format,
    double height,
    Uint8List? logoBytes, {
    int? pageNumber,
    int? totalPages,
    String? customSubtitle,
  }) {
    final isLarge = format == CartographicSheetFormat.a0 || format == CartographicSheetFormat.a1;
    final titleSize = isLarge ? 17.0 : 12.0;
    final subSize = isLarge ? 10.0 : 8.0;

    return pw.Container(
      height: height,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const pw.BoxDecoration(
        color: azulArquitectura,
      ),
      child: pw.Row(
        children: [
          // Logo Oficial Municipio de Lanús
          if (logoBytes != null)
            pw.Container(
              width: height * 0.75,
              height: height * 0.75,
              margin: const pw.EdgeInsets.only(right: 12),
              decoration: pw.BoxDecoration(
                color: PdfColors.black,
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: celesteLanus, width: 1.5),
              ),
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Image(
                  pw.MemoryImage(logoBytes),
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),

          // Títulos Institucionales Requeridos
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      'MUNICIPIO DE LANÚS',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: titleSize,
                        letterSpacing: 1.8,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: const pw.BoxDecoration(
                        color: granateLanus,
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                      ),
                      child: pw.Text(
                        'PLANIFICACIÓN URBANA',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: subSize * 0.75,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'SUBSECRETARÍA DE PLANIFICACIÓN URBANA',
                  style: pw.TextStyle(
                    color: celesteLanus,
                    fontSize: subSize * 1.05,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                pw.Text(
                  customSubtitle ?? 'DIRECCIÓN GENERAL DE MOVILIDAD Y TRANSPORTE · LANÚS DIGITAL',
                  style: pw.TextStyle(
                    color: PdfColors.grey300,
                    fontSize: subSize * 0.88,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Identificador Técnico de Plano
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: celesteLanus, width: 1.0),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
              color: const PdfColor(0.12, 0.18, 0.28),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'PLANO DE ORDENAMIENTO VIAL',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: subSize * 0.9,
                  ),
                ),
                pw.Text(
                  'CÓD: LAN-${data.lineNumber}-${DateFormat("yyyyMM").format(data.date)}',
                  style: pw.TextStyle(
                    color: celesteLanus,
                    fontSize: subSize * 0.8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (pageNumber != null && totalPages != null)
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 2),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: const pw.BoxDecoration(
                      color: granateLanus,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                    ),
                    child: pw.Text(
                      'LÁMINA $pageNumber DE $totalPages',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: subSize * 0.72,
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

  /// Reticulado y cruces de precisión técnica de arquitectura
  static pw.Widget _buildArchitecturalCrosshairs() {
    return pw.CustomPaint(
      painter: (PdfGraphics canvas, PdfPoint size) {
        canvas.setStrokeColor(const PdfColor(0.3, 0.4, 0.5, 0.35));
        canvas.setLineWidth(0.6);

        final cols = 4;
        final rows = 3;
        final stepX = size.x / cols;
        final stepY = size.y / rows;

        for (int i = 1; i < cols; i++) {
          for (int j = 1; j < rows; j++) {
            final cx = stepX * i;
            final cy = stepY * j;
            const arm = 6.0;

            canvas.moveTo(cx - arm, cy);
            canvas.lineTo(cx + arm, cy);
            canvas.moveTo(cx, cy - arm);
            canvas.lineTo(cx, cy + arm);
          }
        }
        canvas.strokePath();

        const markLen = 14.0;
        canvas.setStrokeColor(azulArquitectura);
        canvas.setLineWidth(0.9);

        canvas.moveTo(4, 4 + markLen);
        canvas.lineTo(4, 4);
        canvas.lineTo(4 + markLen, 4);

        canvas.moveTo(size.x - 4 - markLen, 4);
        canvas.lineTo(size.x - 4, 4);
        canvas.lineTo(size.x - 4, 4 + markLen);

        canvas.moveTo(4, size.y - 4 - markLen);
        canvas.lineTo(4, size.y - 4);
        canvas.lineTo(4 + markLen, size.y - 4);

        canvas.moveTo(size.x - 4 - markLen, size.y - 4);
        canvas.lineTo(size.x - 4, size.y - 4);
        canvas.lineTo(size.x - 4, size.y - 4 - markLen);

        canvas.strokePath();
      },
    );
  }

  /// Traza vectorial exacta proyectada mediante Web Mercator isométrica:
  /// - IDA: línea continua sólida con flechas direccionales espaciadas.
  /// - VUELTA: línea discontinua con espacios y flechas direccionales.
  /// - LÍMITE LANÚS: trazo técnico perimetral oficial (si está activado).
  static pw.Widget _buildVectorPolyline({
    required CartographicRouteData data,
    required MercatorViewportProjection projection,
    required PdfColor idaColor,
    required PdfColor vueltaColor,
    List<LatLng> lanusBoundaryPoints = const [],
    bool includeStops = true,
  }) {
    final idaPoints = data.effectiveIdaPoints;
    final vueltaPoints = data.effectiveVueltaPoints;
    final stops = data.stopPoints;

    if (idaPoints.isEmpty && vueltaPoints.isEmpty && lanusBoundaryPoints.isEmpty) return pw.SizedBox();

    return pw.CustomPaint(
      painter: (PdfGraphics canvas, PdfPoint size) {
        // 0. Límite Jurisdiccional Oficial del Partido de Lanús (si está habilitado)
        if (lanusBoundaryPoints.isNotEmpty) {
          // 0a. Halo blanco de contraste con trazo discontinuo
          canvas.setStrokeColor(PdfColors.white);
          canvas.setLineWidth(4.0);
          canvas.setLineDashPattern(const [8, 4, 2, 4], 0);
          final firstB = projection.projectToPdf(lanusBoundaryPoints.first);
          canvas.moveTo(firstB.x, firstB.y);
          for (int i = 1; i < lanusBoundaryPoints.length; i++) {
            final pt = projection.projectToPdf(lanusBoundaryPoints[i]);
            canvas.lineTo(pt.x, pt.y);
          }
          canvas.strokePath();

          // 0b. Traza municipal oficial (Granate Lanús)
          canvas.setStrokeColor(granateLanus);
          canvas.setLineWidth(2.0);
          canvas.setLineDashPattern(const [8, 4, 2, 4], 0);
          canvas.moveTo(firstB.x, firstB.y);
          for (int i = 1; i < lanusBoundaryPoints.length; i++) {
            final pt = projection.projectToPdf(lanusBoundaryPoints[i]);
            canvas.lineTo(pt.x, pt.y);
          }
          canvas.strokePath();
          canvas.setLineDashPattern(); // Restaurar trazo continuo
        }

        // 1. RECORRIDO VUELTA (Línea con espacios / discontinua)
        if (vueltaPoints.isNotEmpty) {
          // 1a. Halo blanco de contraste con patrón discontinuo
          canvas.setStrokeColor(PdfColors.white);
          canvas.setLineWidth(5.5);
          canvas.setLineDashPattern(const [7, 4], 0);
          final firstV = projection.projectToPdf(vueltaPoints.first);
          canvas.moveTo(firstV.x, firstV.y);
          for (int i = 1; i < vueltaPoints.length; i++) {
            final pt = projection.projectToPdf(vueltaPoints[i]);
            canvas.lineTo(pt.x, pt.y);
          }
          canvas.strokePath();

          // 1b. Traza oficial de VUELTA con espacios
          canvas.setStrokeColor(vueltaColor);
          canvas.setLineWidth(3.2);
          canvas.setLineDashPattern(const [7, 4], 0);
          canvas.moveTo(firstV.x, firstV.y);
          for (int i = 1; i < vueltaPoints.length; i++) {
            final pt = projection.projectToPdf(vueltaPoints[i]);
            canvas.lineTo(pt.x, pt.y);
          }
          canvas.strokePath();
          canvas.setLineDashPattern(); // Restaurar trazo continuo

          // 1c. Flechas direccionales espaciadas en sentido VUELTA
          _drawDirectionalChevrons(
            canvas: canvas,
            points: vueltaPoints,
            projection: projection,
            color: vueltaColor,
            spacingMeters: 1800.0,
          );
        }

        // 2. RECORRIDO IDA (Línea continua)
        if (idaPoints.isNotEmpty) {
          // 2a. Halo blanco continuo
          canvas.setStrokeColor(PdfColors.white);
          canvas.setLineWidth(5.5);
          canvas.setLineDashPattern();
          final firstI = projection.projectToPdf(idaPoints.first);
          canvas.moveTo(firstI.x, firstI.y);
          for (int i = 1; i < idaPoints.length; i++) {
            final pt = projection.projectToPdf(idaPoints[i]);
            canvas.lineTo(pt.x, pt.y);
          }
          canvas.strokePath();

          // 2b. Traza oficial de IDA continua
          canvas.setStrokeColor(idaColor);
          canvas.setLineWidth(3.2);
          canvas.moveTo(firstI.x, firstI.y);
          for (int i = 1; i < idaPoints.length; i++) {
            final pt = projection.projectToPdf(idaPoints[i]);
            canvas.lineTo(pt.x, pt.y);
          }
          canvas.strokePath();

          // 2c. Flechas direccionales espaciadas en sentido IDA
          _drawDirectionalChevrons(
            canvas: canvas,
            points: idaPoints,
            projection: projection,
            color: idaColor,
            spacingMeters: 1800.0,
          );
        }

        // 3. Paradas intermedias registradas (condicional)
        if (includeStops && stops.isNotEmpty) {
          canvas.setFillColor(idaColor);
          canvas.setStrokeColor(PdfColors.white);
          canvas.setLineWidth(1.2);
          for (final stop in stops) {
            final spt = projection.projectToPdf(stop);
            canvas.drawEllipse(spt.x, spt.y, 3.5, 3.5);
            canvas.fillPath();
            canvas.drawEllipse(spt.x, spt.y, 3.5, 3.5);
            canvas.strokePath();
          }
        }

        // 4. Cabecera Inicial / Origen (Círculo Verde esmeralda)
        final originPoint = idaPoints.isNotEmpty
            ? idaPoints.first
            : (vueltaPoints.isNotEmpty ? vueltaPoints.first : null);
        if (originPoint != null) {
          final firstPt = projection.projectToPdf(originPoint);
          canvas.setFillColor(const PdfColor(0.1, 0.65, 0.2));
          canvas.setStrokeColor(PdfColors.white);
          canvas.setLineWidth(2.0);
          canvas.drawEllipse(firstPt.x, firstPt.y, 7.0, 7.0);
          canvas.fillPath();
          canvas.drawEllipse(firstPt.x, firstPt.y, 7.0, 7.0);
          canvas.strokePath();
        }

        // 5. Cabecera Final / Terminal de Destino (Círculo Granate Lanús)
        final destPoint = idaPoints.isNotEmpty
            ? idaPoints.last
            : (vueltaPoints.isNotEmpty ? vueltaPoints.last : null);
        if (destPoint != null) {
          final lastPt = projection.projectToPdf(destPoint);
          canvas.setFillColor(granateLanus);
          canvas.setStrokeColor(PdfColors.white);
          canvas.setLineWidth(2.0);
          canvas.drawEllipse(lastPt.x, lastPt.y, 7.0, 7.0);
          canvas.fillPath();
          canvas.drawEllipse(lastPt.x, lastPt.y, 7.0, 7.0);
          canvas.strokePath();
        }
      },
    );
  }

  /// Traza vectorial simultánea para múltiples ramales en una lámina consolidada
  static pw.Widget _buildMultiBranchVectorPolyline({
    required List<CartographicRouteData> branchesData,
    required List<PdfColor> branchColors,
    required MercatorViewportProjection projection,
    List<LatLng> lanusBoundaryPoints = const [],
  }) {
    return pw.CustomPaint(
      painter: (PdfGraphics canvas, PdfPoint size) {
        // 0. Límite Jurisdiccional Oficial del Partido de Lanús
        if (lanusBoundaryPoints.isNotEmpty) {
          canvas.setStrokeColor(PdfColors.white);
          canvas.setLineWidth(4.0);
          canvas.setLineDashPattern(const [8, 4, 2, 4], 0);
          final firstB = projection.projectToPdf(lanusBoundaryPoints.first);
          canvas.moveTo(firstB.x, firstB.y);
          for (int i = 1; i < lanusBoundaryPoints.length; i++) {
            final pt = projection.projectToPdf(lanusBoundaryPoints[i]);
            canvas.lineTo(pt.x, pt.y);
          }
          canvas.strokePath();

          canvas.setStrokeColor(granateLanus);
          canvas.setLineWidth(2.0);
          canvas.setLineDashPattern(const [8, 4, 2, 4], 0);
          canvas.moveTo(firstB.x, firstB.y);
          for (int i = 1; i < lanusBoundaryPoints.length; i++) {
            final pt = projection.projectToPdf(lanusBoundaryPoints[i]);
            canvas.lineTo(pt.x, pt.y);
          }
          canvas.strokePath();
          canvas.setLineDashPattern();
        }

        for (int b = 0; b < branchesData.length; b++) {
          final data = branchesData[b];
          final color = branchColors[b % branchColors.length];
          final idaPoints = data.effectiveIdaPoints;
          final vueltaPoints = data.effectiveVueltaPoints;

          // 1. RECORRIDO VUELTA (Línea con espacios / discontinua)
          if (vueltaPoints.isNotEmpty) {
            canvas.setStrokeColor(PdfColors.white);
            canvas.setLineWidth(4.8);
            canvas.setLineDashPattern(const [6, 4], 0);
            final firstV = projection.projectToPdf(vueltaPoints.first);
            canvas.moveTo(firstV.x, firstV.y);
            for (int i = 1; i < vueltaPoints.length; i++) {
              final pt = projection.projectToPdf(vueltaPoints[i]);
              canvas.lineTo(pt.x, pt.y);
            }
            canvas.strokePath();

            canvas.setStrokeColor(color);
            canvas.setLineWidth(2.8);
            canvas.setLineDashPattern(const [6, 4], 0);
            canvas.moveTo(firstV.x, firstV.y);
            for (int i = 1; i < vueltaPoints.length; i++) {
              final pt = projection.projectToPdf(vueltaPoints[i]);
              canvas.lineTo(pt.x, pt.y);
            }
            canvas.strokePath();
            canvas.setLineDashPattern();

            _drawDirectionalChevrons(
              canvas: canvas,
              points: vueltaPoints,
              projection: projection,
              color: color,
              spacingMeters: 2200.0,
            );
          }

          // 2. RECORRIDO IDA (Línea continua)
          if (idaPoints.isNotEmpty) {
            canvas.setStrokeColor(PdfColors.white);
            canvas.setLineWidth(4.8);
            canvas.setLineDashPattern();
            final firstI = projection.projectToPdf(idaPoints.first);
            canvas.moveTo(firstI.x, firstI.y);
            for (int i = 1; i < idaPoints.length; i++) {
              final pt = projection.projectToPdf(idaPoints[i]);
              canvas.lineTo(pt.x, pt.y);
            }
            canvas.strokePath();

            canvas.setStrokeColor(color);
            canvas.setLineWidth(2.8);
            canvas.moveTo(firstI.x, firstI.y);
            for (int i = 1; i < idaPoints.length; i++) {
              final pt = projection.projectToPdf(idaPoints[i]);
              canvas.lineTo(pt.x, pt.y);
            }
            canvas.strokePath();

            _drawDirectionalChevrons(
              canvas: canvas,
              points: idaPoints,
              projection: projection,
              color: color,
              spacingMeters: 2200.0,
            );
          }

          // 3. Cabecera Inicial del Ramal
          if (idaPoints.isNotEmpty) {
            final orig = projection.projectToPdf(idaPoints.first);
            canvas.setFillColor(PdfColors.white);
            canvas.drawEllipse(orig.x, orig.y, 4.5, 4.5);
            canvas.fillPath();
            canvas.setFillColor(color);
            canvas.drawEllipse(orig.x, orig.y, 3.2, 3.2);
            canvas.fillPath();
          }
        }
      },
    );
  }

  /// Banda resumen de ramales en plano consolidado
  static pw.Widget _buildConsolidatedSummaryBanner({
    required List<CartographicRouteData> branchesData,
    required List<PdfColor> branchColors,
    required double height,
    required bool isLarge,
  }) {
    final fontSize = isLarge ? 8.0 : 6.4;
    return pw.Container(
      height: height,
      margin: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: grisLineaTecnica, width: 0.8),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            color: granateLanus,
            child: pw.Text(
              'RAMALES EN PLANO:',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Wrap(
              spacing: 10,
              runSpacing: 2,
              children: [
                for (var i = 0; i < branchesData.length; i++) ...[
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Container(
                        width: 7,
                        height: 7,
                        decoration: pw.BoxDecoration(
                          color: branchColors[i % branchColors.length],
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        '${branchesData[i].branchName} (${branchesData[i].distanceKm.toStringAsFixed(1)} km)',
                        style: pw.TextStyle(
                          fontSize: fontSize,
                          fontWeight: pw.FontWeight.bold,
                          color: azulArquitectura,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Carátula oficial para plano consolidado con múltiples ramales
  static pw.Widget _buildConsolidatedCarature({
    required List<CartographicRouteData> branchesData,
    required List<PdfColor> branchColors,
    required CartographicSheetFormat format,
    required double height,
    bool includeStops = true,
    bool includeOperationalMetrics = true,
    bool includeLanusBoundary = true,
  }) {
    final isLarge = format == CartographicSheetFormat.a0 || format == CartographicSheetFormat.a1;
    final fontSizeTitle = isLarge ? 15.0 : 10.0;
    final fontSizeVal = isLarge ? 10.0 : 7.4;
    final first = branchesData.first;
    final totalKm = branchesData.fold(0.0, (acc, b) => acc + b.distanceKm);
    final totalPoints = branchesData.fold(0, (acc, b) => acc + b.allPoints.length);
    final totalStops = branchesData.fold(0, (acc, b) => acc + b.stopPoints.length);

    final leftIndices = <int>[];
    final rightIndices = <int>[];
    for (int i = 0; i < branchesData.length; i++) {
      if (i.isEven) {
        leftIndices.add(i);
      } else {
        rightIndices.add(i);
      }
    }

    return pw.Container(
      height: height,
      padding: const pw.EdgeInsets.all(6),
      decoration: const pw.BoxDecoration(color: PdfColors.white),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // 1. Bloque de Proyecto y Ubicación
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: grisLineaTecnica, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'PROYECTO: RED DE TRANSPORTE PÚBLICO COLECTIVO',
                    style: pw.TextStyle(fontSize: fontSizeVal * 0.9, fontWeight: pw.FontWeight.bold, color: granateLanus),
                  ),
                  pw.Text(
                    'UBICACIÓN: PARTIDO DE LANÚS · PCIA. DE BUENOS AIRES',
                    style: pw.TextStyle(fontSize: fontSizeVal * 0.8, color: PdfColors.grey700),
                  ),
                  pw.Divider(color: grisBordeSuave, thickness: 0.5),
                  pw.Row(
                    children: [
                      pw.Container(
                        width: isLarge ? 48 : 34,
                        height: isLarge ? 48 : 34,
                        decoration: const pw.BoxDecoration(
                          color: azulArquitectura,
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            first.lineNumber,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: isLarge ? 18 : 13,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'LÍNEA ${first.lineNumber} · RED CONSOLIDADA',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: fontSizeTitle,
                                color: azulArquitectura,
                              ),
                            ),
                            pw.Text(
                              '${branchesData.length} RAMALES INTEGRADOS · ${first.lineName}',
                              style: pw.TextStyle(fontSize: fontSizeVal * 0.9, color: PdfColors.grey700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 6),

          // 2. Ficha Técnica Consolidada
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: grisLineaTecnica, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricRow('Red Total Consolidada:', '${totalKm.toStringAsFixed(1)} km', fontSizeVal),
                  _buildMetricRow('Ramales en Lámina:', '${branchesData.length} ramales', fontSizeVal),
                  _buildMetricRow('Puntos GPS Digitalizados:', '$totalPoints pts', fontSizeVal),
                  if (includeStops) _buildMetricRow('Paradas Registradas:', '$totalStops paradas', fontSizeVal),
                  if (includeOperationalMetrics) ...[
                    _buildMetricRow('Tiempo Medio de Ciclo:', '${_calculateEstimatedMinutes(totalKm / branchesData.length)} min', fontSizeVal),
                    _buildMetricRow('Frecuencia Estimada:', '4 - 8 min', fontSizeVal),
                  ],
                  _buildMetricRow('Fecha de Emisión:', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()), fontSizeVal),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 6),

          // 3. Leyenda y Referencias de Ramales
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: grisLineaTecnica, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    decoration: const pw.BoxDecoration(color: azulArquitectura),
                    child: pw.Text(
                      'LEYENDA DE RAMALES',
                      style: pw.TextStyle(
                        fontSize: fontSizeVal * 0.85,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 0.6,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                              children: [
                                for (final idx in leftIndices)
                                  _buildBranchLegendItem(
                                    name: branchesData[idx].branchName,
                                    distKm: branchesData[idx].distanceKm,
                                    color: branchColors[idx % branchColors.length],
                                    fontSize: fontSizeVal,
                                  ),
                              ],
                            ),
                          ),
                          if (rightIndices.isNotEmpty) ...[
                            pw.SizedBox(width: 6),
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                                children: [
                                  for (final idx in rightIndices)
                                    _buildBranchLegendItem(
                                      name: branchesData[idx].branchName,
                                      distKm: branchesData[idx].distanceKm,
                                      color: branchColors[idx % branchColors.length],
                                      fontSize: fontSizeVal,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBranchLegendItem({
    required String name,
    required double distKm,
    required PdfColor color,
    required double fontSize,
  }) {
    return pw.Row(
      children: [
        pw.Container(width: 10, height: 3.5, color: color),
        pw.SizedBox(width: 4),
        pw.Expanded(
          child: pw.Text(
            name,
            style: pw.TextStyle(fontSize: fontSize * 0.85, fontWeight: pw.FontWeight.bold),
            maxLines: 1,
          ),
        ),
        pw.Text(
          '${distKm.toStringAsFixed(1)} km',
          style: pw.TextStyle(fontSize: fontSize * 0.78, color: PdfColors.grey700),
        ),
      ],
    );
  }
  static void _drawDirectionalChevrons({
    required PdfGraphics canvas,
    required List<LatLng> points,
    required MercatorViewportProjection projection,
    required PdfColor color,
    double spacingMeters = 1800.0,
  }) {
    if (points.length < 3) return;

    double totalDist = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDist += _distanceMeters(points[i], points[i + 1]);
    }

    final effectiveSpacing = totalDist < 4000.0
        ? (totalDist / 3.0).clamp(700.0, 2000.0)
        : spacingMeters;

    double accumulated = 0.0;
    double distFromStart = 0.0;

    for (int i = 0; i < points.length - 1; i++) {
      final pA = points[i];
      final pB = points[i + 1];
      final d = _distanceMeters(pA, pB);
      accumulated += d;
      distFromStart += d;

      // Colocar flecha cuando se alcance el intervalo, evitando extremos
      if (accumulated >= effectiveSpacing &&
          distFromStart >= 500.0 &&
          (totalDist - distFromStart) >= 500.0) {
        final pdfA = projection.projectToPdf(pA);
        final pdfB = projection.projectToPdf(pB);

        final dx = pdfB.x - pdfA.x;
        final dy = pdfB.y - pdfA.y;
        final segLen = math.sqrt(dx * dx + dy * dy);

        double angle = math.atan2(dy, dx);
        if (segLen < 3.0 && i + 2 < points.length) {
          final pdfNext = projection.projectToPdf(points[i + 2]);
          angle = math.atan2(pdfNext.y - pdfA.y, pdfNext.x - pdfA.x);
        }

        final midX = (pdfA.x + pdfB.x) / 2.0;
        final midY = (pdfA.y + pdfB.y) / 2.0;

        _drawChevronTriangle(canvas, midX, midY, angle, color, size: 7.0);
        accumulated = 0.0;
      }
    }
  }

  static void _drawChevronTriangle(
    PdfGraphics canvas,
    double cx,
    double cy,
    double angle,
    PdfColor color, {
    double size = 7.0,
  }) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    final tipX = cx + size * 1.15 * cosA;
    final tipY = cy + size * 1.15 * sinA;
    final leftX = cx - size * 0.75 * cosA - size * 0.75 * sinA;
    final leftY = cy - size * 0.75 * sinA + size * 0.75 * cosA;
    final rightX = cx - size * 0.75 * cosA + size * 0.75 * sinA;
    final rightY = cy - size * 0.75 * sinA - size * 0.75 * cosA;

    // 1. Halo blanco de contraste
    canvas.setFillColor(PdfColors.white);
    canvas.moveTo(tipX + 1.2 * cosA, tipY + 1.2 * sinA);
    canvas.lineTo(leftX - 1.2 * cosA - 1.2 * sinA, leftY - 1.2 * sinA + 1.2 * cosA);
    canvas.lineTo(rightX - 1.2 * cosA + 1.2 * sinA, rightY - 1.2 * sinA - 1.2 * cosA);
    canvas.closePath();
    canvas.fillPath();

    // 2. Triángulo direccional relleno
    canvas.setFillColor(color);
    canvas.moveTo(tipX, tipY);
    canvas.lineTo(leftX, leftY);
    canvas.lineTo(rightX, rightY);
    canvas.closePath();
    canvas.fillPath();
  }

  static double _distanceMeters(LatLng p1, LatLng p2) {
    const earthRadius = 6371000.0;
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180.0;
    final dLon = (p2.longitude - p1.longitude) * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(p1.latitude * math.pi / 180.0) *
            math.cos(p2.latitude * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Rosa de los vientos arquitectónica con círculo graduado
  static pw.Widget _buildArchitecturalNorthArrow(bool isPlotter) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: azulArquitectura, width: 1.0),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('N', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: azulArquitectura)),
          pw.Container(
            width: isPlotter ? 22 : 16,
            height: isPlotter ? 32 : 24,
            child: pw.CustomPaint(
              painter: (PdfGraphics canvas, PdfPoint size) {
                canvas.setStrokeColor(grisLineaTecnica);
                canvas.setLineWidth(0.6);
                canvas.drawEllipse(size.x / 2, size.y * 0.45, size.x * 0.45, size.x * 0.45);
                canvas.strokePath();

                canvas.setFillColor(azulArquitectura);
                canvas.moveTo(size.x / 2, size.y);
                canvas.lineTo(0, 0);
                canvas.lineTo(size.x / 2, size.y * 0.3);
                canvas.fillPath();

                canvas.setFillColor(celesteLanus);
                canvas.moveTo(size.x / 2, size.y);
                canvas.lineTo(size.x, 0);
                canvas.lineTo(size.x / 2, size.y * 0.3);
                canvas.fillPath();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Escala gráfica métrica matemáticamente calibrada desde Web Mercator
  static pw.Widget _buildGraphicScale(LatLngBounds bounds, MercatorViewportProjection projection) {
    final meanLat = (bounds.north + bounds.south) / 2.0;
    final latRad = meanLat * math.pi / 180.0;
    // Metros por unidad de mundo Web Mercator a esta latitud
    final metersPerWorldUnit = (40075016.686 * math.cos(latRad)) / 256.0;
    // Metros por punto de PDF
    final metersPerPoint = metersPerWorldUnit / projection.scale;

    if (metersPerPoint <= 0) return pw.SizedBox();

    // Determina valor redondo para la escala
    double scaleMeters = 1000.0;
    final targetBarPoints = 100.0;
    final approxMeters = targetBarPoints * metersPerPoint;

    if (approxMeters > 15000) {
      scaleMeters = 20000.0;
    } else if (approxMeters > 7000) {
      scaleMeters = 10000.0;
    } else if (approxMeters > 3500) {
      scaleMeters = 5000.0;
    } else if (approxMeters > 1500) {
      scaleMeters = 2000.0;
    } else if (approxMeters > 700) {
      scaleMeters = 1000.0;
    } else {
      scaleMeters = 500.0;
    }

    final barWidthPoints = scaleMeters / metersPerPoint;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: azulArquitectura, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            'ESCALA MÉTRICA: ${scaleMeters >= 1000 ? "${(scaleMeters / 1000).toStringAsFixed(1)} km" : "${scaleMeters.toInt()} m"}',
            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: azulArquitectura),
          ),
          pw.SizedBox(height: 3),
          pw.Container(
            width: barWidthPoints.clamp(45.0, 160.0),
            height: 6,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: azulArquitectura, width: 0.8),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(child: pw.Container(color: azulArquitectura)),
                pw.Expanded(child: pw.Container(color: PdfColors.white)),
                pw.Expanded(child: pw.Container(color: azulArquitectura)),
                pw.Expanded(child: pw.Container(color: PdfColors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Carátula de Plano de Arquitectura y Urbanismo (Title Block) con Cuadro de Referencias Oficiales
  static pw.Widget _buildArchitecturalCarature(
    CartographicRouteData data,
    CartographicSheetFormat format,
    double height,
    PdfColor idaColor,
    PdfColor vueltaColor, {
    bool includeStops = true,
    bool includeOperationalMetrics = true,
    bool includeLanusBoundary = true,
  }) {
    final isLarge = format == CartographicSheetFormat.a0 || format == CartographicSheetFormat.a1;
    final fontSizeTitle = isLarge ? 15.0 : 10.0;
    final fontSizeVal = isLarge ? 11.0 : 8.0;

    return pw.Container(
      height: height,
      padding: const pw.EdgeInsets.all(6),
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // 1. Bloque de Proyecto y Ubicación
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: grisLineaTecnica, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'PROYECTO: RED DE TRANSPORTE PÚBLICO COLECTIVO',
                    style: pw.TextStyle(fontSize: fontSizeVal * 0.9, fontWeight: pw.FontWeight.bold, color: granateLanus),
                  ),
                  pw.Text(
                    'UBICACIÓN: PARTIDO DE LANÚS · PCIA. DE BUENOS AIRES',
                    style: pw.TextStyle(fontSize: fontSizeVal * 0.8, color: PdfColors.grey700),
                  ),
                  pw.Divider(color: grisBordeSuave, thickness: 0.5),
                  pw.Row(
                    children: [
                      pw.Container(
                        width: isLarge ? 48 : 34,
                        height: isLarge ? 48 : 34,
                        decoration: pw.BoxDecoration(
                          color: idaColor,
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            data.lineNumber,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: isLarge ? 18 : 13,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'LÍNEA ${data.lineNumber} · ${data.branchName.toUpperCase()}',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: fontSizeTitle,
                                color: azulArquitectura,
                              ),
                            ),
                            pw.Text(
                              'SENTIDO: ${data.direction} · ${data.lineName}',
                              style: pw.TextStyle(fontSize: fontSizeVal * 0.9, color: PdfColors.grey700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 6),

          // 2. Ficha Técnica y Cómputo de Traza con Indicadores Operativos
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: grisLineaTecnica, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  if (data.hasIda && data.hasVuelta && data.idaDistanceKm != null) ...[
                    _buildMetricRow('Longitud Ida / Vuelta:', '${data.idaDistanceKm!.toStringAsFixed(1)} / ${(data.vueltaDistanceKm ?? 0).toStringAsFixed(1)} km', fontSizeVal),
                    _buildMetricRow('Distancia Total:', '${data.distanceKm.toStringAsFixed(1)} km', fontSizeVal),
                  ] else ...[
                    _buildMetricRow('Longitud Total:', '${data.distanceKm.toStringAsFixed(2)} km', fontSizeVal),
                    _buildMetricRow('Puntos GPS:', '${data.allPoints.length}', fontSizeVal),
                  ],
                  if (includeOperationalMetrics) ...[
                    _buildMetricRow('Tiempo de Viaje:', '${_calculateEstimatedMinutes(data.distanceKm)} min (Ciclo)', fontSizeVal),
                    _buildMetricRow('Frecuencia Estimada:', _calculateFrequency(data.distanceKm), fontSizeVal),
                  ],
                  if (includeStops)
                    _buildMetricRow('Paradas Registradas:', '${data.stopPoints.length}', fontSizeVal),
                  _buildMetricRow('Fecha de Emisión:', DateFormat('dd/MM/yyyy HH:mm').format(data.date), fontSizeVal),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 6),

          // 3. Cuadro de Referencias Cartográficas Oficiales
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: grisLineaTecnica, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    decoration: const pw.BoxDecoration(
                      color: azulArquitectura,
                    ),
                    child: pw.Text(
                      'REFERENCIAS CARTOGRÁFICAS',
                      style: pw.TextStyle(
                        fontSize: fontSizeVal * 0.82,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 0.6,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  if (data.hasIda)
                    _buildLegendRow(
                      swatch: _buildLineSwatch(color: idaColor, isDashed: false),
                      label: 'Recorrido IDA (Traza Continua)',
                      distText: data.idaDistanceKm != null && data.idaDistanceKm! > 0
                          ? '${data.idaDistanceKm!.toStringAsFixed(1)} km'
                          : null,
                      fontSize: fontSizeVal,
                    ),
                  if (data.hasVuelta)
                    _buildLegendRow(
                      swatch: _buildLineSwatch(color: vueltaColor, isDashed: true),
                      label: 'Recorrido VUELTA (Traza Discontinua)',
                      distText: data.vueltaDistanceKm != null && data.vueltaDistanceKm! > 0
                          ? '${data.vueltaDistanceKm!.toStringAsFixed(1)} km'
                          : null,
                      fontSize: fontSizeVal,
                    ),
                  _buildLegendRow(
                    swatch: _buildArrowSwatch(color: idaColor),
                    label: 'Sentido de Flujo (Flechas de Guía)',
                    fontSize: fontSizeVal,
                  ),
                  _buildLegendRow(
                    swatch: _buildDotSwatch(color: const PdfColor(0.1, 0.65, 0.2)),
                    label: 'Cabecera Inicial / Origen',
                    fontSize: fontSizeVal,
                  ),
                  _buildLegendRow(
                    swatch: _buildDotSwatch(color: granateLanus),
                    label: 'Cabecera Final / Destino',
                    fontSize: fontSizeVal,
                  ),
                  if (includeStops)
                    _buildLegendRow(
                      swatch: _buildStopSwatch(color: idaColor),
                      label: 'Paradas Oficiales (${data.stopPoints.length})',
                      fontSize: fontSizeVal,
                    ),
                  if (includeLanusBoundary)
                    _buildLegendRow(
                      swatch: _buildBoundarySwatch(),
                      label: 'Límite Partido de Lanús',
                      fontSize: fontSizeVal,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Banda de Hoja de Ruta Oficial con la secuencia detectada de calles y avenidas
  static pw.Widget _buildStreetItineraryBanner({
    required List<String> idaStreets,
    required List<String> vueltaStreets,
    required PdfColor idaColor,
    required PdfColor vueltaColor,
    required double height,
    required bool isLarge,
  }) {
    final titleSize = isLarge ? 8.5 : 6.8;
    final bodySize = isLarge ? 7.6 : 6.0;

    return pw.Container(
      height: height,
      margin: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: grisLineaTecnica, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                color: granateLanus,
                child: pw.Text(
                  'HOJA DE RUTA VIAL · ITINERARIO OFICIAL DE ARTERIAS',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: titleSize,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Text(
                'Secuencia georreferenciada de circulación en vía pública',
                style: pw.TextStyle(
                  color: PdfColors.grey600,
                  fontSize: titleSize * 0.9,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          if (idaStreets.isNotEmpty)
            pw.Row(
              children: [
                pw.Text(
                  'IDA: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: idaColor, fontSize: bodySize),
                ),
                pw.Expanded(
                  child: pw.Text(
                    idaStreets.join('  ->  '),
                    style: pw.TextStyle(color: azulArquitectura, fontWeight: pw.FontWeight.bold, fontSize: bodySize),
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                  ),
                ),
              ],
            ),
          if (vueltaStreets.isNotEmpty)
            pw.Row(
              children: [
                pw.Text(
                  'VUELTA: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: vueltaColor, fontSize: bodySize),
                ),
                pw.Expanded(
                  child: pw.Text(
                    vueltaStreets.join('  ->  '),
                    style: pw.TextStyle(color: azulArquitectura, fontWeight: pw.FontWeight.bold, fontSize: bodySize),
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricRow(String label, String value, double fontSize) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: fontSize * 0.88, color: PdfColors.grey700)),
        pw.Text(value, style: pw.TextStyle(fontSize: fontSize * 0.95, fontWeight: pw.FontWeight.bold, color: azulArquitectura)),
      ],
    );
  }

  static pw.Widget _buildLegendRow({
    required pw.Widget swatch,
    required String label,
    String? distText,
    required double fontSize,
  }) {
    return pw.Row(
      children: [
        pw.Container(
          width: 26,
          height: 9,
          alignment: pw.Alignment.center,
          child: swatch,
        ),
        pw.SizedBox(width: 5),
        pw.Expanded(
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize * 0.78,
              fontWeight: pw.FontWeight.bold,
              color: azulArquitectura,
            ),
            maxLines: 1,
          ),
        ),
        if (distText != null && distText.isNotEmpty) ...[
          pw.SizedBox(width: 4),
          pw.Text(
            distText,
            style: pw.TextStyle(
              fontSize: fontSize * 0.78,
              fontWeight: pw.FontWeight.bold,
              color: granateLanus,
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildLineSwatch({
    required PdfColor color,
    required bool isDashed,
  }) {
    return pw.CustomPaint(
      size: const PdfPoint(26, 9),
      painter: (PdfGraphics canvas, PdfPoint size) {
        canvas.setStrokeColor(color);
        canvas.setLineWidth(2.8);
        if (isDashed) {
          canvas.setLineDashPattern(const [5, 3], 0);
        } else {
          canvas.setLineDashPattern();
        }
        canvas.moveTo(0, size.y / 2);
        canvas.lineTo(size.x, size.y / 2);
        canvas.strokePath();
        if (isDashed) canvas.setLineDashPattern();
      },
    );
  }

  static pw.Widget _buildArrowSwatch({required PdfColor color}) {
    return pw.CustomPaint(
      size: const PdfPoint(26, 9),
      painter: (PdfGraphics canvas, PdfPoint size) {
        _drawChevronTriangle(canvas, size.x / 2, size.y / 2, 0, color, size: 4.5);
      },
    );
  }

  static pw.Widget _buildDotSwatch({required PdfColor color}) {
    return pw.CustomPaint(
      size: const PdfPoint(26, 9),
      painter: (PdfGraphics canvas, PdfPoint size) {
        canvas.setFillColor(color);
        canvas.setStrokeColor(PdfColors.white);
        canvas.setLineWidth(1.2);
        canvas.drawEllipse(size.x / 2, size.y / 2, 4.0, 4.0);
        canvas.fillPath();
        canvas.drawEllipse(size.x / 2, size.y / 2, 4.0, 4.0);
        canvas.strokePath();
      },
    );
  }

  static pw.Widget _buildStopSwatch({required PdfColor color}) {
    return pw.CustomPaint(
      size: const PdfPoint(26, 9),
      painter: (PdfGraphics canvas, PdfPoint size) {
        canvas.setFillColor(color);
        canvas.setStrokeColor(PdfColors.white);
        canvas.setLineWidth(0.8);
        canvas.drawEllipse(size.x / 2, size.y / 2, 2.8, 2.8);
        canvas.fillPath();
        canvas.drawEllipse(size.x / 2, size.y / 2, 2.8, 2.8);
        canvas.strokePath();
      },
    );
  }

  static pw.Widget _buildBoundarySwatch() {
    return pw.CustomPaint(
      size: const PdfPoint(26, 9),
      painter: (PdfGraphics canvas, PdfPoint size) {
        // Halo blanco
        canvas.setStrokeColor(PdfColors.white);
        canvas.setLineWidth(3.6);
        canvas.moveTo(0, size.y / 2);
        canvas.lineTo(size.x, size.y / 2);
        canvas.strokePath();

        // Traza Granate Lanús con patrón dash-dot
        canvas.setStrokeColor(granateLanus);
        canvas.setLineWidth(1.8);
        canvas.setLineDashPattern(const [6, 3, 2, 3], 0);
        canvas.moveTo(0, size.y / 2);
        canvas.lineTo(size.x, size.y / 2);
        canvas.strokePath();
        canvas.setLineDashPattern();
      },
    );
  }

  static int _calculateEstimatedMinutes(double distanceKm) {
    if (distanceKm <= 0) return 30;
    // Velocidad comercial media de colectivos en conurbano: 18.5 km/h
    return (distanceKm / 18.5 * 60).round().clamp(10, 180);
  }

  static String _calculateFrequency(double distanceKm) {
    if (distanceKm <= 10.0) return '6 - 9 min';
    if (distanceKm <= 20.0) return '8 - 12 min';
    return '12 - 16 min';
  }

  static LatLngBounds _calculateSafeBounds(List<LatLng> points) {
    if (points.isEmpty) {
      final center = LatLng(-34.7044, -58.3899);
      return LatLngBounds(
        LatLng(center.latitude - 0.04, center.longitude - 0.04),
        LatLng(center.latitude + 0.04, center.longitude + 0.04),
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLon = points.first.longitude;
    double maxLon = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }

    final latPad = (maxLat - minLat) * 0.12;
    final lonPad = (maxLon - minLon) * 0.12;

    final safeLatPad = latPad < 0.005 ? 0.005 : latPad;
    final safeLonPad = lonPad < 0.005 ? 0.005 : lonPad;

    return LatLngBounds(
      LatLng(minLat - safeLatPad, minLon - safeLonPad),
      LatLng(maxLat + safeLatPad, maxLon + safeLonPad),
    );
  }

  /// Guarda el archivo PDF temporal y lo comparte con SharePlus
  static Future<File> exportAndShare({
    required CartographicRouteData data,
    CartographicSheetFormat format = CartographicSheetFormat.a3,
    bool isLandscape = true,
    bool includeBasemap = true,
    MapboxStyle mapboxStyle = MapboxStyle.streetsColor,
    bool includeStops = true,
    bool includeOperationalMetrics = true,
    bool includeLanusBoundary = true,
  }) async {
    final bytes = await generateSheetBytes(
      data: data,
      format: format,
      isLandscape: isLandscape,
      includeBasemap: includeBasemap,
      mapboxStyle: mapboxStyle,
      includeStops: includeStops,
      includeOperationalMetrics: includeOperationalMetrics,
      includeLanusBoundary: includeLanusBoundary,
    );

    final tempDir = await getTemporaryDirectory();
    final fileName = 'Plano_Lanus_${data.lineNumber}_${data.branchName}_${format.name.toUpperCase()}.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Plano Oficial - Línea ${data.lineNumber} (${data.branchName})',
        text: 'Plano Cartográfico Oficial emitido por Subsecretaría de Planificación Urbana · Dirección General de Movilidad y Transporte - Línea ${data.lineNumber} (${format.name.toUpperCase()})',
      ),
    );

    return file;
  }

  /// Guarda el archivo PDF temporal multi-ramal y lo comparte con SharePlus
  static Future<File> exportAndShareMultiBranch({
    required List<CartographicRouteData> branchesData,
    CartographicSheetFormat format = CartographicSheetFormat.a3,
    bool isLandscape = true,
    bool includeBasemap = true,
    MapboxStyle mapboxStyle = MapboxStyle.streetsColor,
    MultiBranchExportMode mode = MultiBranchExportMode.multiPageBooklet,
    bool includeStops = true,
    bool includeOperationalMetrics = true,
    bool includeLanusBoundary = true,
    void Function(int current, int total, String status)? onProgress,
  }) async {
    final bytes = await generateMultiBranchBytes(
      branchesData: branchesData,
      format: format,
      isLandscape: isLandscape,
      includeBasemap: includeBasemap,
      mapboxStyle: mapboxStyle,
      mode: mode,
      includeStops: includeStops,
      includeOperationalMetrics: includeOperationalMetrics,
      includeLanusBoundary: includeLanusBoundary,
      onProgress: onProgress,
    );

    final tempDir = await getTemporaryDirectory();
    final lineNum = branchesData.first.lineNumber;
    final modeSuffix = mode == MultiBranchExportMode.multiPageBooklet ? 'Cuadernillo' : 'RedConsolidada';
    final fileName = 'Plano_Lanus_${lineNum}_${modeSuffix}_${format.name.toUpperCase()}.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Plano Oficial - Línea $lineNum ($modeSuffix)',
        text: 'Plano Cartográfico Oficial emitido por Subsecretaría de Planificación Urbana · Municipio de Lanús - Línea $lineNum ($modeSuffix, ${branchesData.length} ramales, ${format.name.toUpperCase()})',
      ),
    );

    return file;
  }
}
