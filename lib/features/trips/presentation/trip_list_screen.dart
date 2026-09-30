import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    final tripsRepo = ref.watch(tripsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HISTORIAL DE VIAJES'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por línea, ramal, interno, dominio...',
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
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
              ],
            ),
          ),

          // Trips List Stream
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
                  return const Center(
                    child: Text('No se encontraron recorridos capturados'),
                  );
                }

                return ListView.builder(
                  itemCount: trips.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, idx) {
                    final item = trips[idx];
                    final t = item.trip;
                    final startTimeStr = DateFormat('dd/MM/yyyy · HH:mm').format(t.startedAt);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.directions_bus, color: Colors.blue),
                        ),
                        title: Text(
                          '🚍 ${item.line.number} · ${item.branch.name} · ${t.direction}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(startTimeStr),
                            const SizedBox(height: 4),
                            Text(
                              '${GeoUtils.formatDistance(t.distanceMeters)} · ${GeoUtils.formatDuration(Duration(milliseconds: t.durationMs))}\n'
                              '${t.stopCount} paradas · ${t.incidentCount} incidencias',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
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
