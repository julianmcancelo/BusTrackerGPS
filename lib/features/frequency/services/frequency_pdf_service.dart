import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../domain/frequency_models.dart';
import '../domain/frequency_analytics.dart';

class FrequencyPdfService {
  static Future<File> generateAndSharePdf(FrequencySessionAuditSummary summary, {bool openDirectly = false}) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final timeFormat = DateFormat('HH:mm:ss');

    final primaryColor = PdfColor.fromInt(0xFF0369A1);
    final darkHeader = PdfColor.fromInt(0xFF1E293B);
    final greyBg = PdfColor.fromInt(0xFFF1F5F9);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Institutional Header
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BITÁCORA GPS · AUDITORÍA DE TRANSPORTE PÚBLICO',
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 13),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'INFORME OFICIAL DE CONTROL DE FRECUENCIAS Y HEADWAYS',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 9),
                    ),
                  ],
                ),
                pw.Text(
                  DateFormat('dd/MM/yyyy').format(summary.session.startedAt),
                  style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Metadata Grid
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: greyBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: _buildMetaField('Relevamiento / Título:', summary.session.title),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: _buildMetaField('Punto de Control:', summary.session.checkpointName),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildMetaField('Hora Inicio:', dateFormat.format(summary.session.startedAt)),
                    ),
                    pw.Expanded(
                      child: _buildMetaField(
                        'Hora Fin:',
                        summary.session.endedAt != null ? dateFormat.format(summary.session.endedAt!) : 'En curso',
                      ),
                    ),
                    pw.Expanded(
                      child: _buildMetaField('Auditor / Inspector:', summary.session.auditorName ?? 'Veedor Autorizado'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Executive Summary KPIs
          pw.Text('RESUMEN EJECUTIVO DE SERVICIO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: darkHeader)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('Total Unidades', isHeader: true),
                  _buildTableCell('Frecuencia Media', isHeader: true),
                  _buildTableCell('Intervalo Promedio', isHeader: true),
                  _buildTableCell('Intervalo Rango', isHeader: true),
                  _buildTableCell('Acolchonamiento', isHeader: true),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildTableCell('${summary.totalSightings} veh.'),
                  _buildTableCell('${summary.globalVehiclesPerHour.toStringAsFixed(1)} veh/h'),
                  _buildTableCell('${summary.avgHeadwayMinutes.toStringAsFixed(1)} min'),
                  _buildTableCell('${summary.minHeadwayMinutes.toStringAsFixed(1)} - ${summary.maxHeadwayMinutes.toStringAsFixed(1)} min'),
                  _buildTableCell('${summary.totalBunching} (${summary.bunchingRatePercent.toStringAsFixed(0)}%)'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),

          // Branch Level Breakdown Table
          pw.Text('DESGLOSE ESTADÍSTICO POR LÍNEA Y RAMAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: darkHeader)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('Línea', isHeader: true),
                  _buildTableCell('Ramal', isHeader: true),
                  _buildTableCell('Sentido', isHeader: true),
                  _buildTableCell('Coches', isHeader: true),
                  _buildTableCell('Veh/h', isHeader: true),
                  _buildTableCell('H. Medio', isHeader: true),
                  _buildTableCell('Acolch.', isHeader: true),
                  _buildTableCell('Demoras', isHeader: true),
                  _buildTableCell('Carga', isHeader: true),
                ],
              ),
              ...summary.branchStats.map((b) {
                return pw.TableRow(
                  children: [
                    _buildTableCell(b.line.number),
                    _buildTableCell(b.branch.name),
                    _buildTableCell(b.direction),
                    _buildTableCell('${b.totalSightings}'),
                    _buildTableCell(b.vehiclesPerHour.toStringAsFixed(1)),
                    _buildTableCell('${b.avgHeadwayMinutes.toStringAsFixed(1)} min'),
                    _buildTableCell('${b.bunchingCount}'),
                    _buildTableCell('${b.delayedCount}'),
                    _buildTableCell('${b.avgPassengerLoad.toStringAsFixed(1)}/4'),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 18),

          // Chronological Sightings Log
          pw.Text('PLANILLA CRONOLÓGICA DE PASOS AUDITADOS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: darkHeader)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('#', isHeader: true),
                  _buildTableCell('Hora', isHeader: true),
                  _buildTableCell('Línea / Ramal', isHeader: true),
                  _buildTableCell('Sent.', isHeader: true),
                  _buildTableCell('Interno', isHeader: true),
                  _buildTableCell('Intervalo', isHeader: true),
                  _buildTableCell('Estado', isHeader: true),
                  _buildTableCell('Ocupación', isHeader: true),
                ],
              ),
              ...summary.records.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final r = entry.value;
                final rec = r.record;
                String statusStr = 'Normal';
                if (rec.isBunching) statusStr = 'Acolchonado';
                if (rec.isDelayed) statusStr = 'Demorado';

                return pw.TableRow(
                  children: [
                    _buildTableCell('$idx'),
                    _buildTableCell(timeFormat.format(rec.observedAt)),
                    _buildTableCell('${r.line.number} - ${r.branch.name}'),
                    _buildTableCell(rec.direction),
                    _buildTableCell(rec.internalNumber ?? '-'),
                    _buildTableCell(FrequencyAnalytics.formatHeadway(rec.headwaySeconds)),
                    _buildTableCell(statusStr),
                    _buildTableCell(FrequencyAnalytics.formatLoad(rec.passengerLoad)),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 24),

          // Signatures Section
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Column(
                children: [
                  pw.Container(width: 150, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 4),
                  pw.Text('Firma del Inspector / Auditor', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(summary.session.auditorName ?? 'Veedor Actuante', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 150, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 4),
                  pw.Text('Supervisión / Autoridad de Transporte', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Bitácora GPS Control', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final sanitizedTitle = summary.session.title.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final filePath = '${tempDir.path}/Informe_Auditoria_Frecuencias_${summary.session.id}_$sanitizedTitle.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    if (openDirectly) {
      await OpenFilex.open(filePath);
    } else {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Informe Oficial de Frecuencias - ${summary.session.title}',
        text: 'Adjunto informe formal de auditoría de frecuencias en formato PDF.',
      );
    }

    return file;
  }

  static pw.Widget _buildMetaField(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 1),
        pw.Text(value, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 8 : 7.5,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
