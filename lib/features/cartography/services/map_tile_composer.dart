import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'cartographic_projection.dart';

enum MapboxStyle {
  lightArchitectural,
  streetsColor;

  String get label {
    switch (this) {
      case MapboxStyle.lightArchitectural:
        return 'Plano Arquitectónico (Mapbox Light)';
      case MapboxStyle.streetsColor:
        return 'Callejero Urbano (Mapbox Streets)';
    }
  }
}

class MapTileComposer {
  static const String mapboxAccessToken =
      'pk.eyJ1IjoianVsZWVoeiIsImEiOiJja2twYzd3bDAwMnE4MnZwMnEyMWJzZmdtIn0.fQRzvyRtqihBoT_c6vdR0A';

  static const String _mapboxLightTemplate =
      'https://api.mapbox.com/styles/v1/mapbox/light-v11/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxAccessToken';

  static const String _mapboxStreetsTemplate =
      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxAccessToken';

  static const String _cartoFallbackTemplate =
      'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

  /// Descarga y compone un mapa base Mapbox de alta resolución con alineación isométrica Web Mercator.
  static Future<Uint8List?> composeBasemap({
    required LatLngBounds bounds,
    required int targetWidthPx,
    required int targetHeightPx,
    MapboxStyle style = MapboxStyle.lightArchitectural,
  }) async {
    try {
      final projection = MercatorViewportProjection(
        bounds: bounds,
        width: targetWidthPx.toDouble(),
        height: targetHeightPx.toDouble(),
      );

      final zoom = _calculateOptimalZoom(bounds, targetWidthPx, targetHeightPx);

      final minX = _lonToTileX(bounds.west, zoom);
      final maxX = _lonToTileX(bounds.east, zoom);
      final minY = _latToTileY(bounds.north, zoom);
      final maxY = _latToTileY(bounds.south, zoom);

      final countX = (maxX - minX + 1);
      final countY = (maxY - minY + 1);
      if (countX * countY > 40 || countX <= 0 || countY <= 0) {
        return null;
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // Fondo papel plano arquitectónico
      final bgPaint = ui.Paint()
        ..color = style == MapboxStyle.lightArchitectural
            ? const ui.Color(0xFFF6F7F9)
            : const ui.Color(0xFFF1F5F9);
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, targetWidthPx.toDouble(), targetHeightPx.toDouble()),
        bgPaint,
      );

      // Descarga paralela de teselas Mapbox Retina (@2x)
      final tileFutures = <Future<_TileData?>>[];
      for (int tx = minX; tx <= maxX; tx++) {
        for (int ty = minY; ty <= maxY; ty++) {
          tileFutures.add(_fetchTile(tx, ty, zoom, style));
        }
      }

      final downloadedTiles = await Future.wait(tileFutures).timeout(
        const Duration(seconds: 10),
        onTimeout: () => [],
      );

      final tileWorldSpan = 256.0 / (1 << zoom);

      for (final t in downloadedTiles) {
        if (t == null) continue;
        final tileWorldLeft = t.x * tileWorldSpan;
        final tileWorldTop = t.y * tileWorldSpan;

        final drawX = projection.offsetX + (tileWorldLeft - projection.worldLeft) * projection.scale;
        final drawY = projection.offsetY + (tileWorldTop - projection.worldTop) * projection.scale;
        final drawW = tileWorldSpan * projection.scale;
        final drawH = tileWorldSpan * projection.scale;

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

  static Future<_TileData?> _fetchTile(int x, int y, int z, MapboxStyle style) async {
    try {
      final template = style == MapboxStyle.lightArchitectural
          ? _mapboxLightTemplate
          : _mapboxStreetsTemplate;

      final url = template
          .replaceAll('{z}', z.toString())
          .replaceAll('{x}', x.toString())
          .replaceAll('{y}', y.toString());

      final client = http.Client();
      http.Response response;
      try {
        response = await client.get(
          Uri.parse(url),
          headers: {'User-Agent': 'LanusDigitalCartografia/1.0'},
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        final fallbackUrl = _cartoFallbackTemplate
            .replaceAll('{z}', z.toString())
            .replaceAll('{x}', x.toString())
            .replaceAll('{y}', y.toString());
        response = await client.get(
          Uri.parse(fallbackUrl),
          headers: {'User-Agent': 'LanusDigitalCartografia/1.0'},
        ).timeout(const Duration(seconds: 5));
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
    final clampedLat = lat.clamp(-85.05112878, 85.05112878);
    final latRad = clampedLat * math.pi / 180.0;
    return ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * (1 << z)).floor();
  }
}

class _TileData {
  final int x;
  final int y;
  final ui.Image image;
  _TileData({required this.x, required this.y, required this.image});
}
