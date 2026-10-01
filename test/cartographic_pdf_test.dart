import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:pdf/pdf.dart';
import 'package:bitacora_gps/features/cartography/services/cartographic_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CartographicPdfService', () {
    final sampleRouteData = CartographicRouteData(
      lineNumber: '520',
      lineName: 'Micro Ómnibus Lanús',
      branchName: 'Ramal B (Estación Lanús - Hospital Vecinal)',
      direction: 'IDA',
      polylinePoints: const [
        LatLng(-34.7050, -58.3920),
        LatLng(-34.7080, -58.3890),
        LatLng(-34.7120, -58.3850),
        LatLng(-34.7160, -58.3810),
      ],
      stopPoints: const [
        LatLng(-34.7050, -58.3920),
        LatLng(-34.7120, -58.3850),
        LatLng(-34.7160, -58.3810),
      ],
      distanceKm: 8.45,
      inspectorName: 'Inspector Juan Pérez (Leg. 4022)',
      internalNumber: '42',
      domain: 'AF123CD',
      date: DateTime(2026, 10, 1, 14, 30),
      routeNotes: 'Relevamiento de Campo Oficial · Municipio de Lanús',
    );

    test('generates valid PDF bytes for A4 format', () async {
      final bytes = await CartographicPdfService.generateSheetBytes(
        data: sampleRouteData,
        format: CartographicSheetFormat.a4,
        isLandscape: true,
        includeBasemap: false, // offline test
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
      // PDF header signature check: %PDF-
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('generates valid PDF bytes for A3 format', () async {
      final bytes = await CartographicPdfService.generateSheetBytes(
        data: sampleRouteData,
        format: CartographicSheetFormat.a3,
        isLandscape: true,
        includeBasemap: false,
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('generates valid PDF bytes for giant plotter A0 format', () async {
      final bytes = await CartographicPdfService.generateSheetBytes(
        data: sampleRouteData,
        format: CartographicSheetFormat.a0,
        isLandscape: true,
        includeBasemap: false,
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('generates valid PDF bytes with both IDA (solid) and VUELTA (dashed)', () async {
      final dualRouteData = CartographicRouteData(
        lineNumber: '283',
        lineName: 'Compañía Andrade',
        branchName: 'Ramal B1 (Puente La Noria - Lanús)',
        direction: 'AMBOS SENTIDOS',
        idaPoints: const [
          LatLng(-34.7000, -58.3900),
          LatLng(-34.7050, -58.3950),
          LatLng(-34.7100, -58.4000),
        ],
        vueltaPoints: const [
          LatLng(-34.7100, -58.4000),
          LatLng(-34.7060, -58.3940),
          LatLng(-34.7000, -58.3900),
        ],
        stopPoints: const [
          LatLng(-34.7000, -58.3900),
          LatLng(-34.7050, -58.3950),
          LatLng(-34.7100, -58.4000),
        ],
        distanceKm: 18.2,
        idaDistanceKm: 9.3,
        vueltaDistanceKm: 8.9,
        date: DateTime(2026, 10, 1, 15, 0),
        routeNotes: 'Relevamiento de Ida y Vuelta con Simbología Oficial',
      );

      expect(dualRouteData.hasIda, isTrue);
      expect(dualRouteData.hasVuelta, isTrue);
      expect(dualRouteData.effectiveIdaPoints.length, equals(3));
      expect(dualRouteData.effectiveVueltaPoints.length, equals(3));

      final bytes = await CartographicPdfService.generateSheetBytes(
        data: dualRouteData,
        format: CartographicSheetFormat.a3,
        isLandscape: true,
        includeBasemap: false,
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('generates valid PDF bytes for VUELTA only', () async {
      final vueltaData = CartographicRouteData(
        lineNumber: '520',
        lineName: 'Micro Ómnibus Lanús',
        branchName: 'Ramal A',
        direction: 'VUELTA',
        vueltaPoints: const [
          LatLng(-34.7160, -58.3810),
          LatLng(-34.7120, -58.3850),
          LatLng(-34.7050, -58.3920),
        ],
        distanceKm: 8.5,
        vueltaDistanceKm: 8.5,
        date: DateTime(2026, 10, 1, 16, 0),
      );

      expect(vueltaData.hasIda, isFalse);
      expect(vueltaData.hasVuelta, isTrue);

      final bytes = await CartographicPdfService.generateSheetBytes(
        data: vueltaData,
        format: CartographicSheetFormat.a4,
        isLandscape: true,
        includeBasemap: false,
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('PdfGraphics dash pattern check', () {
      final doc = PdfDocument();
      final page = PdfPage(doc, pageFormat: const PdfPageFormat(200, 200));
      final g = page.getGraphics();
      g.setLineDashPattern(const [6, 3], 0);
      g.setLineDashPattern();
    });
  });
}
