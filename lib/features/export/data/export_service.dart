import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../database/database.dart';

class ExportService {
  static Future<String> generateGeoJson({
    required TripEntry trip,
    required LineEntry line,
    required BranchEntry branch,
    required List<TrackPointEntry> trackPoints,
    required List<StopEntry> stops,
    required List<IncidentEntry> incidents,
  }) async {
    final features = <Map<String, dynamic>>[];

    final coordinates = trackPoints
        .where((p) => p.quality != 'OUTLIER')
        .map((p) => [p.longitude, p.latitude, p.altitude ?? 0.0])
        .toList();

    features.add({
      'type': 'Feature',
      'geometry': {
        'type': 'LineString',
        'coordinates': coordinates,
      },
      'properties': {
        'name': '${line.number} - ${branch.name} (${trip.direction})',
        'line': line.number,
        'branch': branch.name,
        'direction': trip.direction,
        'startedAt': trip.startedAt.toIso8601String(),
        'endedAt': trip.endedAt?.toIso8601String(),
        'distanceMeters': trip.distanceMeters,
        'durationMs': trip.durationMs,
      },
    });

    for (final s in stops) {
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [s.longitude, s.latitude],
        },
        'properties': {
          'type': 'stop',
          'sequence': s.sequence,
          'name': s.name ?? 'Parada ${s.sequence}',
          'status': s.status,
          'dwellTimeMs': s.dwellTimeMs,
          'markedAt': s.markedAt.toIso8601String(),
        },
      });
    }

    for (final inc in incidents) {
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [inc.longitude, inc.latitude],
        },
        'properties': {
          'type': 'incident',
          'incidentType': inc.type,
          'severity': inc.severity,
          'description': inc.description ?? '',
          'timestamp': inc.timestamp.toIso8601String(),
        },
      });
    }

    final geoJson = {
      'type': 'FeatureCollection',
      'features': features,
    };

    return const JsonEncoder.withIndent('  ').convert(geoJson);
  }

  static Future<String> generateGpx({
    required TripEntry trip,
    required LineEntry line,
    required BranchEntry branch,
    required List<TrackPointEntry> trackPoints,
    required List<StopEntry> stops,
    required List<IncidentEntry> incidents,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="Bitácora GPS" xmlns="http://www.topografix.com/GPX/1/1">');
    buffer.writeln('  <metadata>');
    buffer.writeln('    <name>${line.number} - ${branch.name} (${trip.direction})</name>');
    buffer.writeln('    <time>${trip.startedAt.toIso8601String()}</time>');
    buffer.writeln('  </metadata>');

    for (final s in stops) {
      buffer.writeln('  <wpt lat="${s.latitude}" lon="${s.longitude}">');
      buffer.writeln('    <name>${_escapeXml(s.name ?? "Parada ${s.sequence}")}</name>');
      buffer.writeln('    <sym>Bus Stop</sym>');
      buffer.writeln('  </wpt>');
    }

    for (final inc in incidents) {
      buffer.writeln('  <wpt lat="${inc.latitude}" lon="${inc.longitude}">');
      buffer.writeln('    <name>${_escapeXml(inc.type)}</name>');
      buffer.writeln('    <desc>${_escapeXml(inc.description ?? "")}</desc>');
      buffer.writeln('    <sym>Warning</sym>');
      buffer.writeln('  </wpt>');
    }

    buffer.writeln('  <trk>');
    buffer.writeln('    <name>${line.number} ${branch.name} ${trip.direction}</name>');
    buffer.writeln('    <trkseg>');
    for (final p in trackPoints) {
      if (p.quality == 'OUTLIER') continue;
      buffer.writeln('      <trkpt lat="${p.latitude}" lon="${p.longitude}">');
      if (p.altitude != null) buffer.writeln('        <ele>${p.altitude}</ele>');
      buffer.writeln('        <time>${p.timestamp.toIso8601String()}</time>');
      if (p.speedMps != null) buffer.writeln('        <speed>${p.speedMps}</speed>');
      buffer.writeln('      </trkpt>');
    }
    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');

    return buffer.toString();
  }

  static Future<String> generateKml({
    required TripEntry trip,
    required LineEntry line,
    required BranchEntry branch,
    required List<TrackPointEntry> trackPoints,
    required List<StopEntry> stops,
    required List<IncidentEntry> incidents,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('  <Document>');
    buffer.writeln('    <name>${line.number} - ${branch.name} (${trip.direction})</name>');

    buffer.writeln('    <Placemark>');
    buffer.writeln('      <name>Recorrido GPS</name>');
    buffer.writeln('      <LineString>');
    buffer.writeln('        <coordinates>');
    final coords = trackPoints
        .where((p) => p.quality != 'OUTLIER')
        .map((p) => '${p.longitude},${p.latitude},${p.altitude ?? 0}')
        .join(' ');
    buffer.writeln('          $coords');
    buffer.writeln('        </coordinates>');
    buffer.writeln('      </LineString>');
    buffer.writeln('    </Placemark>');

    for (final s in stops) {
      buffer.writeln('    <Placemark>');
      buffer.writeln('      <name>${_escapeXml(s.name ?? "Parada ${s.sequence}")}</name>');
      buffer.writeln('      <Point>');
      buffer.writeln('        <coordinates>${s.longitude},${s.latitude},0</coordinates>');
      buffer.writeln('      </Point>');
      buffer.writeln('    </Placemark>');
    }

    buffer.writeln('  </Document>');
    buffer.writeln('</kml>');

    return buffer.toString();
  }

  static Future<Map<String, String>> generateCsv({
    required TripEntry trip,
    required List<TrackPointEntry> trackPoints,
    required List<StopEntry> stops,
    required List<IncidentEntry> incidents,
  }) async {
    final trackCsv = StringBuffer();
    trackCsv.writeln('id,timestamp,latitude,longitude,altitude,accuracy,speedMps,bearingDegrees,quality');
    for (final p in trackPoints) {
      trackCsv.writeln('${p.id},${p.timestamp.toIso8601String()},${p.latitude},${p.longitude},${p.altitude ?? ""},${p.accuracy ?? ""},${p.speedMps ?? ""},${p.bearingDegrees ?? ""},${p.quality}');
    }

    final stopsCsv = StringBuffer();
    stopsCsv.writeln('id,sequence,markedAt,latitude,longitude,accuracy,name,status,dwellTimeMs');
    for (final s in stops) {
      stopsCsv.writeln('${s.id},${s.sequence},${s.markedAt.toIso8601String()},${s.latitude},${s.longitude},${s.accuracy ?? ""},"${s.name ?? ""}",${s.status},${s.dwellTimeMs ?? ""}');
    }

    final incCsv = StringBuffer();
    incCsv.writeln('id,timestamp,latitude,longitude,accuracy,type,severity,description');
    for (final inc in incidents) {
      incCsv.writeln('${inc.id},${inc.timestamp.toIso8601String()},${inc.latitude},${inc.longitude},${inc.accuracy ?? ""},${inc.type},${inc.severity},"${inc.description ?? ""}');
    }

    return {
      'track_points.csv': trackCsv.toString(),
      'stops.csv': stopsCsv.toString(),
      'incidents.csv': incCsv.toString(),
    };
  }

  static Future<File> generateZipPackage({
    required TripEntry trip,
    required LineEntry line,
    required BranchEntry branch,
    required List<TrackPointEntry> trackPoints,
    required List<StopEntry> stops,
    required List<IncidentEntry> incidents,
    required List<AttachmentEntry> attachments,
  }) async {
    final archive = Archive();

    final geoJson = await generateGeoJson(trip: trip, line: line, branch: branch, trackPoints: trackPoints, stops: stops, incidents: incidents);
    final gpx = await generateGpx(trip: trip, line: line, branch: branch, trackPoints: trackPoints, stops: stops, incidents: incidents);
    final kml = await generateKml(trip: trip, line: line, branch: branch, trackPoints: trackPoints, stops: stops, incidents: incidents);
    final csvMap = await generateCsv(trip: trip, trackPoints: trackPoints, stops: stops, incidents: incidents);

    archive.addFile(ArchiveFile('track.geojson', utf8.encode(geoJson).length, utf8.encode(geoJson)));
    archive.addFile(ArchiveFile('track.gpx', utf8.encode(gpx).length, utf8.encode(gpx)));
    archive.addFile(ArchiveFile('track.kml', utf8.encode(kml).length, utf8.encode(kml)));

    csvMap.forEach((filename, content) {
      archive.addFile(ArchiveFile(filename, utf8.encode(content).length, utf8.encode(content)));
    });

    final metadataJson = jsonEncode({
      'app': 'Bitácora GPS',
      'line': line.number,
      'branch': branch.name,
      'direction': trip.direction,
      'internal': trip.internalNumber,
      'domain': trip.domain,
      'startedAt': trip.startedAt.toIso8601String(),
      'endedAt': trip.endedAt?.toIso8601String(),
      'distanceMeters': trip.distanceMeters,
      'durationMs': trip.durationMs,
      'pointCount': trip.pointCount,
      'stopCount': trip.stopCount,
      'incidentCount': trip.incidentCount,
    });
    archive.addFile(ArchiveFile('metadata.json', utf8.encode(metadataJson).length, utf8.encode(metadataJson)));

    for (final att in attachments) {
      final file = File(att.filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final folder = att.type == 'PHOTO' ? 'photos' : 'audio';
        final name = file.path.split(Platform.pathSeparator).last;
        archive.addFile(ArchiveFile('$folder/$name', bytes.length, bytes));
      }
    }

    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);

    final tempDir = await getTemporaryDirectory();
    final dateStr = trip.startedAt.toIso8601String().split('T').first;
    final zipFile = File('${tempDir.path}/${line.number}_${trip.direction.toLowerCase()}_$dateStr.zip');
    await zipFile.writeAsBytes(zipData);

    return zipFile;
  }

  static Future<void> shareFile(File file, {String? text}) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: text ?? 'Recorrido GPS exportado desde Bitácora GPS',
    );
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
