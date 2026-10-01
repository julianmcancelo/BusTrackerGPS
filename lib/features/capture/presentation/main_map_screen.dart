import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../database/database.dart';
import '../../../database/database_provider.dart';
import '../../transport/data/transport_repository.dart';
import '../../trips/data/trips_repository.dart';
import '../domain/capture_state.dart';
import 'capture_notifier.dart';
import '../../media/data/media_service.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/github_update_service.dart';
import '../data/gps_repository.dart';
import '../../../core/utils/line_hierarchy_ext.dart';
import '../../../core/permissions/permissions_handler.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';

class MainMapScreen extends ConsumerStatefulWidget {
  const MainMapScreen({super.key});

  @override
  ConsumerState<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends ConsumerState<MainMapScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final MediaService _mediaService = MediaService();

  String? _selectedHierarchy;
  LineEntry? _selectedLine;
  BranchEntry? _selectedBranch;
  String _direction = 'IDA';

  final _internalController = TextEditingController();
  final _domainController = TextEditingController();
  final _driverController = TextEditingController();

  List<LineEntry> _lines = [];
  List<BranchEntry> _branches = [];
  bool _isLoadingTransport = true;
  bool _isConfigExpanded = true;
  bool _isVehicleExpanded = false;
  bool _isFilterExpanded = false;
  bool _autoFollow = true;
  bool _isRecordingAudio = false;

  List<LatLng> _polyPoints = [];
  List<LatLng> _stopPoints = [];
  List<LatLng> _incidentPoints = [];

