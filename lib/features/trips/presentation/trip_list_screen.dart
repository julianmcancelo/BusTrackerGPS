import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../database/database_provider.dart';
import '../../../core/services/sync_service.dart';
import '../../capture/data/gps_repository.dart';
import '../data/trips_repository.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';

class TripListScreen extends ConsumerStatefulWidget {
  const TripListScreen({super.key});

  @override
  ConsumerState<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends ConsumerState<TripListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _directionFilter;
  final Set<String> _syncingTrips = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _manualSyncTrip(TripWithDetails item) async {
    final tripId = item.trip.id;
    setState(() => _syncingTrips.add(tripId));

    final db = ref.read(databaseProvider);
    final gpsRepo = ref.read(gpsRepositoryProvider);

    final trackPoints = await gpsRepo.getTrackPoints(tripId);
    final stops = await gpsRepo.getStops(tripId);
    final incidents = await gpsRepo.getIncidents(tripId);

    final result = await SyncService.syncTrip(
      db: db,
      trip: item.trip,
      line: item.line,
      branch: item.branch,
      trackPoints: trackPoints,
      stops: stops,
      incidents: incidents,
    );

    if (mounted) {
      setState(() => _syncingTrips.remove(tripId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Recorrido ${item.line.number} sincronizado con Lanús Digital'
                : 'No se pudo sincronizar: ${result.message}',
          ),
          backgroundColor: result.success ? Colors.green.shade700 : Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _confirmDeleteTrip(TripWithDetails item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Recorrido'),
        content: Text(
          '¿Está seguro de que desea eliminar la traza grabada de la Línea ${item.line.number} (${item.branch.name})?\n\nEsta acción borrará los puntos GPS, paradas e incidencias asociadas localmente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(tripsRepositoryProvider).deleteTrip(item.trip.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recorrido ${item.line.number} eliminado'),
            backgroundColor: Colors.grey.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripsRepo = ref.watch(tripsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HISTORIAL DE RELEVAMIENTOS'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.timer_outlined),
            tooltip: 'Control de Frecuencias',
            onPressed: () => context.push('/frequency'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.cloud_outlined, size: 20), text: 'Trazas Bitácora GPS'),
            Tab(icon: Icon(Icons.phone_android, size: 20), text: 'Mis Grabaciones Locales'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por línea, ramal...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Todos', style: TextStyle(fontSize: 11)),
                      selected: _directionFilter == null,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _directionFilter = null),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('IDA', style: TextStyle(fontSize: 11)),
                      selected: _directionFilter == 'IDA',
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _directionFilter = 'IDA'),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('VUELTA', style: TextStyle(fontSize: 11)),
                      selected: _directionFilter == 'VUELTA',
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _directionFilter = 'VUELTA'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // TabBarView Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Bitácora GPS Reference Routes
                _buildReferenceRoutesTab(tripsRepo),

                // Tab 2: Local Recorded Trips
                _buildLocalTripsTab(tripsRepo),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildReferenceRoutesTab(TripsRepository tripsRepo) {
    return StreamBuilder<List<ReferenceRouteWithDetails>>(
      stream: tripsRepo.watchReferenceRoutes(
        searchQuery: _searchQuery,
        direction: _directionFilter,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final routes = snapshot.data ?? [];
        if (routes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'No hay trazas de Bitácora GPS disponibles',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ve a Ajustes > Sincronización para descargar los relevamientos de la red.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/settings'),
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('IR A AJUSTES DE SINCRONIZACIÓN'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: routes.length,
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 80),
          itemBuilder: (context, idx) {
            final item = routes[idx];
            final r = item.route;
            final isIda = r.direction.toUpperCase() == 'IDA';

            return Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              child: InkWell(
                onTap: () => context.push('/reference-routes/${r.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isIda
                                ? [const Color(0xFF0284C7), const Color(0xFF0369A1)]
                                : [const Color(0xFFD97706), const Color(0xFFB45309)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.line.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.branch.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: (isIda ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    r.direction,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isIda ? Colors.blue.shade800 : Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${GeoUtils.formatDistance(item.distanceMeters)} · ${item.pointCount} puntos GPS',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.grey, size: 22),
                        tooltip: 'Ver traza en mapa',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          context.push('/reference-routes/${r.id}');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLocalTripsTab(TripsRepository tripsRepo) {
    return StreamBuilder<List<TripWithDetails>>(
      stream: tripsRepo.watchTrips(
        searchQuery: _searchQuery,
        direction: _directionFilter,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final trips = snapshot.data ?? [];
        if (trips.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bus_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'No hay viajes grabados en este dispositivo',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Inicia una grabación desde la pantalla principal para registrar un recorrido.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('INICIAR NUEVO RELEVAMIENTO'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: trips.length,
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 80),
          itemBuilder: (context, idx) {
            final item = trips[idx];
            final t = item.trip;
            final isSyncing = _syncingTrips.contains(t.id);
            final isSynced = t.syncStatus == 'SYNCED';
            final isIda = t.direction.toUpperCase() == 'IDA';

            return Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push('/trips/${t.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isIda
                                ? [const Color(0xFF0284C7), const Color(0xFF0369A1)]
                                : [const Color(0xFFD97706), const Color(0xFFB45309)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.line.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.branch.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: (isIda ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    t.direction,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isIda ? Colors.blue.shade800 : Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${DateFormat('dd/MM/yyyy HH:mm').format(t.startedAt)} · ${GeoUtils.formatDistance(t.distanceMeters)}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (isSyncing)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (!isSynced)
                        IconButton(
                          icon: const Icon(Icons.cloud_upload_outlined, color: Colors.blue, size: 20),
                          tooltip: 'Sincronizar a Lanús Digital',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _manualSyncTrip(item),
                        )
                      else
                        const Icon(Icons.cloud_done, color: Colors.green, size: 18),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        tooltip: 'Eliminar viaje',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _confirmDeleteTrip(item),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
