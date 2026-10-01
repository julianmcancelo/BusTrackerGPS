import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

import 'transit_controller.dart';
import 'widgets/transit_line_chips.dart';
import 'widgets/transit_bottom_panel.dart';
import 'line_itinerary_screen.dart';
import '../data/models/transit_models.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';

class TransitMapScreen extends ConsumerStatefulWidget {
  const TransitMapScreen({super.key});

  @override
  ConsumerState<TransitMapScreen> createState() => _TransitMapScreenState();
}

class _TransitMapScreenState extends ConsumerState<TransitMapScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;

  // Lanús center coordinates: ~ -34.7065, -58.3934
  static const LatLng _lanusCenter = LatLng(-34.7065, -58.3934);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fitLineCamera(TransitLineSummary? line, TransitBranchSummary? branch) {
    if (line == null || branch == null) {
      _mapController.move(_lanusCenter, 13.0);
      return;
    }

    final points = <LatLng>[];
    final dir = ref.read(transitControllerProvider).directionFilter;

    if (dir == TransitDirectionFilter.ida || dir == TransitDirectionFilter.both) {
      points.addAll(branch.idaPoints);
    }
    if (dir == TransitDirectionFilter.vuelta || dir == TransitDirectionFilter.both) {
      points.addAll(branch.vueltaPoints);
    }

    if (points.isEmpty) {
      _mapController.move(_lanusCenter, 13.0);
      return;
    }

    if (points.length == 1) {
      _mapController.move(points.first, 15.0);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(40, 90, 40, 220),
      ),
    );
  }

  void _fitAllNetworkCamera() {
    final state = ref.read(transitControllerProvider);
    final allPoints = <LatLng>[];

    for (final line in state.allLines) {
      if (state.enabledLineIds.contains(line.id)) {
        for (final branch in line.branches) {
          allPoints.addAll(branch.idaPoints);
          allPoints.addAll(branch.vueltaPoints);
        }
      }
    }

    if (allPoints.isEmpty) {
      _mapController.move(_lanusCenter, 13.0);
      return;
    }

    final bounds = LatLngBounds.fromPoints(allPoints);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(30, 90, 30, 220),
      ),
    );
  }

  void _centerOnUser() {
    final userLoc = ref.read(transitControllerProvider).userLocation;
    if (userLoc != null) {
      _mapController.move(userLoc, 16.0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buscando señal GPS actual...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transitControllerProvider);
    final notifier = ref.read(transitControllerProvider.notifier);

    final focusedLine = state.focusedLine;
    final focusedBranch = state.focusedBranch;

    // Build Polylines
    final polylines = <Polyline>[];
    for (final line in state.allLines) {
      if (!state.enabledLineIds.contains(line.id)) continue;

      final isLineFocused = state.focusedLineId == line.id;
      final branchesToRender = isLineFocused && focusedBranch != null
          ? [focusedBranch]
          : line.branches;

      for (final branch in branchesToRender) {
        // Ida
        if (state.directionFilter == TransitDirectionFilter.ida ||
            state.directionFilter == TransitDirectionFilter.both) {
          if (branch.idaPoints.isNotEmpty) {
            polylines.add(
              Polyline(
                points: branch.idaPoints,
                strokeWidth: isLineFocused ? 5.0 : 3.0,
                color: isLineFocused ? line.color : line.color.withValues(alpha: 0.55),
              ),
            );
          }
        }

        // Vuelta
        if (state.directionFilter == TransitDirectionFilter.vuelta ||
            state.directionFilter == TransitDirectionFilter.both) {
          if (branch.vueltaPoints.isNotEmpty) {
            polylines.add(
              Polyline(
                points: branch.vueltaPoints,
                strokeWidth: isLineFocused ? 4.5 : 2.5,
                color: isLineFocused
                    ? line.color.withValues(alpha: 0.85)
                    : line.color.withValues(alpha: 0.45),
              ),
            );
          }
        }
      }
    }

    // Build Markers
    final markers = <Marker>[];

    // User location marker
    if (state.userLocation != null) {
      markers.add(
        Marker(
          point: state.userLocation!,
          width: 32,
          height: 32,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.person_pin_circle, color: Colors.white, size: 18),
          ),
        ),
      );
    }

    // Stop markers
    if (state.showStops && focusedLine != null && state.stops.isNotEmpty) {
      for (final stop in state.stops) {
        final isSelected = state.selectedStop?.id == stop.id;
        final isStart = stop == state.stops.first;
        final isEnd = stop == state.stops.last;

        markers.add(
          Marker(
            point: stop.position,
            width: isSelected || isStart || isEnd ? 34 : 22,
            height: isSelected || isStart || isEnd ? 34 : 22,
            child: GestureDetector(
              onTap: () => notifier.selectStop(stop),
              child: Container(
                decoration: BoxDecoration(
                  color: isStart
                      ? Colors.green.shade700
                      : (isEnd ? Colors.red.shade700 : (isSelected ? Colors.black87 : focusedLine.color)),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: isSelected ? 2.5 : 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isStart
                        ? Icons.flag
                        : (isEnd ? Icons.sports_score : Icons.directions_bus),
                    color: Colors.white,
                    size: isSelected || isStart || isEnd ? 18 : 12,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Scaffold(
      key: _scaffoldKey,
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
                    leading: const Icon(Icons.alt_route, color: Color(0xFF0284C7)),
                    title: const Text('Transporte Público (Red y Mapa)', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Visor interactivo de colectivos, trazas y paradas', style: TextStyle(fontSize: 11)),
                    selected: true,
                    selectedTileColor: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.directions_bus_filled, color: Colors.teal),
                    title: const Text('Gestión de Líneas y Ramales'),
                    subtitle: Text('${state.allLines.length} líneas operativas · Carga y sincronización', style: const TextStyle(fontSize: 11)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history, color: Colors.indigo),
                    title: const Text('Historial de Trazados'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/trips');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer_outlined, color: Color(0xFF0284C7)),
                    title: const Text('Control de Frecuencias (Aforo)', style: TextStyle(fontWeight: FontWeight.w600)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/frequency');
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.blueGrey),
                    title: const Text('Ajustes y Parámetros'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // 1. FlutterMap base
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _lanusCenter,
              initialZoom: 13.5,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bitacoragps.app.bitacora_gps',
              ),
              PolylineLayer(polylines: polylines),
              MarkerLayer(markers: markers),
            ],
          ),

          // 2. Top App Bar & Header
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Search & Title Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.blueGrey),
                        tooltip: 'Abrir menú',
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _isSearchExpanded
                            ? TextField(
                                controller: _searchController,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: 'Buscar línea o ramal...',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (q) => notifier.setSearchQuery(q),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'TRANSPORTE PÚBLICO',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'Red Municipal de Colectivos · Lanús',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isSearchExpanded ? Icons.close : Icons.search,
                          color: Colors.blueGrey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSearchExpanded = !_isSearchExpanded;
                            if (!_isSearchExpanded) {
                              _searchController.clear();
                              notifier.setSearchQuery('');
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.app_registration, color: Colors.blueGrey),
                        tooltip: 'Gestión y Carga de Líneas',
                        onPressed: () => context.push('/transport'),
                      ),
                    ],
                  ),
                ),

                // Top Line Selector Chips
                TransitLineChips(
                  lines: state.filteredLines,
                  enabledLineIds: state.enabledLineIds,
                  focusedLineId: state.focusedLineId,
                  onLineToggled: (id) => notifier.toggleLineVisibility(id),
                  onLineFocused: (id) {
                    notifier.focusLine(id);
                    final line = state.allLines.where((l) => l.id == id).firstOrNull;
                    _fitLineCamera(line, line?.primaryBranch);
                  },
                  onShowAll: () {
                    notifier.showAllLines();
                    _fitAllNetworkCamera();
                  },
                ),
              ],
            ),
          ),

          // 3. Floating Quick Action Controls (Right side)
          Positioned(
            right: 14,
            top: 130,
            child: Column(
              children: [
                // Locate Me Button
                FloatingActionButton.small(
                  heroTag: 'transit_locate_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade800,
                  onPressed: _centerOnUser,
                  tooltip: 'Mi ubicación',
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 10),

                // Fit Network Bounds Button
                FloatingActionButton.small(
                  heroTag: 'transit_fit_network_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueGrey.shade800,
                  onPressed: () => _fitLineCamera(focusedLine, focusedBranch),
                  tooltip: 'Ajustar a recorrido',
                  child: const Icon(Icons.center_focus_strong),
                ),
                const SizedBox(height: 10),

                // Toggle Stops Layer
                FloatingActionButton.small(
                  heroTag: 'transit_stops_btn',
                  backgroundColor: state.showStops ? Colors.blue.shade900 : Colors.white,
                  foregroundColor: state.showStops ? Colors.white : Colors.blueGrey.shade700,
                  onPressed: () => notifier.toggleStopsVisibility(),
                  tooltip: state.showStops ? 'Ocultar paradas' : 'Ver paradas',
                  child: const Icon(Icons.directions_bus),
                ),
              ],
            ),
          ),

          // 4. Floating Selected Stop Info Card (if stop tapped)
          if (state.selectedStop != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 230,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (focusedLine?.color ?? Colors.blue).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.directions_bus, color: focusedLine?.color ?? Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.selectedStop!.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Líneas: ${state.selectedStop!.lineNumbers.join(", ")}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => notifier.selectStop(null),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Bottom Info Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: TransitBottomPanel(
              focusedLine: focusedLine,
              focusedBranch: focusedBranch,
              directionFilter: state.directionFilter,
              stopsCount: state.stops.length,
              onBranchSelected: (branchId) {
                notifier.selectBranch(branchId);
                final br = focusedLine?.branches.where((b) => b.branch.id == branchId).firstOrNull;
                _fitLineCamera(focusedLine, br);
              },
              onDirectionChanged: (filter) => notifier.setDirectionFilter(filter),
              onFitCamera: () => _fitLineCamera(focusedLine, focusedBranch),
              onViewItinerary: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LineItineraryScreen()),
                );
              },
              onAdminLines: () => context.push('/transport'),
            ),
          ),
        ],
      ),
    );
  }
}
