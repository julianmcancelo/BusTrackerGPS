import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
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
  });
}
