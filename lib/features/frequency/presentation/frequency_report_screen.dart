import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/frequency_repository.dart';
import '../domain/frequency_models.dart';
import '../domain/frequency_analytics.dart';
import '../services/frequency_pdf_service.dart';
import '../services/frequency_csv_service.dart';

class FrequencyReportScreen extends ConsumerStatefulWidget {
  final int sessionId;
  const FrequencyReportScreen({super.key, required this.sessionId});

  @override
  ConsumerState<FrequencyReportScreen> createState() => _FrequencyReportScreenState();
}

class _FrequencyReportScreenState extends ConsumerState<FrequencyReportScreen> {
  FrequencySessionAuditSummary? _summary;
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final repo = ref.read(frequencyRepositoryProvider);
    final summary = await repo.getSessionAuditSummary(widget.sessionId);
    if (mounted) {
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    }
  }

  Future<void> _sharePdf({bool openDirectly = false}) async {
    if (_summary == null || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      await FrequencyPdfService.generateAndSharePdf(_summary!, openDirectly: openDirectly);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al exportar PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _shareCsv() async {
    if (_summary == null || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      await FrequencyCsvService.exportAndShareCsv(_summary!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al exportar CSV: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Generando informe...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_summary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Informe de Frecuencias')),
        body: const Center(child: Text('No se encontraron datos para esta auditoría.')),
      );
    }

    final s = _summary!;
    final session = s.session;
    final isCompleted = session.status == 'COMPLETED';
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('INFORME DE AUDITORÍA'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Ver PDF',
            onPressed: () => _sharePdf(openDirectly: true),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Compartir PDF',
            onPressed: () => _sharePdf(openDirectly: false),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 85),
        children: [
          // Header Card with Institutional Metadata
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0369A1).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.assignment_outlined, color: Color(0xFF0369A1), size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              session.checkpointName,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isCompleted ? Colors.green : Colors.amber.shade800).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isCompleted ? 'FINALIZADO' : 'EN VIVO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCompleted ? Colors.green : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetaText('INICIO', dateFormat.format(session.startedAt)),
                      _buildMetaText('DURACIÓN', '${s.totalDuration.inMinutes} min'),
                      _buildMetaText('AUDITOR', session.auditorName ?? 'Inspector'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Executive Summary KPIs
          _buildSectionHeader('MÉTRICAS CLAVE DE SERVICIO', Icons.speed),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildKpiCard('UNIDADES', s.totalSightings.toString(), 'Total vistas', const Color(0xFF0F172A)),
              const SizedBox(width: 8),
              _buildKpiCard('FRECUENCIA', s.globalVehiclesPerHour.toStringAsFixed(1), 'vehículos / hora', const Color(0xFF0284C7)),
              const SizedBox(width: 8),
              _buildKpiCard('H. MEDIO', '${s.avgHeadwayMinutes.toStringAsFixed(1)} m', 'Intervalo prom.', const Color(0xFF059669)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildKpiCard('ACOLCHONADO', '${s.bunchingRatePercent.toStringAsFixed(0)}%', '${s.totalBunching} unidades', Colors.amber.shade800),
              const SizedBox(width: 8),
              _buildKpiCard('DEMORAS', '${s.delayedRatePercent.toStringAsFixed(0)}%', '${s.totalDelayed} coches', Colors.red.shade700),
              const SizedBox(width: 8),
              _buildKpiCard('CARGA', '${s.avgPassengerLoad.toStringAsFixed(1)} / 4', 'Nivel medio', Colors.purple.shade700),
            ],
          ),
          const SizedBox(height: 16),

          // Branch Level Breakdown
          _buildSectionHeader('DESGLOSE POR LÍNEA Y RAMAL', Icons.alt_route),
          const SizedBox(height: 6),
          ...s.branchStats.map((b) => _buildBranchStatCard(b)),

          const SizedBox(height: 16),
          // Detailed Sightings Log Header
          _buildSectionHeader('PLANILLA DE PASOS (${s.records.length})', Icons.format_list_numbered),
          const SizedBox(height: 6),

          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: s.records.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final r = s.records[i];
                final rec = r.record;
                final timeStr = DateFormat('HH:mm:ss').format(rec.observedAt);
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 34,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(4)),
                    child: Text(r.line.number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  title: Text('${r.branch.name} (${rec.direction})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Hora: $timeStr${rec.internalNumber != null ? ' · Coche #${rec.internalNumber}' : ''} · ${FrequencyAnalytics.formatLoad(rec.passengerLoad)}',
                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (rec.isBunching ? Colors.amber : (rec.isDelayed ? Colors.red : Colors.green)).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      FrequencyAnalytics.formatHeadway(rec.headwaySeconds),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: rec.isBunching ? Colors.amber.shade900 : (rec.isDelayed ? Colors.red.shade900 : Colors.green.shade800),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Actions to export
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: const Color(0xFF0369A1),
            ),
            onPressed: _isExporting ? null : () => _sharePdf(openDirectly: false),
            icon: _isExporting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.share),
            label: const Text('COMPARTIR INFORME OFICIAL PDF', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            onPressed: _isExporting ? null : _shareCsv,
            icon: const Icon(Icons.table_view_outlined),
            label: const Text('EXPORTAR PLANILLA CSV PARA EXCEL', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => context.pushReplacement('/frequency/session/${session.id}'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('VOLVER AL AFORO EN VIVO'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaText(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, String subtitle, Color color) {
    return Expanded(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            children: [
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 8.5, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranchStatCard(FrequencyBranchStat b) {
    return Card(
      elevation: 0.8,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
              child: Text(b.line.number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${b.branch.name} (${b.direction})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    '${b.totalSightings} coches · ${b.vehiclesPerHour.toStringAsFixed(1)} v/h · Intervalo prom: ${b.avgHeadwayMinutes.toStringAsFixed(1)} min',
                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (b.bunchingCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: Text('${b.bunchingCount} acolch.', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
              ),
          ],
        ),
      ),
    );
  }
}
