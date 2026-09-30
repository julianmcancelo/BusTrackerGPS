import 'dart:io';
import 'dart:math' as math;
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../database/database.dart';

class OfflineMapsService {
  final AppDatabase db;
  OfflineMapsService(this.db);

  Stream<List<OfflineMapRegionEntry>> watchRegions() {
    return db.select(db.offlineMapRegions).watch();
  }

  static int tileCountForRegion({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
    required int minZoom,
    required int maxZoom,
  }) {
    int total = 0;
    for (int z = minZoom; z <= maxZoom; z++) {
      final p1 = _latLngToTile(minLat, minLng, z);
      final p2 = _latLngToTile(maxLat, maxLng, z);

      final minX = math.min(p1.x, p2.x);
      final maxX = math.max(p1.x, p2.x);
      final minY = math.min(p1.y, p2.y);
      final maxY = math.max(p1.y, p2.y);

      total += ((maxX - minX + 1) * (maxY - minY + 1));
    }
    return total;
  }

  static double estimateSizeBytes(int tileCount) {
    return tileCount * 15.0 * 1024.0; // ~15 KB per tile average
  }

  Future<int> createRegion({
    required String name,
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
    required int minZoom,
    required int maxZoom,
  }) {
    return db.into(db.offlineMapRegions).insert(
          OfflineMapRegionsCompanion.insert(
            name: name,
            minLat: minLat,
            minLng: minLng,
            maxLat: maxLat,
            maxLng: maxLng,
            minZoom: minZoom,
            maxZoom: maxZoom,
          ),
        );
  }

  Future<void> downloadRegionTiles({
    required int regionId,
    required Function(int downloaded, int total) onProgress,
  }) async {
    final region = await (db.select(db.offlineMapRegions)..where((t) => t.id.equals(regionId))).getSingle();
    final appDir = await getApplicationDocumentsDirectory();
    final tilesDir = Directory(p.join(appDir.path, 'offline_tiles', 'region_${region.id}'));
    if (!await tilesDir.exists()) {
      await tilesDir.create(recursive: true);
    }

    int totalTiles = tileCountForRegion(
      minLat: region.minLat,
      minLng: region.minLng,
      maxLat: region.maxLat,
      maxLng: region.maxLng,
      minZoom: region.minZoom,
      maxZoom: region.maxZoom,
    );

    int downloaded = 0;
    int totalBytes = 0;

    for (int z = region.minZoom; z <= region.maxZoom; z++) {
      final p1 = _latLngToTile(region.minLat, region.minLng, z);
      final p2 = _latLngToTile(region.maxLat, region.maxLng, z);

      final minX = math.min(p1.x, p2.x);
      final maxX = math.max(p1.x, p2.x);
      final minY = math.min(p1.y, p2.y);
      final maxY = math.max(p1.y, p2.y);

      for (int x = minX; x <= maxX; x++) {
        for (int y = minY; y <= maxY; y++) {
          final tileFile = File(p.join(tilesDir.path, '$z', '$x', '$y.png'));
          if (!await tileFile.exists()) {
            await tileFile.create(recursive: true);
            try {
              final url = Uri.parse('https://tile.openstreetmap.org/$z/$x/$y.png');
              final res = await http.get(url, headers: {'User-Agent': 'BitacoraGPS/1.0'});
              if (res.statusCode == 200) {
                await tileFile.writeAsBytes(res.bodyBytes);
                totalBytes += res.bodyBytes.length;
              }
            } catch (_) {}
          } else {
            totalBytes += await tileFile.length();
          }
          downloaded++;
          onProgress(downloaded, totalTiles);
        }
      }
    }

    await (db.update(db.offlineMapRegions)..where((t) => t.id.equals(regionId))).write(
      OfflineMapRegionsCompanion(
        isDownloaded: const Value(true),
        mbTilesPath: Value(tilesDir.path),
        sizeBytes: Value(totalBytes),
      ),
    );
  }

  Future<void> deleteRegion(int regionId) async {
    final region = await (db.select(db.offlineMapRegions)..where((t) => t.id.equals(regionId))).getSingleOrNull();
    if (region?.mbTilesPath != null) {
      final dir = Directory(region!.mbTilesPath!);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
    await (db.delete(db.offlineMapRegions)..where((t) => t.id.equals(regionId))).go();
  }

  static ({int x, int y}) _latLngToTile(double lat, double lng, int zoom) {
    final n = math.pow(2, zoom);
    final x = ((lng + 180.0) / 360.0 * n).floor();
    final latRad = lat * math.pi / 180.0;
    final y = ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * n).floor();
    return (x: x, y: y);
  }
}
