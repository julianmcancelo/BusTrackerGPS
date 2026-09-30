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

class _MainMapScreenState extends ConsumerState<MainMapScreen> with SingleTickerProviderStateMixin {
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

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadTransportData();
    _loadPointsForMap();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _internalController.dispose();
    _domainController.dispose();
    _driverController.dispose();
    super.dispose();
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
          const SnackBar(content: Text('Grabando audio... Pulse de nuevo para finalizar')),
        );
      }
    }
  }

  IconData _getIncidentIcon(IncidentType type) {
    switch (type) {
      case IncidentType.obra:
        return Icons.construction;
      case IncidentType.corte:
        return Icons.block;
      case IncidentType.desvio:
        return Icons.alt_route;
      case IncidentType.transito:
        return Icons.traffic;
      case IncidentType.parada:
        return Icons.hail;
      case IncidentType.calzada:
        return Icons.warning_amber_rounded;
      case IncidentType.unidad:
        return Icons.directions_bus;
      case IncidentType.accidente:
        return Icons.car_crash;
      case IncidentType.otro:
        return Icons.more_horiz;
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
              const Text('REGISTRAR INCIDENCIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
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
                          Icon(_getIncidentIcon(type), size: 28, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 6),
                          Text(type.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade900, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_bus, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('BITÁCORA GPS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Relevamiento Colectivos', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('v1.0.4 · Offline-First · Shorebird OTA', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
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
                      width: 38,
                      height: 38,
                      child: Container(
                        decoration: BoxDecoration(
                          color: state.status == CaptureStatus.active ? Colors.blue.shade800 : Colors.green.shade700,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                        ),
                        child: const Icon(Icons.directions_bus, color: Colors.white, size: 22),
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

          // Top Status Header / Telemetry Overlay
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Card(
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
                                        style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          FadeTransition(
                                            opacity: _pulseAnimation,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              margin: const EdgeInsets.only(right: 6),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'REC · LÍNEA ${state.line?.number ?? ''}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${state.branch?.name ?? ''} (${state.direction})',
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${GeoUtils.formatDistance(state.totalDistanceMeters)} · ${state.currentSpeedKmh.toStringAsFixed(0)} km/h · ${state.pointCount} pts · ${GeoUtils.formatDuration(Duration(seconds: state.elapsedSeconds))}',
                                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
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
                ),
              ),
            ),
          ),

          // Auto Stop Banner Overlay
          if (state.possibleStopDetected)
            Positioned(
              top: 90,
              left: 16,
              right: 16,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Card(
                    color: Colors.amber.shade200,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'POSIBLE PARADA (${state.possibleStopSeconds}s)',
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
                ),
              ),
            ),

          // Re-center Floating Button
          if (!_autoFollow && pos != null)
            Positioned(
              bottom: state.status == CaptureStatus.idle ? 250 : 260,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () {
                  setState(() => _autoFollow = true);
                  _mapController.move(currentLatLng, _mapController.camera.zoom);
                },
                icon: const Icon(Icons.my_location),
                label: const Text('CENTRAR GPS'),
              ),
            ),

          // Responsive Bottom Quick Action & Setup Panel
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: state.status == CaptureStatus.idle
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.directions_bus, color: Colors.blue, size: 22),
                                const SizedBox(width: 8),
                                const Text(
                                  'CONFIGURACIÓN DE RECORRIDO',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<LineEntry>(
                                    value: _selectedLine,
                                    isDense: true,
                                    borderRadius: BorderRadius.circular(12),
                                    decoration: InputDecoration(
                                      labelText: 'Línea de Colectivo',
                                      prefixIcon: const Icon(Icons.format_list_numbered),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    items: _lines
                                        .map((l) => DropdownMenuItem(
                                              value: l,
                                              child: Text('Línea ${l.number}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            ))
                                        .toList(),
                                    onChanged: _onLineChanged,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<BranchEntry>(
                                    value: _selectedBranch,
                                    isDense: true,
                                    borderRadius: BorderRadius.circular(12),
                                    decoration: InputDecoration(
                                      labelText: 'Ramal',
                                      prefixIcon: const Icon(Icons.alt_route),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    items: _branches
                                        .map((b) => DropdownMenuItem(
                                              value: b,
                                              child: Text(b.name, overflow: TextOverflow.ellipsis),
                                            ))
                                        .toList(),
                                    onChanged: (b) => setState(() => _selectedBranch = b),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: SegmentedButton<String>(
                                    segments: const [
                                      ButtonSegment(value: 'IDA', label: Text('IDA'), icon: Icon(Icons.arrow_forward)),
                                      ButtonSegment(value: 'VUELTA', label: Text('VUELTA'), icon: Icon(Icons.arrow_back)),
                                    ],
                                    selected: {_direction},
                                    onSelectionChanged: (set) => setState(() => _direction = set.first),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _internalController,
                                    decoration: InputDecoration(
                                      labelText: 'Interno (opcional)',
                                      isDense: true,
                                      prefixIcon: const Icon(Icons.tag, size: 20),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _domainController,
                                    decoration: InputDecoration(
                                      labelText: 'Dominio/Patente',
                                      isDense: true,
                                      prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    textCapitalization: TextCapitalization.characters,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(54),
                                backgroundColor: Colors.green.shade700,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _startCapture,
                              icon: const Icon(Icons.play_arrow, size: 28),
                              label: const Text('INICIAR CAPTURA DE RECORRIDO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Primary PARADA Button
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(56),
                                backgroundColor: Colors.red.shade700,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () async {
                                await ref.read(captureNotifierProvider.notifier).addManualStop();
                                _loadPointsForMap();
                              },
                              icon: const Icon(Icons.location_on, size: 28),
                              label: const Text('REGISTRAR PARADA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ),

                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _showIncidentPicker,
                                    icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                                    label: const Text('INCIDENCIA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _handleTakePhoto,
                                    icon: const Icon(Icons.camera_alt, size: 18),
                                    label: const Text('FOTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      backgroundColor: _isRecordingAudio ? Colors.red.shade100 : null,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _handleToggleAudio,
                                    icon: Icon(Icons.mic, color: _isRecordingAudio ? Colors.red : null, size: 18),
                                    label: Text(_isRecordingAudio ? 'PARAR' : 'AUDIO', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      backgroundColor: state.status == CaptureStatus.paused ? Colors.green : Colors.amber.shade800,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      backgroundColor: Colors.red.shade900,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
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
          ),
        ],
      ),
    );
  }
}
