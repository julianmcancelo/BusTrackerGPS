import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';

class MapTileComposer {
  static const String _tileUrlTemplate = 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
  static const String _osmFallbackTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Descarga y compone un mapa base para el Bounding Box dado con las dimensiones especificadas.
  static Future<Uint8List?> composeBasemap({
    required LatLngBounds bounds,
    required int targetWidthPx,
    required int targetHeightPx,
  }) async {
    try {
      // Determina el zoom óptimo para cubrir el bounding box con resolución suficiente
      final zoom = _calculateOptimalZoom(bounds, targetWidthPx, targetHeightPx);

      final minX = _lonToTileX(bounds.west, zoom);
      final maxX = _lonToTileX(bounds.east, zoom);
      final minY = _latToTileY(bounds.north, zoom);
      final maxY = _latToTileY(bounds.south, zoom);

      // Limita la cantidad de teselas para no sobrecargar memoria ni tiempo de espera (máx 36 teselas)
      final countX = (maxX - minX + 1);
      final countY = (maxY - minY + 1);
      if (countX * countY > 40 || countX <= 0 || countY <= 0) {
        return null;
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // Fondo papel cartográfico claro
      final bgPaint = ui.Paint()..color = const ui.Color(0xFFF8F9FA);
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, targetWidthPx.toDouble(), targetHeightPx.toDouble()),
        bgPaint,
      );

      // Bounding box en píxeles mundiales de Web Mercator al zoom calculado
      final worldLeft = _lonToWorldPx(bounds.west, zoom);
      final worldRight = _lonToWorldPx(bounds.east, zoom);
      final worldTop = _latToWorldPx(bounds.north, zoom);
      final worldBottom = _latToWorldPx(bounds.south, zoom);

      final worldWidth = (worldRight - worldLeft).abs();
      final worldHeight = (worldBottom - worldTop).abs();

      if (worldWidth == 0 || worldHeight == 0) return null;

      final scaleX = targetWidthPx / worldWidth;
      final scaleY = targetHeightPx / worldHeight;
      // Usar escala uniforme para preservar aspecto cartográfico
      final scale = math.min(scaleX, scaleY);
      final offsetX = (targetWidthPx - (worldWidth * scale)) / 2.0;
      final offsetY = (targetHeightPx - (worldHeight * scale)) / 2.0;

      // Descarga paralela de teselas
      final tileFutures = <Future<_TileData?>>[];
      for (int tx = minX; tx <= maxX; tx++) {
        for (int ty = minY; ty <= maxY; ty++) {
          tileFutures.add(_fetchTile(tx, ty, zoom));
        }
      }

      final downloadedTiles = await Future.wait(tileFutures).timeout(
        const Duration(seconds: 8),
        onTimeout: () => [],
      );

      for (final t in downloadedTiles) {
        if (t == null) continue;
        final tileWorldX = t.x * 256.0;
        final tileWorldY = t.y * 256.0;

        final drawX = offsetX + (tileWorldX - worldLeft) * scale;
        final drawY = offsetY + (tileWorldY - worldTop) * scale;
        final drawW = 256.0 * scale;
        final drawH = 256.0 * scale;

        final src = ui.Rect.fromLTWH(0, 0, t.image.width.toDouble(), t.image.height.toDouble());
        final dst = ui.Rect.fromLTWH(drawX, drawY, drawW, drawH);
        canvas.drawImageRect(t.image, src, dst, ui.Paint());
      }

      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(targetWidthPx, targetHeightPx);
      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  static Future<_TileData?> _fetchTile(int x, int y, int z) async {
    try {
      final url = _tileUrlTemplate
          .replaceAll('{z}', z.toString())
          .replaceAll('{x}', x.toString())
          .replaceAll('{y}', y.toString());

      final client = http.Client();
      http.Response response;
      try {
        response = await client.get(
          Uri.parse(url),
          headers: {'User-Agent': 'LanusDigitalCartografia/1.0'},
        ).timeout(const Duration(seconds: 4));
      } catch (_) {
        final fallbackUrl = _osmFallbackTemplate
            .replaceAll('{z}', z.toString())
            .replaceAll('{x}', x.toString())
            .replaceAll('{y}', y.toString());
        response = await client.get(
          Uri.parse(fallbackUrl),
          headers: {'User-Agent': 'LanusDigitalCartografia/1.0'},
        ).timeout(const Duration(seconds: 4));
      } finally {
        client.close();
      }

      if (response.statusCode == 200) {
        final completer = Completer<ui.Image>();
        ui.decodeImageFromList(response.bodyBytes, (img) {
          completer.complete(img);
        });
        final image = await completer.future.timeout(const Duration(seconds: 3));
        return _TileData(x: x, y: y, image: image);
      }
    } catch (_) {}
    return null;
  }

  static int _calculateOptimalZoom(LatLngBounds bounds, int widthPx, int heightPx) {
    for (int z = 16; z >= 11; z--) {
      final minX = _lonToTileX(bounds.west, z);
      final maxX = _lonToTileX(bounds.east, z);
      final minY = _latToTileY(bounds.north, z);
      final maxY = _latToTileY(bounds.south, z);
      final count = (maxX - minX + 1) * (maxY - minY + 1);
      if (count <= 25) {
        return z;
      }
    }
    return 13;
  }

  static int _lonToTileX(double lon, int z) {
    return ((lon + 180.0) / 360.0 * (1 << z)).floor();
  }

  static int _latToTileY(double lat, int z) {
    final latRad = lat * math.pi / 180.0;
    return ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * (1 << z)).floor();
  }

  static double _lonToWorldPx(double lon, int z) {
    return (lon + 180.0) / 360.0 * (256.0 * (1 << z));
  }

  static double _latToWorldPx(double lat, int z) {
    final latRad = lat * math.pi / 180.0;
    return (1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * (256.0 * (1 << z));
  }
}

class _TileData {
  final int x;
  final int y;
  final ui.Image image;
  _TileData({required this.x, required this.y, required this.image});
}
