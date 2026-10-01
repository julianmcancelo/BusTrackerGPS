import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'transit_controller.dart';
import '../data/models/transit_models.dart';

class LineItineraryScreen extends ConsumerStatefulWidget {
  const LineItineraryScreen({super.key});

  @override
  ConsumerState<LineItineraryScreen> createState() => _LineItineraryScreenState();
}

class _LineItineraryScreenState extends ConsumerState<LineItineraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transitControllerProvider);
    final line = state.focusedLine;
    final branch = state.focusedBranch;

    if (line == null || branch == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Itinerario')),
        body: const Center(
          child: Text('No hay línea seleccionada.'),
        ),
      );
    }

    final color = line.color;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Línea ${line.number} · Itinerario',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              'Ramal: ${branch.branch.name}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.alt_route, size: 20),
              text: 'IDA (${branch.idaDistanceKm.toStringAsFixed(1)} km)',
            ),
            Tab(
              icon: const Icon(Icons.u_turn_left, size: 20),
              text: 'VUELTA (${branch.vueltaDistanceKm.toStringAsFixed(1)} km)',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDirectionItinerary(
            context: context,
            line: line,
            branch: branch,
            direction: TransitDirectionFilter.ida,
            pointsCount: branch.idaPoints.length,
            distanceKm: branch.idaDistanceKm,
          ),
          _buildDirectionItinerary(
            context: context,
            line: line,
            branch: branch,
            direction: TransitDirectionFilter.vuelta,
            pointsCount: branch.vueltaPoints.length,
            distanceKm: branch.vueltaDistanceKm,
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionItinerary({
    required BuildContext context,
    required TransitLineSummary line,
    required TransitBranchSummary branch,
    required TransitDirectionFilter direction,
    required int pointsCount,
    required double distanceKm,
  }) {
    final state = ref.watch(transitControllerProvider);
    final stops = state.stops.where((s) => s.direction == direction.label).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Card
        Card(
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: line.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'SENTIDO ${direction.label}',
                        style: TextStyle(
                          color: line.color,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${distanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Empresa / Operador: ${line.name}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                Text(
                  'Puntos de traza GPS: $pointsCount',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'PARADAS Y PUNTOS DEL RECORRIDO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 10),

        if (stops.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.route, size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'No hay paradas generadas para el sentido ${direction.label}.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          ...stops.map((stop) {
            final isFirst = stop == stops.first;
            final isLast = stop == stops.last;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline column
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isFirst || isLast ? line.color : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: line.color,
                            width: 2.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${stop.sequence ?? 1}',
                            style: TextStyle(
                              color: isFirst || isLast ? Colors.white : line.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: line.color.withValues(alpha: 0.4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Stop Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  stop.name,
                                  style: TextStyle(
                                    fontWeight: isFirst || isLast ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (isFirst)
                                const Chip(
                                  label: Text('ORIGEN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                              if (isLast)
                                const Chip(
                                  label: Text('DESTINO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Coord: ${stop.position.latitude.toStringAsFixed(5)}, ${stop.position.longitude.toStringAsFixed(5)}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () {
                              ref.read(transitControllerProvider.notifier).selectStop(stop);
                              context.pop();
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_searching, size: 14, color: line.color),
                                const SizedBox(width: 4),
                                Text(
                                  'Ver en mapa',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: line.color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
