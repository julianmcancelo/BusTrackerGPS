import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

import '../data/trips_repository.dart';
import '../../capture/data/gps_repository.dart';
import '../../export/data/export_service.dart';
import '../../../database/database.dart';
import '../../../core/utils/geo_utils.dart';
import '../../capture/presentation/capture_notifier.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  TripWithDetails? _details;
  List<TrackPointEntry> _points = [];
  List<StopEntry> _stops = [];
  List<IncidentEntry> _incidents = [];
  List<AttachmentEntry> _attachments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTripData();
  }

  Future<void> _loadTripData() async {
    final tripsRepo = ref.read(tripsRepositoryProvider);
    final gpsRepo = ref.read(gpsRepositoryProvider);

    final details = await tripsRepo.getTripWithDetails(widget.tripId);
    final points = await gpsRepo.getTrackPoints(widget.tripId);
    final stops = await gpsRepo.getStops(widget.tripId);
    final incidents = await gpsRepo.getIncidents(widget.tripId);
    final attachments = await gpsRepo.getAttachments(widget.tripId);

    if (mounted) {
      setState(() {
        _details = details;
        _points = points;
        _stops = stops;
        _incidents = incidents;
        _attachments = attachments;
        _isLoading = false;
      });
    }
  }

  Future<void> _reverseTrip() async {
    if (_details == null) return;
    final newDir = _details!.trip.direction == 'IDA' ? 'VUELTA' : 'IDA';

    await ref.read(captureNotifierProvider.notifier).startCapture(
          line: _details!.line,
          branch: _details!.branch,
          direction: newDir,
          internalNumber: _details!.trip.internalNumber,
          domain: _details!.trip.domain,
          driverName: _details!.trip.driverName,
        );

    if (mounted) {
      context.go('/capture');
    }
  }

  Future<void> _exportZip() async {
    if (_details == null) return;
    final zipFile = await ExportService.generateZipPackage(
      trip: _details!.trip,
      line: _details!.line,
      branch: _details!.branch,
      trackPoints: _points,
      stops: _stops,
      incidents: _incidents,
      attachments: _attachments,
    );
    await ExportService.shareFile(zipFile, text: 'Recorrido ${_details!.line.number} ZIP');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando viaje...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_details == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No se encontró el viaje')),
      );
    }

    final t = _details!.trip;
    final line = _details!.line;
    final branch = _details!.branch;

    final polyPoints = _points
        .where((p) => p.quality != 'OUTLIER')
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${line.number} · ${branch.name} (${t.direction})'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _exportZip,
              tooltip: 'Exportar ZIP',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.analytics), text: 'Stats'),
              Tab(icon: Icon(Icons.map), text: 'Mapa'),
              Tab(icon: Icon(Icons.location_on), text: 'Paradas'),
              Tab(icon: Icon(Icons.warning), text: 'Eventos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Stats & Info
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.directions_bus, size: 36, color: Colors.blue),
                            title: Text('Línea ${line.number} - ${branch.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Sentido: ${t.direction}\nInterno: ${t.internalNumber ?? "N/A"} · Dominio: ${t.domain ?? "N/A"}'),
                          ),
                          const Divider(),
                          Text(
                            'Fecha: ${DateFormat("dd/MM/yyyy HH:mm").format(t.startedAt)}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Telemetry Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      _buildStatCard('Distancia', GeoUtils.formatDistance(t.distanceMeters), Icons.straighten),
                      _buildStatCard('Duración', GeoUtils.formatDuration(Duration(milliseconds: t.durationMs)), Icons.timer),
                      _buildStatCard('Velocidad Media', '${t.averageSpeedKmh.toStringAsFixed(1)} km/h', Icons.speed),
                      _buildStatCard('Velocidad Máx.', '${t.maxSpeedKmh.toStringAsFixed(1)} km/h', Icons.navigation),
                      _buildStatCard('Movimiento', GeoUtils.formatDuration(Duration(milliseconds: t.movingTimeMs)), Icons.directions_run),
                      _buildStatCard('Detenido', GeoUtils.formatDuration(Duration(milliseconds: t.stoppedTimeMs)), Icons.pause_circle),
                      _buildStatCard('Puntos GPS', '${t.pointCount}', Icons.pin_drop),
                      _buildStatCard('Paradas', '${t.stopCount}', Icons.location_on),
                    ],
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.indigo,
                    ),
                    onPressed: _reverseTrip,
                    icon: const Icon(Icons.swap_calls, color: Colors.white),
                    label: const Text('HACER VUELTA (SENTIDO CONTRARIO)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // Tab 2: Interactive Map
            FlutterMap(
              options: MapOptions(
                initialCenter: polyPoints.isNotEmpty ? polyPoints.first : const LatLng(-34.700, -58.380),
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bitacoragps.app.bitacora_gps',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polyPoints,
                      strokeWidth: 5.0,
                      color: Colors.blue.shade700,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    ..._stops.map(
                      (s) => Marker(
                        point: LatLng(s.latitude, s.longitude),
                        width: 24,
                        height: 24,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 24),
                      ),
                    ),
                    ..._incidents.map(
                      (inc) => Marker(
                        point: LatLng(inc.latitude, inc.longitude),
                        width: 24,
                        height: 24,
                        child: const Icon(Icons.warning, color: Colors.orange, size: 24),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Tab 3: Stops Timeline
            ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _stops.length,
              separatorBuilder: (ctx, idx) => const Divider(),
              itemBuilder: (ctx, idx) {
                final s = _stops[idx];
                final timeStr = DateFormat('HH:mm:ss').format(s.markedAt);
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${s.sequence}'),
                  ),
                  title: Text(s.name ?? 'Parada ${s.sequence}'),
                  subtitle: Text('Hora: $timeStr · Estado: ${s.status}'),
                  trailing: s.dwellTimeMs != null
                      ? Text('${(s.dwellTimeMs! / 1000).toStringAsFixed(0)}s detenido', style: const TextStyle(color: Colors.amber))
                      : null,
                );
              },
            ),

            // Tab 4: Incidents & Attachments
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Incidencias', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ..._incidents.map((inc) {
                  return Card(
                    margin: const EdgeInsets.only(top: 8),
                    child: ListTile(
                      leading: const Icon(Icons.warning, color: Colors.orange),
                      title: Text(inc.type),
                      subtitle: Text('Severidad: ${inc.severity}\n${inc.description ?? ""}'),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                const Text('Archivos Adjuntos (Fotos / Audios)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ..._attachments.map((att) {
                  return Card(
                    margin: const EdgeInsets.only(top: 8),
                    child: ListTile(
                      leading: Icon(att.type == 'PHOTO' ? Icons.camera_alt : Icons.mic),
                      title: Text(att.type),
                      subtitle: Text(att.filePath),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
