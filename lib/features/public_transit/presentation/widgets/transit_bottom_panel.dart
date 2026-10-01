import 'package:flutter/material.dart';
import '../../data/models/transit_models.dart';

class TransitBottomPanel extends StatelessWidget {
  final TransitLineSummary? focusedLine;
  final TransitBranchSummary? focusedBranch;
  final TransitDirectionFilter directionFilter;
  final int stopsCount;
  final ValueChanged<int> onBranchSelected;
  final ValueChanged<TransitDirectionFilter> onDirectionChanged;
  final VoidCallback onFitCamera;
  final VoidCallback onViewItinerary;
  final VoidCallback onAdminLines;
  final VoidCallback? onPrintSheet;

  const TransitBottomPanel({
    super.key,
    required this.focusedLine,
    required this.focusedBranch,
    required this.directionFilter,
    required this.stopsCount,
    required this.onBranchSelected,
    required this.onDirectionChanged,
    required this.onFitCamera,
    required this.onViewItinerary,
    required this.onAdminLines,
    this.onPrintSheet,
  });

  @override
  Widget build(BuildContext context) {
    if (focusedLine == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.touch_app, color: Colors.blueGrey),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Seleccioná una línea superior para ver ramales e itinerario.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
            TextButton.icon(
              onPressed: onAdminLines,
              icon: const Icon(Icons.settings_outlined, size: 16),
              label: const Text('Gestión', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    final line = focusedLine!;
    final branch = focusedBranch;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: line.color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: line.color.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    line.number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Línea ${line.number}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      line.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.crop_free, color: Colors.blueGrey),
                tooltip: 'Centrar en el mapa',
                onPressed: onFitCamera,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Branch selection & Direction toggle row
          Row(
            children: [
              // Branch dropdown
              if (line.branches.isNotEmpty)
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: branch?.branch.id ?? line.branches.first.branch.id,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        items: line.branches.map((b) {
                          return DropdownMenuItem<int>(
                            value: b.branch.id,
                            child: Text(
                              'Ramal: ${b.branch.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null) onBranchSelected(id);
                        },
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),

              // Direction toggle
              Expanded(
                flex: 4,
                child: SegmentedButton<TransitDirectionFilter>(
                  segments: const [
                    ButtonSegment(
                      value: TransitDirectionFilter.ida,
                      label: Text('Ida', style: TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment(
                      value: TransitDirectionFilter.vuelta,
                      label: Text('Vta', style: TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment(
                      value: TransitDirectionFilter.both,
                      label: Text('Ambos', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  selected: {directionFilter},
                  onSelectionChanged: (set) {
                    if (set.isNotEmpty) onDirectionChanged(set.first);
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 4)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quick distance & stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: line.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: line.color.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.alt_route,
                  label: 'Ida',
                  value: branch != null && branch.idaDistanceKm > 0
                      ? '${branch.idaDistanceKm.toStringAsFixed(1)} km'
                      : 'Sin traza',
                  color: line.color,
                ),
                Container(height: 24, width: 1, color: Colors.grey.shade300),
                _buildStatItem(
                  icon: Icons.u_turn_left,
                  label: 'Vuelta',
                  value: branch != null && branch.vueltaDistanceKm > 0
                      ? '${branch.vueltaDistanceKm.toStringAsFixed(1)} km'
                      : 'Sin traza',
                  color: line.color,
                ),
                Container(height: 24, width: 1, color: Colors.grey.shade300),
                _buildStatItem(
                  icon: Icons.directions_bus,
                  label: 'Paradas',
                  value: stopsCount > 0 ? '$stopsCount' : '0',
                  color: line.color,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onViewItinerary,
                  style: FilledButton.styleFrom(
                    backgroundColor: line.color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.format_list_bulleted, size: 18),
                  label: const Text(
                    'ITINERARIO Y PARADAS',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
              if (onPrintSheet != null) ...[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: onPrintSheet,
                  tooltip: 'Imprimir Plano Cartográfico Oficial (A0-A4)',
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.print_outlined, size: 20),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }
}
