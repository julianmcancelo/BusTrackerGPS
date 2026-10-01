import 'dart:io';
import 'dart:typed_data';
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
  // Colores institucionales de Lanús
  static const PdfColor granateLanus = PdfColor.fromInt(0xFF7B1828);
  static const PdfColor azulInstitucional = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor grisFondo = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor grisBorde = PdfColor.fromInt(0xFFCBD5E1);

  /// Genera la lámina cartográfica oficial en el formato de papel y orientación seleccionados.
  static Future<Uint8List> generateSheetBytes({
    required CartographicRouteData data,
    CartographicSheetFormat format = CartographicSheetFormat.a3,
    bool isLandscape = true,
    bool includeBasemap = true,
  }) async {
    final pdf = pw.Document();
    final pageFormat = format.toPdfPageFormat(isLandscape: isLandscape);

    // Calcular Bounding Box de la traza con margen de seguridad (12%)
    final points = data.polylinePoints;
    final bounds = _calculateSafeBounds(points);

    // Dimensiones en puntos de la página
    final pageWidth = pageFormat.width;
    final pageHeight = pageFormat.height;
    final margin = format == CartographicSheetFormat.a0 || format == CartographicSheetFormat.a1 ? 40.0 : 24.0;

    final contentWidth = pageWidth - (margin * 2);
    final contentHeight = pageHeight - (margin * 2);

    // Área del mapa dentro de la lámina (reserva espacio para encabezado y carátula inferior)
    final headerHeight = format == CartographicSheetFormat.a0 ? 110.0 : (format == CartographicSheetFormat.a1 ? 95.0 : 70.0);
    final caratureHeight = format == CartographicSheetFormat.a0 ? 180.0 : (format == CartographicSheetFormat.a1 ? 150.0 : 110.0);
    final mapHeight = contentHeight - headerHeight - caratureHeight - 16.0;

    // Descargar mosaico base si se solicitó
    Uint8List? basemapBytes;
    if (includeBasemap && points.isNotEmpty) {
      basemapBytes = await MapTileComposer.composeBasemap(
        bounds: bounds,
        targetWidthPx: (contentWidth * 1.5).toInt(),
        targetHeightPx: (mapHeight * 1.5).toInt(),
      );
    }

    final lineColorHex = TransportUtils.getLineColor(data.lineNumber).toARGB32();
    final linePdfColor = PdfColor.fromInt(lineColorHex);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(margin),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: granateLanus, width: 2.0),
              color: PdfColors.white,
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: grisBorde, width: 0.8),
                ),
                child: pw.Column(
                  children: [
                    // 1. Encabezado Oficial Institucional
                    _buildInstitutionalHeader(data, format, headerHeight),

                    // 2. Viewport del Mapa Cartográfico
                    pw.Expanded(
                      child: pw.Container(
                        width: double.infinity,
                        margin: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: grisBorde, width: 1.0),
                          color: grisFondo,
                        ),
                        child: pw.Stack(
                          children: [
                            // Fondo raster callejero
                            if (basemapBytes != null)
                              pw.Positioned.fill(
                                child: pw.Image(
                                  pw.MemoryImage(basemapBytes),
                                  fit: pw.BoxFit.fill,
                                ),
                              ),

                            // Grilla de coordenadas UTM / Geográficas
                            pw.Positioned.fill(
                              child: _buildCoordinateGrid(bounds),
                            ),

                            // Trazado Vectorial de la Traza y Paradas
                            pw.Positioned.fill(
                              child: _buildVectorPolyline(
                                points: points,
                                stops: data.stopPoints,
                                bounds: bounds,
                                lineColor: linePdfColor,
                              ),
                            ),

                            // Rosa de los Vientos (Norte)
                            pw.Positioned(
                              top: 14,
                              right: 14,
                              child: _buildNorthArrow(),
                            ),

                            // Escala Gráfica Métrica
                            pw.Positioned(
                              bottom: 12,
                              left: 14,
                              child: _buildGraphicScale(bounds, contentWidth),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. Carátula Cartográfica y Cuadro de Firmas
                    _buildCaratureAndSignatures(data, format, caratureHeight, linePdfColor),
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

  /// Construye el encabezado con membrete oficial del Municipio de Lanús
  static pw.Widget _buildInstitutionalHeader(
    CartographicRouteData data,
    CartographicSheetFormat format,
    double height,
  ) {
    final isLarge = format == CartographicSheetFormat.a0 || format == CartographicSheetFormat.a1;
    final titleSize = isLarge ? 20.0 : 13.0;
    final subSize = isLarge ? 11.0 : 8.5;

    return pw.Container(
      height: height,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const pw.BoxDecoration(
        color: granateLanus,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'MUNICIPIO DE LANÚS',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: titleSize,
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'SECRETARÍA DE SEGURIDAD Y MOVILIDAD CIUDADANA · SUBSECRETARÍA DE MOVILIDAD Y TRANSPORTE URBANO',
                style: pw.TextStyle(
                  color: PdfColors.grey200,
                  fontSize: subSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'DIRECCIÓN DE TRANSPORTE Y CONTROL DE TRÁNSITO · LANÚS DIGITAL',
                style: pw.TextStyle(
                  color: PdfColors.grey300,
                  fontSize: subSize * 0.9,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'PLANO CARTOGRÁFICO OFICIAL',
                  style: pw.TextStyle(
                    color: granateLanus,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: subSize,
                  ),
                ),
                pw.Text(
                  'EXPTE: ${data.lineNumber}-${DateFormat("yyyyMMdd").format(data.date)}',
                  style: pw.TextStyle(
                    color: azulInstitucional,
                    fontSize: subSize * 0.85,
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

  /// Dibuja la traza y las paradas mediante dibujo vectorial exacto
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

        // Proyección de LatLng a coordenadas del Canvas PDF
        PdfPoint project(LatLng p) {
          final x = ((p.longitude - minLon) / lonSpan) * w;
          // En PDF, y=0 está abajo, invertimos para que Norte quede arriba
          final y = ((p.latitude - minLat) / latSpan) * h;
          return PdfPoint(x, y);
        }

        // 1. Dibuja halo blanco exterior de alto contraste
        canvas.setStrokeColor(PdfColors.white);
        canvas.setLineWidth(5.0);
        final firstPt = project(points.first);
        canvas.moveTo(firstPt.x, firstPt.y);
        for (int i = 1; i < points.length; i++) {
          final pt = project(points[i]);
          canvas.lineTo(pt.x, pt.y);
        }
        canvas.strokePath();

        // 2. Dibuja la traza oficial con el color de la línea
        canvas.setStrokeColor(lineColor);
        canvas.setLineWidth(3.0);
        canvas.moveTo(firstPt.x, firstPt.y);
        for (int i = 1; i < points.length; i++) {
          final pt = project(points[i]);
          canvas.lineTo(pt.x, pt.y);
        }
        canvas.strokePath();

        // 3. Dibuja paradas intermedias
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

        // 4. Marcador Cabecera de Inicio (Verde)
        canvas.setFillColor(const PdfColor(0.1, 0.65, 0.2));
        canvas.setStrokeColor(PdfColors.white);
        canvas.setLineWidth(2.0);
        canvas.drawEllipse(firstPt.x, firstPt.y, 7.0, 7.0);
        canvas.fillPath();
        canvas.drawEllipse(firstPt.x, firstPt.y, 7.0, 7.0);
        canvas.strokePath();

        // 5. Marcador Terminal de Destino (Rojo)
        final lastPt = project(points.last);
        canvas.setFillColor(const PdfColor(0.85, 0.15, 0.15));
        canvas.setStrokeColor(PdfColors.white);
        canvas.setLineWidth(2.0);
        canvas.drawEllipse(lastPt.x, lastPt.y, 7.0, 7.0);
        canvas.fillPath();
        canvas.drawEllipse(lastPt.x, lastPt.y, 7.0, 7.0);
        canvas.strokePath();
      },
    );
  }

  /// Grilla de coordenadas marginales
  static pw.Widget _buildCoordinateGrid(LatLngBounds bounds) {
    return pw.CustomPaint(
      painter: (PdfGraphics canvas, PdfPoint size) {
        canvas.setStrokeColor(const PdfColor(0.8, 0.85, 0.9, 0.45));
        canvas.setLineWidth(0.5);

        // Líneas verticales (longitud)
        final stepX = size.x / 5.0;
        for (int i = 1; i < 5; i++) {
          final x = stepX * i;
          canvas.moveTo(x, 0);
          canvas.lineTo(x, size.y);
        }

        // Líneas horizontales (latitud)
        final stepY = size.y / 4.0;
        for (int j = 1; j < 4; j++) {
          final y = stepY * j;
          canvas.moveTo(0, y);
          canvas.lineTo(size.x, y);
        }
        canvas.strokePath();
      },
    );
  }

  /// Rosa de los vientos (indicador de Norte)
  static pw.Widget _buildNorthArrow() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: grisBorde, width: 1.0),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('N', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: azulInstitucional)),
          pw.Container(
            width: 14,
            height: 24,
            child: pw.CustomPaint(
              painter: (PdfGraphics canvas, PdfPoint size) {
                canvas.setFillColor(granateLanus);
                canvas.moveTo(size.x / 2, size.y);
                canvas.lineTo(0, 0);
                canvas.lineTo(size.x / 2, size.y * 0.3);
                canvas.fillPath();

                canvas.setFillColor(azulInstitucional);
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

  /// Escala gráfica métrica calibrada
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
        border: pw.Border.all(color: grisBorde, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            'ESCALA GRÁFICA: ${scaleMeters >= 1000 ? "${(scaleMeters / 1000).toStringAsFixed(1)} km" : "${scaleMeters.toInt()} m"}',
            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: azulInstitucional),
          ),
          pw.SizedBox(height: 3),
          pw.Container(
            width: barWidthPoints.clamp(40.0, 160.0),
            height: 5,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: azulInstitucional, width: 1),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(child: pw.Container(color: azulInstitucional)),
                pw.Expanded(child: pw.Container(color: PdfColors.white)),
                pw.Expanded(child: pw.Container(color: azulInstitucional)),
                pw.Expanded(child: pw.Container(color: PdfColors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Carátula técnica y cuadro oficial de firmas
  static pw.Widget _buildCaratureAndSignatures(
    CartographicRouteData data,
    CartographicSheetFormat format,
    double height,
    PdfColor lineColor,
  ) {
    final isLarge = format == CartographicSheetFormat.a0 || format == CartographicSheetFormat.a1;
    final fontSizeTitle = isLarge ? 16.0 : 10.0;
    final fontSizeVal = isLarge ? 12.0 : 8.0;

    return pw.Container(
      height: height,
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
      ),
      child: pw.Row(
        children: [
          // Identificación de Línea y Ramal
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: grisBorde, width: 1.0),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: isLarge ? 60 : 44,
                    height: isLarge ? 60 : 44,
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
                          fontSize: isLarge ? 22 : 14,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          'LÍNEA ${data.lineNumber} · ${data.branchName.toUpperCase()}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: fontSizeTitle,
                            color: azulInstitucional,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'SENTIDO: ${data.direction} · ${data.lineName}',
                          style: pw.TextStyle(
                            fontSize: fontSizeVal,
                            color: PdfColors.grey700,
                          ),
                        ),
                        if (data.routeNotes != null && data.routeNotes!.isNotEmpty)
                          pw.Text(
                            'Notas: ${data.routeNotes}',
                            style: pw.TextStyle(fontSize: fontSizeVal * 0.9, color: PdfColors.grey600),
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 8),

          // Métricas Técnicas
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: grisBorde, width: 1.0),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  _buildMetricRow('Longitud de Traza:', '${data.distanceKm.toStringAsFixed(2)} km', fontSizeVal),
                  _buildMetricRow('Puntos Georreferenciados:', '${data.polylinePoints.length}', fontSizeVal),
                  _buildMetricRow('Paradas Registradas:', '${data.stopPoints.length}', fontSizeVal),
                  _buildMetricRow('Fecha Relevamiento:', DateFormat('dd/MM/yyyy HH:mm').format(data.date), fontSizeVal),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 8),

          // Cuadro de Firmas Institucionales
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: grisBorde, width: 1.0),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                children: [
                  _buildSignatureBox('RELEVÓ', data.inspectorName ?? 'Inspector Técnico', fontSizeVal),
                  pw.SizedBox(width: 4),
                  _buildSignatureBox('VERIFICÓ', 'Dirección de Transporte', fontSizeVal),
                  pw.SizedBox(width: 4),
                  _buildSignatureBox('APROBÓ', 'Sec. de Movilidad', fontSizeVal),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricRow(String label, String value, double fontSize) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize * 0.9, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold, color: azulInstitucional)),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureBox(String role, String entity, double fontSize) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
        ),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              role,
              style: pw.TextStyle(fontSize: fontSize * 0.75, fontWeight: pw.FontWeight.bold, color: granateLanus),
            ),
            pw.Container(
              height: 20,
              alignment: pw.Alignment.bottomCenter,
              child: pw.Container(
                height: 0.5,
                color: PdfColors.grey400,
                margin: const pw.EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
            pw.Text(
              entity,
              style: pw.TextStyle(fontSize: fontSize * 0.65, color: PdfColors.grey600),
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
      // Centro de Lanús por defecto
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
  }) async {
    final bytes = await generateSheetBytes(
      data: data,
      format: format,
      isLandscape: isLandscape,
      includeBasemap: includeBasemap,
    );

    final tempDir = await getTemporaryDirectory();
    final fileName = 'Plano_Lanus_${data.lineNumber}_${data.branchName}_${format.name.toUpperCase()}.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Plano Cartográfico Oficial - Línea ${data.lineNumber} (${data.branchName})',
        text: 'Plano Cartográfico Oficial emitido por Municipio de Lanús - Línea ${data.lineNumber} Ramal ${data.branchName} (${format.name.toUpperCase()})',
      ),
    );

    return file;
  }
}
