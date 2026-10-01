import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/frequency_models.dart';
import '../domain/frequency_analytics.dart';

class FrequencyCsvService {
  static Future<String> generateCsvString(FrequencySessionAuditSummary summary) async {
    final sb = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final timeFormat = DateFormat('HH:mm:ss');

    // Header metadata
    sb.writeln('INFORME OFICIAL DE AUDITORIA DE FRECUENCIAS');
    sb.writeln('Titulo;"${summary.session.title}"');
    sb.writeln('Punto de Control;"${summary.session.checkpointName}"');
    sb.writeln('Fecha Inicio;"${dateFormat.format(summary.session.startedAt)}"');
    sb.writeln('Fecha Fin;"${summary.session.endedAt != null ? dateFormat.format(summary.session.endedAt!) : 'En curso'}"');
    sb.writeln('Auditor;"${summary.session.auditorName ?? 'Inspector de Transporte'}"');
    sb.writeln('Total Unidades Relevadas;${summary.totalSightings}');
    sb.writeln('Frecuencia Global (veh/h);${summary.globalVehiclesPerHour.toStringAsFixed(1)}');
    sb.writeln('Intervalo Promedio (min);${summary.avgHeadwayMinutes.toStringAsFixed(1)}');
    sb.writeln('Tasa de Acolchonamiento (Bunching %);${summary.bunchingRatePercent.toStringAsFixed(1)}%');
    sb.writeln('');

    // Branch stats table
    sb.writeln('RESUMEN POR LINEA Y RAMAL');
    sb.writeln('Linea;Ramal;Sentido;Total Unidades;Frecuencia (veh/h);Intervalo Medio (min);Intervalo Min (min);Intervalo Max (min);Acolchonamiento;Demoras;Carga Media');
    for (final b in summary.branchStats) {
      sb.writeln(
        '${b.line.number};"${b.branch.name}";${b.direction};${b.totalSightings};${b.vehiclesPerHour.toStringAsFixed(1)};${b.avgHeadwayMinutes.toStringAsFixed(1)};${b.minHeadwayMinutes.toStringAsFixed(1)};${b.maxHeadwayMinutes.toStringAsFixed(1)};${b.bunchingCount};${b.delayedCount};${b.avgPassengerLoad.toStringAsFixed(1)}',
      );
    }
    sb.writeln('');

    // Detailed sightings log
    sb.writeln('LOG CRONOLOGICO DE PASOS DE UNIDADES');
    sb.writeln('Nro;Hora;Linea;Ramal;Sentido;Interno;Patente;Intervalo (seg);Intervalo Formato;Bunching;Demora;Carga;Observaciones');
    int count = 1;
    for (final r in summary.records) {
      final rec = r.record;
      sb.writeln(
        '$count;${timeFormat.format(rec.observedAt)};${r.line.number};"${r.branch.name}";${rec.direction};"${rec.internalNumber ?? ''}";"${rec.domain ?? ''}";${rec.headwaySeconds ?? ''};"${FrequencyAnalytics.formatHeadway(rec.headwaySeconds)}";${rec.isBunching ? 'SI' : 'NO'};${rec.isDelayed ? 'SI' : 'NO'};"${FrequencyAnalytics.formatLoad(rec.passengerLoad)}";"${rec.notes ?? ''}"',
      );
      count++;
    }

    return sb.toString();
  }

  static Future<File> exportAndShareCsv(FrequencySessionAuditSummary summary) async {
    final csvContent = await generateCsvString(summary);
    final tempDir = await getTemporaryDirectory();
    final sanitizedTitle = summary.session.title.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final filePath = '${tempDir.path}/Aforo_Frecuencias_${summary.session.id}_$sanitizedTitle.csv';
    final file = File(filePath);
    await file.writeAsString(csvContent);

    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'Informe de Frecuencias - ${summary.session.title}',
      text: 'Adjunto informe de frecuencias en formato CSV / Excel.',
    );

    return file;
  }
}
