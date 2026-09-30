import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../database/database.dart';
import '../../transport/data/transport_repository.dart';
import '../../trips/data/trips_repository.dart';
import '../domain/capture_state.dart';
import 'capture_notifier.dart';
import '../../media/data/media_service.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../data/gps_repository.dart';
import '../../../core/permissions/permissions_handler.dart';

class MainMapScreen extends ConsumerStatefulWidget {
  const MainMapScreen({super.key});

  @override
  ConsumerState<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends ConsumerState<MainMapScreen> {
  final MapController _mapController = MapController();
  final MediaService _mediaService = MediaService();

  LineEntry? _selectedLine;
  BranchEntry? _selectedBranch;
  String _direction = 'IDA';

  final _internalController = TextEditingController();
  final _domainController = TextEditingController();
  final _driverController = TextEditingController();

  List<LineEntry> _lines = [];
  List<BranchEntry> _branches = [];
  bool _isLoadingTransport = true;
  bool _autoFollow = true;
  bool _isRecordingAudio = false;

  List<LatLng> _polyPoints = [];
  List<LatLng> _stopPoints = [];
  List<LatLng> _incidentPoints = [];

  @override
  void initState() {
    super.initState();
    _loadTransportData();
    _loadPointsForMap();
  }

  Future<void> _loadTransportData() async {
    final transportRepo = ref.read(transportRepositoryProvider);
    final lines = await transportRepo.getAllLines();
    if (lines.isNotEmpty) {
      final defaultLine = lines.first;
      final branches = await transportRepo.getBranchesForLine(defaultLine.id);
      setState(() {
        _lines = lines;
        _selectedLine = defaultLine;
        _branches = branches;
        _selectedBranch = branches.isNotEmpty ? branches.first : null;
        _isLoadingTransport = false;
      });
    } else {
      setState(() => _isLoadingTransport = false);
    }
  }

  Future<void> _onLineChanged(LineEntry? line) async {
    if (line == null) return;
    setState(() {
      _selectedLine = line;
      _isLoadingTransport = true;
    });
    final branches = await ref.read(transportRepositoryProvider).getBranchesForLine(line.id);
    setState(() {
      _branches = branches;
      _selectedBranch = branches.isNotEmpty ? branches.first : null;
      _isLoadingTransport = false;
    });
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

  Future<void> _startCapture() async {
    if (_selectedLine == null || _selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione Línea y Ramal')),
      );
      return;
    }

    final hasPerms = await AppPermissionsHandler.checkAndRequestLocationPermissions();
    if (!hasPerms) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se requiere permiso de ubicación GPS en alta precisión')),
        );
      }
      return;
    }

    await AppPermissionsHandler.requestNotificationPermission();

    await ref.read(captureNotifierProvider.notifier).startCapture(
          line: _selectedLine!,
          branch: _selectedBranch!,
          direction: _direction,
          internalNumber: _internalController.text.trim().isNotEmpty ? _internalController.text.trim() : null,
          domain: _domainController.text.trim().isNotEmpty ? _domainController.text.trim() : null,
          driverName: _driverController.text.trim().isNotEmpty ? _driverController.text.trim() : null,
        );

    setState(() {
      _polyPoints.clear();
      _stopPoints.clear();
      _incidentPoints.clear();
      _autoFollow = true;
    });
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

    if (pos != null && state.status == CaptureStatus.active) {
      if (_polyPoints.isEmpty || _polyPoints.last != currentLatLng) {
        _polyPoints.add(currentLatLng);
      }
    }

    if (pos != null && _autoFollow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(currentLatLng, _mapController.camera.zoom);
      });
    }

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue.shade900),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_bus, color: Colors.white, size: 36),
                      SizedBox(width: 12),
                      Text('BITÁCORA GPS', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('Relevamiento de Campo Colectivos', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.blue),
              title: const Text('Mapa Principal'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historial de Viajes'),
              onTap: () {
                Navigator.pop(context);
                context.push('/trips');
              },
            ),
            ListTile(
              leading: const Icon(Icons.alt_route),
              title: const Text('Gestión de Líneas y Ramales'),
              onTap: () {
                Navigator.pop(context);
                context.push('/transport');
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_for_offline),
              title: const Text('Mapas Offline'),
              onTap: () {
                Navigator.pop(context);
                context.push('/maps');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ajustes & Backup'),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // 100% Fullscreen Map
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
              ),
              if (_polyPoints.isNotEmpty)
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
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: state.status == CaptureStatus.active ? Colors.blue.shade800 : Colors.green.shade700,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                        ),
                        child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
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

          // Top Header Overlay Card with Drawer button
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Theme.of(context).cardColor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Builder(
                              builder: (ctx) => IconButton(
                                icon: const Icon(Icons.menu, size: 28),
                                onPressed: () => Scaffold.of(ctx).openDrawer(),
                              ),
                            ),
                            Expanded(
                              child: state.status == CaptureStatus.idle
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('BITÁCORA GPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text(
                                          pos != null ? 'GPS Listo (±${pos.accuracy.toStringAsFixed(0)}m)' : 'Buscando señal GPS...',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${state.line?.number ?? ''} · ${state.branch?.name ?? ''} (${state.direction})',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Text(
                                          '${GeoUtils.formatDuration(Duration(seconds: state.elapsedSeconds))} · ${GeoUtils.formatDistance(state.totalDistanceMeters)} · ${state.currentSpeedKmh.toStringAsFixed(1)} km/h',
                                          style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                            ),
                            IconButton(
                              icon: Icon(_autoFollow ? Icons.gps_fixed : Icons.gps_not_fixed, color: Colors.blue),
                              onPressed: () {
                                setState(() => _autoFollow = !_autoFollow);
                                if (_autoFollow && pos != null) {
                                  _mapController.move(currentLatLng, _mapController.camera.zoom);
                                }
                              },
                              tooltip: 'Seguir GPS',
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Setup controls when Idle
                    if (state.status == CaptureStatus.idle && !_isLoadingTransport) ...[
                      const SizedBox(height: 8),
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<LineEntry>(
                                      value: _selectedLine,
                                      isDense: true,
                                      decoration: const InputDecoration(labelText: 'Línea', border: OutlineInputBorder()),
                                      items: _lines.map((l) => DropdownMenuItem(value: l, child: Text(l.number))).toList(),
                                      onChanged: _onLineChanged,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<BranchEntry>(
                                      value: _selectedBranch,
                                      isDense: true,
                                      decoration: const InputDecoration(labelText: 'Ramal', border: OutlineInputBorder()),
                                      items: _branches.map((b) => DropdownMenuItem(value: b, child: Text(b.name))).toList(),
                                      onChanged: (b) => setState(() => _selectedBranch = b),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: SegmentedButton<String>(
                                      segments: const [
                                        ButtonSegment(value: 'IDA', label: Text('IDA')),
                                        ButtonSegment(value: 'VUELTA', label: Text('VUELTA')),
                                      ],
                                      selected: {_direction},
                                      onSelectionChanged: (set) => setState(() => _direction = set.first),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                    onPressed: _startCapture,
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('INICIAR', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Auto Stop banner overlay
                    if (state.possibleStopDetected) ...[
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.amber.shade200,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.amber),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '🟡 POSIBLE PARADA (${state.possibleStopSeconds}s)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                              TextButton(
                                onPressed: () => ref.read(captureNotifierProvider.notifier).confirmAutoStop(),
                                child: const Text('CONFIRMAR'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => ref.read(captureNotifierProvider.notifier).ignoreAutoStop(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Floating Re-center button
          if (!_autoFollow && pos != null)
            Positioned(
              bottom: state.status == CaptureStatus.active ? 220 : 30,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () {
                  setState(() => _autoFollow = true);
                  _mapController.move(currentLatLng, _mapController.camera.zoom);
                },
                icon: const Icon(Icons.my_location),
                label: const Text('VOLVER A UBICACIÓN'),
              ),
            ),

          // Floating Action Controls Panel at bottom during Capture
          if (state.status == CaptureStatus.active || state.status == CaptureStatus.paused)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Large PARADA Button
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: Colors.red.shade700,
                        ),
                        onPressed: () async {
                          await ref.read(captureNotifierProvider.notifier).addManualStop();
                          _loadPointsForMap();
                        },
                        icon: const Icon(Icons.location_on, size: 28),
                        label: const Text('📍 REGISTRAR PARADA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showIncidentPicker,
                              icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                              label: const Text('⚠ INCIDENCIA', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _handleTakePhoto,
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: const Text('📷 FOTO', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _isRecordingAudio ? Colors.red.shade100 : null,
                              ),
                              onPressed: _handleToggleAudio,
                              icon: Icon(Icons.mic, color: _isRecordingAudio ? Colors.red : null, size: 18),
                              label: Text(_isRecordingAudio ? '⏹ STOP' : '🎤 AUDIO', style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: state.status == CaptureStatus.paused ? Colors.green : Colors.amber.shade800,
                              ),
                              onPressed: () {
                                if (state.status == CaptureStatus.paused) {
                                  ref.read(captureNotifierProvider.notifier).resumeCapture();
                                } else {
                                  ref.read(captureNotifierProvider.notifier).pauseCapture();
                                }
                              },
                              icon: Icon(state.status == CaptureStatus.paused ? Icons.play_arrow : Icons.pause, color: Colors.white, size: 18),
                              label: Text(
                                state.status == CaptureStatus.paused ? 'REANUDAR' : 'PAUSAR',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
                              onPressed: _confirmFinish,
                              icon: const Icon(Icons.stop, color: Colors.white, size: 18),
                              label: const Text('FINALIZAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
