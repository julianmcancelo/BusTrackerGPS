import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:pdf/pdf.dart';

/// Proyector isométrico unificado Web Mercator (EPSG:3857)
/// Garantiza coincidencia matemática exacta entre el mosaico de imagen de fondo y el trazado vectorial del PDF.
class MercatorViewportProjection {
  final LatLngBounds bounds;
  final double width;
  final double height;
  late final double scale;
  late final double offsetX;
  late final double offsetY;
  late final double worldLeft;
  late final double worldTop;
  late final double worldWidth;
  late final double worldHeight;

  MercatorViewportProjection({
    required this.bounds,
    required this.width,
    required this.height,
  }) {
    worldLeft = lonToWorld(bounds.west);
    final worldRight = lonToWorld(bounds.east);
    worldTop = latToWorld(bounds.north);
    final worldBottom = latToWorld(bounds.south);

    worldWidth = (worldRight - worldLeft).abs();
    worldHeight = (worldBottom - worldTop).abs();

    if (worldWidth > 0 && worldHeight > 0) {
      final scaleX = width / worldWidth;
      final scaleY = height / worldHeight;
      // Escala isométrica uniforme: preserva la geometría y evita cualquier deformación
      scale = math.min(scaleX, scaleY);
      offsetX = (width - (worldWidth * scale)) / 2.0;
      offsetY = (height - (worldHeight * scale)) / 2.0;
    } else {
      scale = 1.0;
      offsetX = 0.0;
      offsetY = 0.0;
    }
  }

  static double lonToWorld(double lon) {
    return (lon + 180.0) / 360.0 * 256.0;
  }

  static double latToWorld(double lat) {
    // Fórmula oficial Web Mercator (EPSG:3857)
    final clampedLat = lat.clamp(-85.05112878, 85.05112878);
    final latRad = clampedLat * math.pi / 180.0;
    return (1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * 256.0;
  }

  /// Proyecta a píxeles de imagen (origen arriba-izquierda, como en pantalla/Canvas)
  PdfPoint projectToImage(LatLng p) {
    final wx = lonToWorld(p.longitude);
    final wy = latToWorld(p.latitude);
    final x = offsetX + (wx - worldLeft) * scale;
    final y = offsetY + (wy - worldTop) * scale;
    return PdfPoint(x, y);
  }

  /// Proyecta a coordenadas de PDF (origen abajo-izquierda, Y invertido respecto a pantalla)
  PdfPoint projectToPdf(LatLng p) {
    final wx = lonToWorld(p.longitude);
    final wy = latToWorld(p.latitude);
    final x = offsetX + (wx - worldLeft) * scale;
    final y = height - (offsetY + (wy - worldTop) * scale);
    return PdfPoint(x, y);
  }
}
