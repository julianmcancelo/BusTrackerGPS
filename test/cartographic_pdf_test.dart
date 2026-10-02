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

    test('generates valid PDF bytes with Hoja de Ruta banner and directional chevrons', () async {
      final routeWithStreets = CartographicRouteData(
        lineNumber: '520',
        lineName: 'Micro Ómnibus Lanús',
        branchName: 'Ramal B',
        direction: 'AMBOS SENTIDOS',
        idaPoints: const [
          LatLng(-34.7000, -58.3900),
          LatLng(-34.7050, -58.3950),
          LatLng(-34.7100, -58.4000),
          LatLng(-34.7150, -58.4050),
          LatLng(-34.7200, -58.4100),
        ],
        vueltaPoints: const [
          LatLng(-34.7200, -58.4100),
          LatLng(-34.7150, -58.4050),
          LatLng(-34.7100, -58.4000),
          LatLng(-34.7050, -58.3950),
          LatLng(-34.7000, -58.3900),
        ],
        idaStreets: const ['Av. Hipólito Yrigoyen', 'Av. 25 de Mayo', 'Av. San Martín', 'Eva Perón'],
        vueltaStreets: const ['Eva Perón', 'Cnel. D\'Elía', 'Presidente Perón', 'Av. Hipólito Yrigoyen'],
        distanceKm: 16.8,
        idaDistanceKm: 8.4,
        vueltaDistanceKm: 8.4,
        date: DateTime(2026, 10, 1, 17, 30),
      );

      final bytes = await CartographicPdfService.generateSheetBytes(
        data: routeWithStreets,
        format: CartographicSheetFormat.a3,
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

    test('generates multi-page booklet PDF for multiple branches', () async {
      final branch1 = CartographicRouteData(
        lineNumber: '520',
        lineName: 'Micro Ómnibus Lanús',
        branchName: 'Ramal 1 (Estación Lanús - Valentín Alsina)',
        direction: 'AMBOS SENTIDOS',
        idaPoints: const [LatLng(-34.700, -58.390), LatLng(-34.705, -58.395)],
        vueltaPoints: const [LatLng(-34.705, -58.395), LatLng(-34.700, -58.390)],
        distanceKm: 8.5,
        date: DateTime(2026, 10, 2),
      );

      final branch2 = CartographicRouteData(
        lineNumber: '520',
        lineName: 'Micro Ómnibus Lanús',
        branchName: 'Ramal 2 (Lanús - Villa Obrera)',
        direction: 'AMBOS SENTIDOS',
        idaPoints: const [LatLng(-34.700, -58.390), LatLng(-34.712, -58.380)],
        vueltaPoints: const [LatLng(-34.712, -58.380), LatLng(-34.700, -58.390)],
        distanceKm: 11.2,
        date: DateTime(2026, 10, 2),
      );

      final branch3 = CartographicRouteData(
        lineNumber: '520',
        lineName: 'Micro Ómnibus Lanús',
        branchName: 'Ramal 3 (Lanús - Monte Chingolo)',
        direction: 'AMBOS SENTIDOS',
        idaPoints: const [LatLng(-34.700, -58.390), LatLng(-34.725, -58.370)],
        vueltaPoints: const [LatLng(-34.725, -58.370), LatLng(-34.700, -58.390)],
        distanceKm: 14.0,
        date: DateTime(2026, 10, 2),
      );

      final progressReports = <int>[];
      final bytes = await CartographicPdfService.generateMultiBranchBytes(
        branchesData: [branch1, branch2, branch3],
        format: CartographicSheetFormat.a4,
        isLandscape: true,
        includeBasemap: false,
        mode: MultiBranchExportMode.multiPageBooklet,
        onProgress: (current, total, status) {
          progressReports.add(current);
        },
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
      expect(progressReports, equals([1, 2, 3]));
    });

    test('generates single consolidated sheet PDF with all branches overlay', () async {
      final branch1 = CartographicRouteData(
        lineNumber: '520',
        lineName: 'Micro Ómnibus Lanús',
        branchName: 'Ramal 1',
        direction: 'AMBOS SENTIDOS',
        idaPoints: const [LatLng(-34.700, -58.390), LatLng(-34.705, -58.395)],
        vueltaPoints: const [LatLng(-34.705, -58.395), LatLng(-34.700, -58.390)],
        distanceKm: 8.5,
        date: DateTime(2026, 10, 2),
      );

      final branch2 = CartographicRouteData(
        lineNumber: '520',
        lineName: 'Micro Ómnibus Lanús',
        branchName: 'Ramal 2',
        direction: 'AMBOS SENTIDOS',
        idaPoints: const [LatLng(-34.700, -58.390), LatLng(-34.712, -58.380)],
        vueltaPoints: const [LatLng(-34.712, -58.380), LatLng(-34.700, -58.390)],
        distanceKm: 11.2,
        date: DateTime(2026, 10, 2),
      );

      final bytes = await CartographicPdfService.generateMultiBranchBytes(
        branchesData: [branch1, branch2],
        format: CartographicSheetFormat.a3,
        isLandscape: true,
        includeBasemap: false,
        mode: MultiBranchExportMode.singleConsolidatedSheet,
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('falls back gracefully to single sheet when 1 branch provided', () async {
      final single = CartographicRouteData(
        lineNumber: '283',
        lineName: 'Compañía Andrade',
        branchName: 'Ramal Único',
        direction: 'IDA',
        polylinePoints: const [LatLng(-34.700, -58.390), LatLng(-34.710, -58.400)],
        distanceKm: 7.0,
        date: DateTime(2026, 10, 2),
      );

      final bytes = await CartographicPdfService.generateMultiBranchBytes(
        branchesData: [single],
        format: CartographicSheetFormat.a4,
        isLandscape: true,
        includeBasemap: false,
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('loads official Lanus boundary points from json', () async {
      final boundaryPoints = await CartographicPdfService.loadLanusBoundaryPoints();
      expect(boundaryPoints, isNotEmpty);
      expect(boundaryPoints.length, greaterThan(100));
      // First point should be around Lanús boundary (-34.68 to -34.74 lat, -58.33 to -58.45 lon)
      expect(boundaryPoints.first.latitude, inInclusiveRange(-34.76, -34.64));
      expect(boundaryPoints.first.longitude, inInclusiveRange(-58.48, -58.32));
    });

    test('generates valid PDF with Lanus municipal boundary enabled and disabled', () async {
      final bytesWithBoundary = await CartographicPdfService.generateSheetBytes(
        data: sampleRouteData,
        format: CartographicSheetFormat.a3,
        includeBasemap: false,
        includeLanusBoundary: true,
      );
      expect(bytesWithBoundary, isA<Uint8List>());
      expect(bytesWithBoundary.isNotEmpty, isTrue);

      final bytesWithoutBoundary = await CartographicPdfService.generateSheetBytes(
        data: sampleRouteData,
        format: CartographicSheetFormat.a3,
        includeBasemap: false,
        includeLanusBoundary: false,
      );
      expect(bytesWithoutBoundary, isA<Uint8List>());
      expect(bytesWithoutBoundary.isNotEmpty, isTrue);
    });

    test('generates valid PDF with custom layer options (metrics off, stops off)', () async {
      final bytes = await CartographicPdfService.generateSheetBytes(
        data: sampleRouteData,
        format: CartographicSheetFormat.a4,
        includeBasemap: false,
        includeStops: false,
        includeOperationalMetrics: false,
        includeLanusBoundary: true,
      );
      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
    });

    test('CartographicRouteData automatically derives return trajectory for AMBOS when only ida is supplied', () {
      final route = CartographicRouteData(
        lineNumber: '520',
        lineName: 'Micro Ómnibus Lanús',
        branchName: 'Ramal B',
        direction: 'AMBOS',
        polylinePoints: const [
          LatLng(-34.7050, -58.3920),
          LatLng(-34.7080, -58.3890),
          LatLng(-34.7120, -58.3850),
        ],
        distanceKm: 10.0,
        date: DateTime.now(),
      );

      expect(route.hasIda, isTrue);
      expect(route.hasVuelta, isTrue);
      expect(route.effectiveIdaPoints.length, equals(3));
      expect(route.effectiveVueltaPoints.length, equals(3));
      // First point of Vuelta should be the last point of Ida
      expect(route.effectiveVueltaPoints.first, equals(const LatLng(-34.7120, -58.3850)));
      expect(route.effectiveIdaDistanceKm, equals(5.0));
      expect(route.effectiveVueltaDistanceKm, equals(5.0));
    });

    test('generates valid PDF bytes with both parallel lanes for IDA and VUELTA', () async {
      final route = CartographicRouteData(
        lineNumber: '520',
        lineName: 'Micro Ómnibus Lanús',
        branchName: 'Ramal B',
        direction: 'AMBOS',
        idaPoints: const [
          LatLng(-34.7050, -58.3920),
          LatLng(-34.7080, -58.3890),
          LatLng(-34.7120, -58.3850),
        ],
        vueltaPoints: const [
          LatLng(-34.7120, -58.3850),
          LatLng(-34.7080, -58.3890),
          LatLng(-34.7050, -58.3920),
        ],
        distanceKm: 10.0,
        idaDistanceKm: 5.0,
        vueltaDistanceKm: 5.0,
        date: DateTime.now(),
      );

      final bytes = await CartographicPdfService.generateSheetBytes(
        data: route,
        format: CartographicSheetFormat.a3,
        includeBasemap: false,
      );
      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
    });
  });
}
