import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../domain/capture_state.dart';
import 'capture_notifier.dart';
import '../../media/data/media_service.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../trips/data/trips_repository.dart';
import '../data/gps_repository.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final MapController _mapController = MapController();
  final MediaService _mediaService = MediaService();

  bool _autoFollow = true;
  bool _isRecordingAudio = false;

  List<LatLng> _polyPoints = [];
  List<LatLng> _stopPoints = [];
  List<LatLng> _incidentPoints = [];

  @override
  void initState() {
    super.initState();
    _loadPointsForMap();
  }

  Future<void> _loadPointsForMap() async {
    final state = ref.read(captureNotifierProvider);
    if (state.tripId != null) {
      final gpsRepo = ref.read(gpsRepositoryProvider);
      final rawPoints = await gpsRepo.getTrackPoints(state.tripId!);
      final stops = await gpsRepo.getStops(state.tripId!);
      final incidents = await gpsRepo.getIncidents(state.tripId!);

      if (mounted) {
        setState(() {
          _polyPoints = rawPoints
              .where((p) => p.quality != 'OUTLIER')
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList();
          _stopPoints = stops.map((s) => LatLng(s.latitude, s.longitude)).toList();
          _incidentPoints = incidents.map((i) => LatLng(i.latitude, i.longitude)).toList();
        });
      }
    }
  }

  void _centerMapOnCurrent(LatLng pos) {
    _mapController.move(pos, 16.0);
  }

  Future<void> _handleTakePhoto() async {
    final file = await _mediaService.takePhoto();
    if (file != null) {
      await ref.read(captureNotifierProvider.notifier).addPhoto(file.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Foto guardada y georreferenciada')),
        );
      }
    }
  }

  Future<void> _handleToggleAudio() async {
    if (_isRecordingAudio) {
      final file = await _mediaService.stopAudioRecording();
      setState(() => _isRecordingAudio = false);
      if (file != null) {
        await ref.read(captureNotifierProvider.notifier).addAudio(file.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Nota de audio guardada')),
          );
        }
      }
    } else {
      final tripId = ref.read(captureNotifierProvider).tripId;
      if (tripId == null) return;
      await _mediaService.startAudioRecording('audio_${DateTime.now().millisecondsSinceEpoch}');
      setState(() => _isRecordingAudio = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎤 Grabando audio... Pulse de nuevo para finalizar')),
        );
      }
    }
  }

  void _showIncidentPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('SELECCIONAR INCIDENCIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: IncidentType.values.map((type) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(captureNotifierProvider.notifier).addIncident(type: type.name);
                      _loadPointsForMap();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(type.iconEmoji, style: const TextStyle(fontSize: 28)),
                          const SizedBox(height: 4),
                          Text(type.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmFinish() async {
    final state = ref.read(captureNotifierProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿FINALIZAR RECORRIDO?'),
        content: Text(
          '${state.line?.number ?? ''} · ${state.branch?.name ?? ''} · ${state.direction}\n\n'
          'Distancia: ${GeoUtils.formatDistance(state.totalDistanceMeters)}\n'
          'Paradas: ${state.stopCount}\n'
          'Incidencias: ${state.incidentCount}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('FINALIZAR'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final finishedTripId = await ref.read(captureNotifierProvider.notifier).finishCapture();
      if (mounted && finishedTripId != null) {
        context.go('/trips/$finishedTripId');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(captureNotifierProvider);
    final pos = state.currentPosition;
    final currentLatLng = pos != null ? LatLng(pos.latitude, pos.longitude) : const LatLng(-34.700, -58.380);

    if (pos != null) {
      if (_polyPoints.isEmpty || _polyPoints.last != currentLatLng) {
        _polyPoints.add(currentLatLng);
      }
      if (_autoFollow) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(currentLatLng, _mapController.camera.zoom);
        });
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: state.status == CaptureStatus.paused ? Colors.orange.shade800 : Colors.blue.shade900,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.line?.number ?? ''} · ${state.branch?.name ?? ''} · ${state.direction}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: state.status == CaptureStatus.paused ? Colors.amber : Colors.greenAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              state.status == CaptureStatus.paused ? 'PAUSADO' : 'CAPTURANDO',
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(_autoFollow ? Icons.gps_fixed : Icons.gps_not_fixed, color: Colors.white),
                    onPressed: () {
                      setState(() => _autoFollow = !_autoFollow);
                      if (_autoFollow) _centerMapOnCurrent(currentLatLng);
                    },
                    tooltip: 'Seguir GPS',
                  ),
                ],
              ),
            ),

            // Possible Auto Stop Banner (Rule 31)
            if (state.possibleStopDetected)
              Container(
                color: Colors.amber.shade200,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🟡 POSIBLE PARADA: Detenido ${state.possibleStopSeconds}s',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.read(captureNotifierProvider.notifier).confirmAutoStop(),
                      child: const Text('CONFIRMAR'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => ref.read(captureNotifierProvider.notifier).ignoreAutoStop(),
                    ),
                  ],
                ),
              ),

            // Interactive Flutter Map
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: currentLatLng,
                      initialZoom: 16.0,
                      onPositionChanged: (cam, hasGesture) {
                        if (hasGesture && _autoFollow) {
                          setState(() => _autoFollow = false);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.bitacoragps.app.bitacora_gps',
                        tileBuilder: (context, tileWidget, tile) {
                          return tileWidget;
                        },
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _polyPoints,
                            strokeWidth: 5.0,
                            color: Colors.blue.shade700,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          if (pos != null)
                            Marker(
                              point: currentLatLng,
                              width: 32,
                              height: 32,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 3)),
                                ),
                                child: const Icon(Icons.directions_bus, color: Colors.white, size: 18),
                              ),
                            ),
                          ..._stopPoints.map(
                            (p) => Marker(
                              point: p,
                              width: 24,
                              height: 24,
                              child: const Icon(Icons.location_on, color: Colors.red, size: 24),
                            ),
                          ),
                          ..._incidentPoints.map(
                            (p) => Marker(
                              point: p,
                              width: 24,
                              height: 24,
                              child: const Icon(Icons.warning, color: Colors.orange, size: 24),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Floating Re-center button if autoFollow is disabled
                  if (!_autoFollow)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton.extended(
                        onPressed: () {
                          setState(() => _autoFollow = true);
                          _centerMapOnCurrent(currentLatLng);
                        },
                        icon: const Icon(Icons.my_location),
                        label: const Text('VOLVER A UBICACIÓN'),
                      ),
                    ),
                ],
              ),
            ),

            // Live Dashboard & Telemetry Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricItem(
                    label: 'TIEMPO',
                    value: GeoUtils.formatDuration(Duration(seconds: state.elapsedSeconds)),
                  ),
                  _buildMetricItem(
                    label: 'DISTANCIA',
                    value: GeoUtils.formatDistance(state.totalDistanceMeters),
                  ),
                  _buildMetricItem(
                    label: 'VELOCIDAD',
                    value: '${state.currentSpeedKmh.toStringAsFixed(1)} km/h',
                  ),
                  _buildMetricItem(
                    label: 'GPS',
                    value: '±${pos?.accuracy.toStringAsFixed(0) ?? '?'} m',
                    subtitle: state.gpsSignalQuality,
                  ),
                ],
              ),
            ),

            // Single-Hand Field Action Controls (Rule 23)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Primary Action: Large PARADA Button
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(60),
                      backgroundColor: Colors.red.shade700,
                    ),
                    onPressed: () async {
                      await ref.read(captureNotifierProvider.notifier).addManualStop();
                      _loadPointsForMap();
                    },
                    icon: const Icon(Icons.location_on, size: 32),
                    label: const Text('📍 REGISTRAR PARADA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),

                  const SizedBox(height: 12),

                  // Secondary Controls Row 1
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: _showIncidentPicker,
                          icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          label: const Text('⚠ INCIDENCIA'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: _handleTakePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('📷 FOTO'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Secondary Controls Row 2
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: _isRecordingAudio ? Colors.red.shade100 : null,
                          ),
                          onPressed: _handleToggleAudio,
                          icon: Icon(Icons.mic, color: _isRecordingAudio ? Colors.red : null),
                          label: Text(_isRecordingAudio ? '⏹ DETENER' : '🎤 AUDIO'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: () {
                            ref.read(captureNotifierProvider.notifier).addIncident(type: 'otro', description: 'Punto libre');
                          },
                          icon: const Icon(Icons.add_location_alt),
                          label: const Text('+ PUNTO'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Pause / Resume & Finish Row
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: state.status == CaptureStatus.paused ? Colors.green : Colors.amber.shade800,
                          ),
                          onPressed: () {
                            if (state.status == CaptureStatus.paused) {
                              ref.read(captureNotifierProvider.notifier).resumeCapture();
                            } else {
                              ref.read(captureNotifierProvider.notifier).pauseCapture();
                            }
                          },
                          icon: Icon(state.status == CaptureStatus.paused ? Icons.play_arrow : Icons.pause, color: Colors.white),
                          label: Text(
                            state.status == CaptureStatus.paused ? '▶ REANUDAR' : '⏸ PAUSAR',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.red.shade900,
                          ),
                          onPressed: _confirmFinish,
                          icon: const Icon(Icons.stop, color: Colors.white),
                          label: const Text('■ FINALIZAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        if (subtitle != null)
          Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
