import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

import '../data/trips_repository.dart';
import '../../../core/utils/geo_utils.dart';
import '../../capture/presentation/capture_notifier.dart';

class ReferenceRouteDetailScreen extends ConsumerStatefulWidget {
  final int routeId;
  const ReferenceRouteDetailScreen({super.key, required this.routeId});

  @override
  ConsumerState<ReferenceRouteDetailScreen> createState() => _ReferenceRouteDetailScreenState();
}

class _ReferenceRouteDetailScreenState extends ConsumerState<ReferenceRouteDetailScreen> {
  final MapController _mapController = MapController();
  ReferenceRouteWithDetails? _details;
  List<LatLng> _points = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tripsRepo = ref.read(tripsRepositoryProvider);
    final details = await tripsRepo.getReferenceRouteWithDetails(widget.routeId);

    if (details != null) {
      final points = GeoUtils.parseGeoJsonCoordinates(details.route.geoJsonData);
      if (mounted) {
        setState(() {
          _details = details;
          _points = points;
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 250), () {
            if (mounted) _fitCamera();
          });
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _fitCamera() {
    if (!mounted || _points.isEmpty) return;
    try {
      if (_points.length == 1) {
        _mapController.move(_points.first, 15.0);
        return;
      }
      final bounds = LatLngBounds.fromPoints(_points);
      if ((bounds.north - bounds.south).abs() < 0.0001 &&
          (bounds.east - bounds.west).abs() < 0.0001) {
        _mapController.move(_points.first, 15.0);
        return;
      }
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(36),
        ),
      );
    } catch (_) {}
  }

  Future<void> _startCaptureFromReference() async {
    if (_details == null) return;
    await ref.read(captureNotifierProvider.notifier).startCapture(
          line: _details!.line,
          branch: _details!.branch,
          direction: _details!.route.direction.toUpperCase(),
        );
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando traza...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_details == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No se encontró la traza relevada')),
      );
    }

    final r = _details!.route;
    final line = _details!.line;
    final branch = _details!.branch;
    final isIda = r.direction.toUpperCase() == 'IDA';
    final polyColor = isIda ? const Color(0xFF2563EB) : const Color(0xFF059669);

    return Scaffold(
      appBar: AppBar(
        title: Text('${line.number} · ${branch.name} (${r.direction})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in_map),
            tooltip: 'Ajustar mapa',
            onPressed: _fitCamera,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info summary card
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: polyColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.cloud_done_rounded, color: polyColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Línea ${line.number} - ${branch.name}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Relevamiento Comunitario / Servidor Lanús Digital',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: polyColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          r.direction.toUpperCase(),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: polyColor),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Distancia', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            GeoUtils.formatDistance(_details!.distanceMeters),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Puntos GPS', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            '${_details!.pointCount}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Fecha Registro', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd/MM/yyyy').format(r.createdAt),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Map View
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _points.isNotEmpty
                          ? _points[_points.length ~/ 2]
                          : const LatLng(-34.700, -58.380),
                      initialZoom: _points.isNotEmpty ? 13.5 : 12.0,
                      onMapReady: () {
                        Future.delayed(const Duration(milliseconds: 250), () {
                          if (mounted) _fitCamera();
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.bitacoragps.app.bitacora_gps',
                      ),
                      if (_points.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _points,
                              strokeWidth: 5.5,
                              color: polyColor,
                            ),
                          ],
                        ),
                      if (_points.isNotEmpty)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _points.first,
                              width: 32,
                              height: 32,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: const Icon(Icons.flag, color: Colors.white, size: 16),
                              ),
                            ),
                            Marker(
                              point: _points.last,
                              width: 32,
                              height: 32,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: const Icon(Icons.sports_score, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  // Floating re-center button
                  if (_points.isNotEmpty)
                    Positioned(
                      right: 14,
                      bottom: 14,
                      child: FloatingActionButton.small(
                        heroTag: 'recenter_route_fab',
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade800,
                        onPressed: _fitCamera,
                        tooltip: 'Encuadrar traza',
                        child: const Icon(Icons.center_focus_strong, size: 20),
                      ),
                    ),

                  // Empty points banner
                  if (_points.isEmpty)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Esta traza aún no contiene coordenadas geográficas trazadas en el servidor.',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2))],
            ),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.blue.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _startCaptureFromReference,
              icon: const Icon(Icons.directions_bus),
              label: const Text('RELEVAR O GRABAR ESTA LÍNEA AHORA', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
