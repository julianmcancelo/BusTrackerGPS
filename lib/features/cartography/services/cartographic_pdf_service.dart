import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/geo_utils.dart';
import '../../../core/utils/transport_utils.dart';
import 'map_tile_composer.dart';

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
  final List<LatLng> stopPoints;
  final double distanceKm;
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
    required this.polylinePoints,
    this.stopPoints = const [],
    required this.distanceKm,
    this.inspectorName,
    this.internalNumber,
    this.domain,
    required this.date,
    this.routeNotes,
  });
}

class CartographicPdfService {
  // Paleta oficial de Lanús y Arquitectura Técnica
  static const PdfColor granateLanus = PdfColor.fromInt(0xFF7B1828);
  static const PdfColor celesteLanus = PdfColor.fromInt(0xFF00AEEF);
  static const PdfColor azulArquitectura = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor grisPlano = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor grisLineaTecnica = PdfColor.fromInt(0xFF334155);
  static const PdfColor grisBordeSuave = PdfColor.fromInt(0xFFCBD5E1);

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

  /// Genera la lámina cartográfica oficial de arquitectura en el formato y orientación seleccionados.
  static Future<Uint8List> generateSheetBytes({
    required CartographicRouteData data,
    CartographicSheetFormat format = CartographicSheetFormat.a3,
    bool isLandscape = true,
    bool includeBasemap = true,
    MapboxStyle mapboxStyle = MapboxStyle.lightArchitectural,
  }) async {
    final pdf = pw.Document();
    final pageFormat = format.toPdfPageFormat(isLandscape: isLandscape);

    final points = data.polylinePoints;
    final bounds = _calculateSafeBounds(points);

    final pageWidth = pageFormat.width;
    final pageHeight = pageFormat.height;
    final margin = format == CartographicSheetFormat.a0 || format == CartographicSheetFormat.a1 ? 36.0 : 20.0;

    final contentWidth = pageWidth - (margin * 2);
    final contentHeight = pageHeight - (margin * 2);

    final isPlotterLarge = format == CartographicSheetFormat.a0 || format == CartographicSheetFormat.a1;
    final headerHeight = isPlotterLarge ? 90.0 : 66.0;
    final caratureHeight = isPlotterLarge ? 175.0 : 118.0;

    // Descarga de mosaico Mapbox (@2x Retina)
    Uint8List? basemapBytes;
    if (includeBasemap && points.isNotEmpty) {
      basemapBytes = await MapTileComposer.composeBasemap(
        bounds: bounds,
        targetWidthPx: (contentWidth * 1.5).toInt(),
        targetHeightPx: ((contentHeight - headerHeight - caratureHeight) * 1.5).toInt(),
        style: mapboxStyle,
      );
    }

    final logoBytes = await _loadOfficialLogoBytes();

    final lineColorHex = TransportUtils.getLineColor(data.lineNumber).toARGB32();
    final linePdfColor = PdfColor.fromInt(lineColorHex);

    pdf.addPage(
      pw.Page(
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
                    // 1. Encabezado Oficial Institucional con Logo
                    _buildInstitutionalHeader(data, format, headerHeight, logoBytes),

                    // 2. Viewport del Plano Cartográfico con estética arquitectónica
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
                            // Fondo raster Mapbox (Light / Streets)
                            if (basemapBytes != null)
                              pw.Positioned.fill(
                                child: pw.Image(
                                  pw.MemoryImage(basemapBytes),
                                  fit: pw.BoxFit.fill,
                                ),
                              ),

                            // Marcas de registro y cruces técnicas de arquitectura
                            pw.Positioned.fill(
                              child: _buildArchitecturalCrosshairs(bounds),
                            ),

                            // Trazado Vectorial de Alta Definición
                            pw.Positioned.fill(
                              child: _buildVectorPolyline(
                                points: points,
                                stops: data.stopPoints,
                                bounds: bounds,
                                lineColor: linePdfColor,
                              ),
                            ),

                            // Rosa de los Vientos Arquitectónica
                            pw.Positioned(
                              top: 14,
                              right: 14,
                              child: _buildArchitecturalNorthArrow(isPlotterLarge),
                            ),

                            // Escala Gráfica Métrica de Arquitectura
                            pw.Positioned(
                              bottom: 12,
                              left: 14,
                              child: _buildGraphicScale(bounds, contentWidth),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. Carátula de Plano de Urbanismo y Firmas
                    _buildArchitecturalCarature(data, format, caratureHeight, linePdfColor),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Encabezado Institucional Oficial con logotipo y dependencias del Municipio de Lanús
  static pw.Widget _buildInstitutionalHeader(
    CartographicRouteData data,
    CartographicSheetFormat format,
    double height,
    Uint8List? logoBytes,
  ) {
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
                        'GESTIÓN URBANA',
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
                  'DIRECCIÓN GENERAL DE MOVILIDAD Y TRANSPORTE · LANÚS DIGITAL',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Reticulado y cruces de precisión técnica de arquitectura
  static pw.Widget _buildArchitecturalCrosshairs(LatLngBounds bounds) {
    return pw.CustomPaint(
      painter: (PdfGraphics canvas, PdfPoint size) {
        canvas.setStrokeColor(const PdfColor(0.3, 0.4, 0.5, 0.35));
        canvas.setLineWidth(0.6);

        // Cruces de mira arquitectónicas (+) en puntos de retícula
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

        // Marcas de registro en las 4 esquinas exteriores
        const markLen = 14.0;
        canvas.setStrokeColor(azulArquitectura);
        canvas.setLineWidth(0.9);

        // Sup-Izq
        canvas.moveTo(4, 4 + markLen);
        canvas.lineTo(4, 4);
        canvas.lineTo(4 + markLen, 4);

        // Sup-Der
        canvas.moveTo(size.x - 4 - markLen, 4);
        canvas.lineTo(size.x - 4, 4);
        canvas.lineTo(size.x - 4, 4 + markLen);

        // Inf-Izq
        canvas.moveTo(4, size.y - 4 - markLen);
        canvas.lineTo(4, size.y - 4);
        canvas.lineTo(4 + markLen, size.y - 4);

        // Inf-Der
        canvas.moveTo(size.x - 4 - markLen, size.y - 4);
        canvas.lineTo(size.x - 4, size.y - 4);
        canvas.lineTo(size.x - 4, size.y - 4 - markLen);

        canvas.strokePath();
      },
    );
  }

  /// Traza vectorial exacta con resolución infinita
  static pw.Widget _buildVectorPolyline({
    required List<LatLng> points,
    required List<LatLng> stops,
    required LatLngBounds bounds,
    required PdfColor lineColor,
  }) {
    if (points.isEmpty) return pw.SizedBox();

    return pw.CustomPaint(
      painter: (PdfGraphics canvas, PdfPoint size) {
        final w = size.x;
        final h = size.y;

        final minLon = bounds.west;
        final maxLon = bounds.east;
        final minLat = bounds.south;
        final maxLat = bounds.north;

        final lonSpan = (maxLon - minLon).abs();
        final latSpan = (maxLat - minLat).abs();

        if (lonSpan == 0 || latSpan == 0) return;

        PdfPoint project(LatLng p) {
          final x = ((p.longitude - minLon) / lonSpan) * w;
          final y = ((p.latitude - minLat) / latSpan) * h;
          return PdfPoint(x, y);
        }

        // 1. Halo blanco de contraste
        canvas.setStrokeColor(PdfColors.white);
        canvas.setLineWidth(5.5);
        final firstPt = project(points.first);
        canvas.moveTo(firstPt.x, firstPt.y);
        for (int i = 1; i < points.length; i++) {
          final pt = project(points[i]);
          canvas.lineTo(pt.x, pt.y);
        }
        canvas.strokePath();

        // 2. Traza oficial
        canvas.setStrokeColor(lineColor);
        canvas.setLineWidth(3.2);
        canvas.moveTo(firstPt.x, firstPt.y);
        for (int i = 1; i < points.length; i++) {
          final pt = project(points[i]);
          canvas.lineTo(pt.x, pt.y);
        }
        canvas.strokePath();

        // 3. Paradas intermedias
        canvas.setFillColor(lineColor);
        canvas.setStrokeColor(PdfColors.white);
        canvas.setLineWidth(1.2);
        for (final stop in stops) {
          final spt = project(stop);
          canvas.drawEllipse(spt.x, spt.y, 3.5, 3.5);
          canvas.fillPath();
          canvas.drawEllipse(spt.x, spt.y, 3.5, 3.5);
          canvas.strokePath();
        }

        // 4. Cabecera Inicial (Verde)
        canvas.setFillColor(const PdfColor(0.1, 0.65, 0.2));
        canvas.setStrokeColor(PdfColors.white);
        canvas.setLineWidth(2.0);
        canvas.drawEllipse(firstPt.x, firstPt.y, 7.0, 7.0);
        canvas.fillPath();
        canvas.drawEllipse(firstPt.x, firstPt.y, 7.0, 7.0);
        canvas.strokePath();

        // 5. Terminal de Destino (Granate)
        final lastPt = project(points.last);
        canvas.setFillColor(granateLanus);
        canvas.setStrokeColor(PdfColors.white);
        canvas.setLineWidth(2.0);
        canvas.drawEllipse(lastPt.x, lastPt.y, 7.0, 7.0);
        canvas.fillPath();
        canvas.drawEllipse(lastPt.x, lastPt.y, 7.0, 7.0);
        canvas.strokePath();
      },
    );
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
                // Círculo concéntrico técnico
                canvas.setStrokeColor(grisLineaTecnica);
                canvas.setLineWidth(0.6);
                canvas.drawEllipse(size.x / 2, size.y * 0.45, size.x * 0.45, size.x * 0.45);
                canvas.strokePath();

                // Flecha Norte
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

  /// Escala gráfica métrica estilo arquitecto
  static pw.Widget _buildGraphicScale(LatLngBounds bounds, double mapWidthPoints) {
    final metersAcross = GeoUtils.distanceMeters(
      (bounds.north + bounds.south) / 2.0,
      bounds.west,
      (bounds.north + bounds.south) / 2.0,
      bounds.east,
    );

    if (metersAcross <= 0) return pw.SizedBox();

    final metersPerPoint = metersAcross / mapWidthPoints;
    double scaleMeters = 1000.0;
    if (metersAcross > 15000) {
      scaleMeters = 5000.0;
    } else if (metersAcross > 8000) {
      scaleMeters = 2000.0;
    } else if (metersAcross < 3000) {
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

  /// Carátula de Plano de Arquitectura y Urbanismo (Title Block)
  static pw.Widget _buildArchitecturalCarature(
    CartographicRouteData data,
    CartographicSheetFormat format,
    double height,
    PdfColor lineColor,
  ) {
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
              padding: const pw.EdgeInsets.all(7),
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
                          color: lineColor,
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

          // 2. Ficha Técnica y Cómputo de Traza
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(7),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: grisLineaTecnica, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricRow('Longitud Total:', '${data.distanceKm.toStringAsFixed(2)} km', fontSizeVal),
                  _buildMetricRow('Paradas Registradas:', '${data.stopPoints.length}', fontSizeVal),
                  _buildMetricRow('Puntos GPS WGS-84:', '${data.polylinePoints.length}', fontSizeVal),
                  _buildMetricRow('Fecha de Emisión:', DateFormat('dd/MM/yyyy HH:mm').format(data.date), fontSizeVal),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 6),

          // 3. Cuadro de Firmas Técnicas y Aprobación
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: grisLineaTecnica, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  _buildSignatureBox('RELEVÓ', data.inspectorName ?? 'Inspector Técnico', fontSizeVal),
                  pw.SizedBox(width: 3),
                  _buildSignatureBox('REVISÓ', 'Dpto. de Movilidad', fontSizeVal),
                  pw.SizedBox(width: 3),
                  _buildSignatureBox('APROBÓ', 'Subsecretaría Planificación', fontSizeVal),
                ],
              ),
            ),
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

  static pw.Widget _buildSignatureBox(String role, String entity, double fontSize) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              role,
              style: pw.TextStyle(fontSize: fontSize * 0.72, fontWeight: pw.FontWeight.bold, color: granateLanus),
            ),
            pw.Container(
              height: 18,
              alignment: pw.Alignment.bottomCenter,
              child: pw.Container(
                height: 0.5,
                color: PdfColors.grey400,
                margin: const pw.EdgeInsets.symmetric(horizontal: 2),
              ),
            ),
            pw.Text(
              entity,
              style: pw.TextStyle(fontSize: fontSize * 0.62, color: PdfColors.grey600),
              textAlign: pw.TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
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
    MapboxStyle mapboxStyle = MapboxStyle.lightArchitectural,
  }) async {
    final bytes = await generateSheetBytes(
      data: data,
      format: format,
      isLandscape: isLandscape,
      includeBasemap: includeBasemap,
      mapboxStyle: mapboxStyle,
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
}
