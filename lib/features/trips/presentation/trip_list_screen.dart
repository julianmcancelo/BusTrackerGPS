import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../database/database_provider.dart';
import '../../../core/services/sync_service.dart';
import '../../capture/data/gps_repository.dart';
import '../data/trips_repository.dart';
import '../../../core/utils/geo_utils.dart';

class TripListScreen extends ConsumerStatefulWidget {
  const TripListScreen({super.key});

  @override
  ConsumerState<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends ConsumerState<TripListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _directionFilter;
  String? _hierarchyFilter;
  final Set<String> _syncingTrips = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Column(
        children: [
          // Search & Direction Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por línea, ramal...',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Nacional'),
                        selected: _hierarchyFilter == 'Jurisdicción Nacional',
                        onSelected: (_) => setState(() => _hierarchyFilter = _hierarchyFilter == 'Jurisdicción Nacional' ? null : 'Jurisdicción Nacional'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Provincial'),
                        selected: _hierarchyFilter == 'Jurisdicción Provincial',
                        onSelected: (_) => setState(() => _hierarchyFilter = _hierarchyFilter == 'Jurisdicción Provincial' ? null : 'Jurisdicción Provincial'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Municipal'),
                        selected: _hierarchyFilter == 'Jurisdicción Municipal',
                        onSelected: (_) => setState(() => _hierarchyFilter = _hierarchyFilter == 'Jurisdicción Municipal' ? null : 'Jurisdicción Municipal'),
                      ),
                      const SizedBox(width: 16),
                      const Text('|', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 16),
                      FilterChip(
                        label: const Text('Todos'),
                        selected: _directionFilter == null,
                        onSelected: (_) => setState(() => _directionFilter = null),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('IDA'),
                        selected: _directionFilter == 'IDA',
                        onSelected: (_) => setState(() => _directionFilter = 'IDA'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('VUELTA'),
                        selected: _directionFilter == 'VUELTA',
                        onSelected: (_) => setState(() => _directionFilter = 'VUELTA'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Trip List
          Expanded(
            child: StreamBuilder<List<TripWithDetails>>(
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_bus_outlined, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Aún no hay viajes grabados en este dispositivo',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: trips.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      itemBuilder: (context, idx) {
                        final item = trips[idx];
                        final t = item.trip;
                        final isSyncing = _syncingTrips.contains(t.id);
                        final startTimeStr = DateFormat('dd/MM/yyyy · HH:mm').format(t.startedAt);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: const Icon(Icons.directions_bus, color: Color(0xFF1E88E5)),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.line.number} · ${item.branch.name} · ${t.direction}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                                if (isSyncing)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else if (t.syncStatus == 'SYNCED')
                                  const Tooltip(
                                    message: 'Sincronizado con Lanús Digital',
                                    child: Icon(Icons.cloud_done_rounded, color: Color(0xFF16A34A), size: 22),
                                  )
                                else
                                  IconButton(
                                    icon: const Icon(Icons.cloud_upload_outlined, color: Colors.orange, size: 22),
                                    tooltip: 'Transferir a Lanús Digital',
                                    onPressed: () => _manualSyncTrip(item),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(startTimeStr, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  '${GeoUtils.formatDistance(t.distanceMeters)} · ${GeoUtils.formatDuration(Duration(milliseconds: t.durationMs))} · '
                                  '${t.stopCount} paradas · ${t.incidentCount} incidencias',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                  tooltip: 'Eliminar traza',
                                  onPressed: () => _confirmDeleteTrip(item),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () {
                              context.push('/trips/${t.id}');
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
