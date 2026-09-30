import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackupSummary {
  final int tripCount;
  final int pointCount;
  final int stopCount;
  final int photoCount;
  final int audioCount;

  BackupSummary({
    required this.tripCount,
    required this.pointCount,
    required this.stopCount,
    required this.photoCount,
    required this.audioCount,
  });
}

class BackupService {
  static Future<File> createFullBackupZip() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(appDocDir.path, 'bitacora_gps_db.sqlite'));

    final archive = Archive();

    if (await dbFile.exists()) {
      final dbBytes = await dbFile.readAsBytes();
      archive.addFile(ArchiveFile('database.sqlite', dbBytes.length, dbBytes));
    }

    final mediaDir = Directory(p.join(appDocDir.path, 'media'));
    if (await mediaDir.exists()) {
      final files = mediaDir.listSync(recursive: true);
      for (final f in files) {
        if (f is File) {
          final relativePath = p.relative(f.path, from: appDocDir.path);
          final bytes = await f.readAsBytes();
          archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
        }
      }
    }

    final nowStr = DateTime.now().toIso8601String().split('T').first;
    final metadata = {
      'app': 'Bitácora GPS Backup',
      'version': '1.0.0',
      'createdAt': DateTime.now().toIso8601String(),
    };
    final metaBytes = utf8.encode(jsonEncode(metadata));
    archive.addFile(ArchiveFile('backup_metadata.json', metaBytes.length, metaBytes));

    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);

    final tempDir = await getTemporaryDirectory();
    final backupFile = File(p.join(tempDir.path, 'bitacora_backup_$nowStr.zip'));
    await backupFile.writeAsBytes(zipData);

    return backupFile;
  }

  static Future<BackupSummary?> inspectBackupZip(File zipFile) async {
    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      int photos = 0;
      int audios = 0;
      bool hasDb = false;

      for (final file in archive) {
        if (file.name.contains('database.sqlite')) {
          hasDb = true;
        } else if (file.name.contains('photos/')) {
          photos++;
        } else if (file.name.contains('audio/')) {
          audios++;
        }
      }

      if (!hasDb) return null;

      return BackupSummary(
        tripCount: 1,
        pointCount: 0,
        stopCount: 0,
        photoCount: photos,
        audioCount: audios,
      );
    } catch (_) {
      return null;
    }
  }
}