  BranchDirectionStatus? _directionStatus;
  List<LatLng> _referenceIdaPoints = [];
  List<LatLng> _referenceVueltaPoints = [];
  List<LatLng> _localIdaPoints = [];
  List<LatLng> _localVueltaPoints = [];

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(githubUpdateProvider.notifier).checkForUpdates(context: context);
    });
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
      await _updateBranchDirectionStatus();
    } else {
      setState(() => _isLoadingTransport = false);
    }
  }

  Future<void> _refreshConfig() async {
    setState(() => _isLoadingTransport = true);
    try {
      final db = ref.read(databaseProvider);
      await SyncService.fetchBitacoraGpsSurveys(db);
      await _loadTransportData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Datos de relevamientos actualizados!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uy, hubo un error al actualizar: $e')),
        );
      }
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
    await _updateBranchDirectionStatus();
  }

  Future<void> _onBranchChanged(BranchEntry? branch) async {
    if (branch == null) return;
    setState(() => _selectedBranch = branch);
    await _updateBranchDirectionStatus();
  }

  Future<void> _updateBranchDirectionStatus() async {
    if (_selectedLine == null || _selectedBranch == null) return;

    final tripsRepo = ref.read(tripsRepositoryProvider);

    final status = await tripsRepo.getBranchDirectionStatus(_selectedLine!.id, _selectedBranch!.id);

    final idaPts = status.idaPoints;
    final vueltaPts = status.vueltaPoints;

    if (mounted) {
      setState(() {
        _directionStatus = status;
        _referenceIdaPoints = idaPts;
        _referenceVueltaPoints = vueltaPts;
        _localIdaPoints = status.localIdaPoints;
        _localVueltaPoints = status.localVueltaPoints;

        // Auto-select missing direction so user can register immediately
        if (status.hasIda && !status.hasVuelta) {
          _direction = 'VUELTA';
        } else if (status.hasVuelta && !status.hasIda) {
          _direction = 'IDA';
        }
      });
    }
  }

  void _fitCameraToLoadedTrack() {
    final allPoints = <LatLng>[
      if (_referenceIdaPoints.isNotEmpty) ..._referenceIdaPoints,
      if (_referenceVueltaPoints.isNotEmpty) ..._referenceVueltaPoints,
    ];

    if (allPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este ramal aún no tiene traza cargada para encuadrar')),
      );
      return;
    }

    final bounds = LatLngBounds.fromPoints(allPoints);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(top: 130, bottom: 300, left: 40, right: 40),
      ),
    );
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
          const SnackBar(content: Text('Foto guardada y georreferenciada')),
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
            const SnackBar(content: Text('Nota de audio guardada')),
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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _handleBackNavigation() async {
    // 1. If drawer is open, close it
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
      return;
    }

    final state = ref.read(captureNotifierProvider);

    // 2. If recording is active, inform that recording continues in background or allow exit
    if (state.status == CaptureStatus.active || state.status == CaptureStatus.paused) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.info_outline, color: Colors.blue, size: 36),
          title: const Text('RELEVAMIENTO EN CURSO'),
          content: const Text(
            'El relevamiento continuará registrándose en segundo plano.\n\n'
            '¿Desea enviar la aplicación al segundo plano o permanecer en el mapa?',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('PERMANECER EN EL MAPA'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('SALIR AL INICIO'),
            ),
          ],
        ),
      );

      if (shouldExit == true) {
        // Send app to background using SystemNavigator
        SystemNavigator.pop();
      }
      return;
    }

    // 3. If idle, show confirmation dialog before exiting app
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.exit_to_app, color: Colors.indigo, size: 36),
        title: const Text('¿CERRAR LANÚS DIGITAL?'),
        content: const Text('¿Está seguro de que desea salir de la aplicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SALIR'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        key: _scaffoldKey,
        extendBody: true,
        drawer: Drawer(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 48, bottom: 20, left: 20, right: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade900, Colors.indigo.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.location_city, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LANÚS DIGITAL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                'Movilidad Urbana y Transporte',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.system_update_alt, color: Colors.white70, size: 13),
                          SizedBox(width: 6),
                          Text(
                            'v1.0.8 · Snap to Roads & OTA',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'OPERACIONES DE CAMPO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.map, color: Colors.blue),
                      title: const Text('Mapa y Relevamiento GPS', style: TextStyle(fontWeight: FontWeight.w600)),
                      selected: true,
                      selectedTileColor: Colors.blue.withOpacity(0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.history, color: Colors.indigo),
                      title: const Text('Historial de Trazados'),
                      subtitle: const Text('Consulta de idas y vueltas guardadas', style: TextStyle(fontSize: 11)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/trips');
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Divider(),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'RED MUNICIPAL DE TRANSPORTE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.directions_bus_filled, color: Colors.teal),
                      title: const Text('Líneas y Ramales (520 - 527)'),
                      subtitle: Text('${_lines.length} líneas operativas', style: const TextStyle(fontSize: 11)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/transport');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.download_for_offline, color: Colors.orange),
                      title: const Text('Mapas Offline'),
                      subtitle: const Text('Descargas locales para trabajo sin señal', style: TextStyle(fontSize: 11)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/maps');
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Divider(),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'SISTEMA Y AJUSTES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings, color: Colors.blueGrey),
                      title: const Text('Configuración & Backup'),
                      subtitle: const Text('Actualizaciones OTA, GitHub y respaldos', style: TextStyle(fontSize: 11)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/settings');
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Municipio de Lanús · Sistema de Relevamiento',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
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


              
              // Trazas relevadas por otros usuarios (guardadas en reference_routes)
              if (_referenceIdaPoints.isNotEmpty || _referenceVueltaPoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    if (_referenceIdaPoints.isNotEmpty)
                      Polyline(
                        points: _referenceIdaPoints,
                        strokeWidth: 4.5,
                        color: Colors.blue.withOpacity(0.7),
                      ),
                    if (_referenceVueltaPoints.isNotEmpty)
                      Polyline(
                        points: _referenceVueltaPoints,
                        strokeWidth: 4.5,
                        color: Colors.orange.withOpacity(0.7),
                      ),
                  ],
                ),
              
              // Active recording track polyline
              if (_polyPoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _polyPoints,
                      strokeWidth: 5.5,
                      color: Colors.red.shade700,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  if (pos != null)
                    Marker(
                      point: currentLatLng,
                      width: 26,
                      height: 26,
                      child: Container(
                        decoration: BoxDecoration(
                          color: state.status == CaptureStatus.active ? Colors.red.shade600 : Colors.blue.shade700,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 14),
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
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          Builder(
                            builder: (ctx) => IconButton(
                              icon: const Icon(Icons.menu, color: Colors.blueGrey),
                              onPressed: () => Scaffold.of(ctx).openDrawer(),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: state.status == CaptureStatus.idle
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('LANÚS DIGITAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text(
                                        pos != null ? 'GPS Listo (±${pos.accuracy.toStringAsFixed(0)}m)' : 'Buscando señal GPS...',
                                        style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
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
                            icon: const Icon(Icons.refresh, color: Colors.blueGrey),
                            onPressed: _refreshConfig,
                            tooltip: 'Sincronizar',
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
              bottom: state.status == CaptureStatus.idle ? 270 : 260,
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
                            GestureDetector(
                              onTap: () => setState(() => _isConfigExpanded = !_isConfigExpanded),
                              behavior: HitTestBehavior.opaque,
                              child: Column(
                                children: [
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 6,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade400,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.directions_bus, color: Colors.blue, size: 22),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'CONFIGURACIÓN DE RECORRIDO',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                                        ),
                                      ),
                                      if (_directionStatus != null) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _directionStatus!.isComplete ? Colors.green.shade100 : Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _directionStatus!.isComplete ? 'TRAZO COMPLETO' : 'TRAZO EN PROCESO',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: _directionStatus!.isComplete ? Colors.green.shade900 : Colors.orange.shade900,
                                            ),
                                          ),
                                        ),
                                      ],
                                      Icon(_isConfigExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, color: Colors.grey),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  
                                  // Recorded Directions Status Badge Row
                                  if (_directionStatus != null)
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: _directionStatus!.hasAny
                                            ? Colors.green.shade50.withValues(alpha: 0.8)
                                            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _directionStatus!.hasAny ? Colors.green.shade300 : Colors.transparent,
                                        ),
                                      ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _directionStatus!.hasAny ? Icons.verified : Icons.info_outline,
                                          size: 18,
                                          color: _directionStatus!.hasAny ? Colors.green.shade700 : Colors.orange.shade800,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _directionStatus!.hasAny
                                                ? 'TRAZA RELEVADA (${GeoUtils.formatDistance(_directionStatus!.totalDistanceMeters)})'
                                                : 'PENDIENTE DE RELEVAMIENTO',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: _directionStatus!.hasAny ? Colors.green.shade900 : Colors.orange.shade900,
                                            ),
                                          ),
                                        ),
                                        if (_directionStatus!.hasAny)
                                          InkWell(
                                            onTap: _fitCameraToLoadedTrack,
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade700,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.zoom_in_map, size: 14, color: Colors.white),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'VER TRAZA',
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          _directionStatus!.hasIda ? Icons.check_circle : Icons.pending_outlined,
                                          size: 14,
                                          color: _directionStatus!.hasIda ? Colors.green.shade700 : Colors.orange.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _directionStatus!.hasIda
                                              ? 'IDA: ${GeoUtils.formatDistance(_directionStatus!.idaDistanceMeters)}'
                                              : 'IDA: Pendiente',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _directionStatus!.hasIda ? Colors.green.shade800 : Colors.orange.shade800,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          _directionStatus!.hasVuelta ? Icons.check_circle : Icons.pending_outlined,
                                          size: 14,
                                          color: _directionStatus!.hasVuelta ? Colors.green.shade700 : Colors.orange.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _directionStatus!.hasVuelta
                                              ? 'VUELTA: ${GeoUtils.formatDistance(_directionStatus!.vueltaDistanceMeters)}'
                                              : 'VUELTA: Pendiente',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _directionStatus!.hasVuelta ? Colors.green.shade800 : Colors.orange.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ), // End of Container
                            ],
                          ),
                        ), // End of GestureDetector

                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: _isConfigExpanded ? Column(
                                children: [
                            InkWell(
                              onTap: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.filter_list,
                                      size: 14,
                                      color: _selectedHierarchy != null ? Colors.blue.shade700 : Colors.blueGrey.shade500,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedHierarchy != null ? 'Jurisdicción: ${_selectedHierarchy!.split(' ')[1]}' : 'Filtrar por jurisdicción (Opcional)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedHierarchy != null ? Colors.blue.shade700 : Colors.blueGrey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              child: _isFilterExpanded
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 6.0, bottom: 8.0),
                                      child: DropdownButtonFormField<String?>(
                                        value: _selectedHierarchy,
                                        isDense: true,
                                        borderRadius: BorderRadius.circular(16),
                                        decoration: InputDecoration(
                                          labelText: 'Jurisdicción',
                                          labelStyle: TextStyle(color: Colors.blueGrey.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                                          prefixIcon: Icon(Icons.account_balance, color: Colors.blueGrey.shade400, size: 18),
                                          filled: true,
                                          fillColor: Colors.blueGrey.shade50,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        ),
                                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                                        items: const [
                                          DropdownMenuItem(value: null, child: Text('Todas las líneas')),
                                          DropdownMenuItem(value: 'Jurisdicción Nacional', child: Text('Nacional (1-199)')),
                                          DropdownMenuItem(value: 'Jurisdicción Provincial', child: Text('Provincial (200-499)')),
                                          DropdownMenuItem(value: 'Jurisdicción Municipal', child: Text('Municipal (500+)')),
                                        ],
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedHierarchy = val;
                                            _isFilterExpanded = false; // Auto close on select
                                            if (_selectedLine != null && val != null && _selectedLine!.hierarchy != val) {
                                              _selectedLine = null;
                                              _branches = [];
                                              _selectedBranch = null;
                                            }
                                          });
                                        },
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            DropdownButtonFormField<LineEntry>(
                              value: _selectedLine,
                              isDense: true,
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(16),
                              decoration: InputDecoration(
                                labelText: '¿Qué línea vas a relevar?',
                                labelStyle: TextStyle(color: Colors.blueGrey.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                                prefixIcon: Icon(Icons.format_list_numbered, color: Colors.blueGrey.shade400, size: 20),
                                filled: true,
                                fillColor: Colors.blueGrey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: _lines
                                  .where((l) => _selectedHierarchy == null || l.hierarchy == _selectedHierarchy)
                                  .map((l) => DropdownMenuItem(
                                        value: l,
                                        child: Text('Línea ${l.number}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ))
                                  .toList(),
                              onChanged: _onLineChanged,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<BranchEntry>(
                              value: _selectedBranch,
                              isDense: true,
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(16),
                              decoration: InputDecoration(
                                labelText: '¿Y cuál ramal?',
                                labelStyle: TextStyle(color: Colors.blueGrey.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                                prefixIcon: Icon(Icons.alt_route, color: Colors.blueGrey.shade400, size: 20),
                                filled: true,
                                fillColor: Colors.blueGrey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: _branches
                                  .map((b) => DropdownMenuItem(
                                        value: b,
                                        child: Text(b.name, overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: _onBranchChanged,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: SegmentedButton<String>(
                                    style: SegmentedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                                      backgroundColor: Colors.white,
                                      selectedBackgroundColor: Colors.blue.shade100,
                                      selectedForegroundColor: Colors.blue.shade900,
                                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    segments: const [
                                      ButtonSegment(value: 'IDA', label: Text('IDA'), icon: Icon(Icons.arrow_forward, size: 16)),
                                      ButtonSegment(value: 'VUELTA', label: Text('VUELTA'), icon: Icon(Icons.arrow_back, size: 16)),
                                    ],
                                    selected: {_direction},
                                    onSelectionChanged: (set) => setState(() => _direction = set.first),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: () => setState(() => _isVehicleExpanded = !_isVehicleExpanded),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Datos del vehículo (Opcional)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _isVehicleExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                      size: 18,
                                      color: Colors.blueGrey.shade600,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              child: _isVehicleExpanded
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _internalController,
                                              decoration: InputDecoration(
                                                labelText: 'Interno',
                                                labelStyle: TextStyle(color: Colors.blueGrey.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                                                isDense: true,
                                                prefixIcon: Icon(Icons.tag, size: 18, color: Colors.blueGrey.shade400),
                                                filled: true,
                                                fillColor: Colors.blueGrey.shade50,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              ),
                                              style: const TextStyle(fontSize: 13),
                                              keyboardType: TextInputType.number,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextField(
                                              controller: _domainController,
                                              decoration: InputDecoration(
                                                labelText: 'Patente',
                                                labelStyle: TextStyle(color: Colors.blueGrey.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                                                isDense: true,
                                                prefixIcon: Icon(Icons.badge_outlined, size: 18, color: Colors.blueGrey.shade400),
                                                filled: true,
                                                fillColor: Colors.blueGrey.shade50,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              ),
                                              style: const TextStyle(fontSize: 13),
                                              textCapitalization: TextCapitalization.characters,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                                ],
                              ) : const SizedBox.shrink(),
                            ), // End of AnimatedSize items
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(54),
                                backgroundColor: _directionStatus?.isComplete == true
                                    ? Colors.blue.shade800
                                    : (_directionStatus?.hasIda == true && _direction == 'VUELTA'
                                        ? Colors.teal.shade700
                                        : Colors.blue.shade700),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: _startCapture,
                              icon: const Icon(Icons.play_arrow_rounded, size: 30),
                              label: Text(
                                _directionStatus?.hasIda == true && _direction == 'VUELTA'
                                    ? 'GRABAR LA VUELTA'
                                    : 'EMPEZAR RECORRIDO',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
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
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    ),
  );
}
}
