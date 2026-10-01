import 'package:flutter/material.dart';
import '../../data/models/transit_models.dart';

class TransitLineChips extends StatelessWidget {
  final List<TransitLineSummary> lines;
  final Set<int> enabledLineIds;
  final int? focusedLineId;
  final ValueChanged<int> onLineToggled;
  final ValueChanged<int> onLineFocused;
  final VoidCallback onShowAll;

  const TransitLineChips({
    super.key,
    required this.lines,
    required this.enabledLineIds,
    required this.focusedLineId,
    required this.onLineToggled,
    required this.onLineFocused,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();

    final allSelected = lines.every((l) => enabledLineIds.contains(l.id));

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          // Chip "TODAS"
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('TODAS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              selected: allSelected,
              onSelected: (_) => onShowAll(),
              selectedColor: Colors.blue.shade900,
              labelStyle: TextStyle(
                color: allSelected ? Colors.white : Colors.black87,
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.92),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: allSelected ? Colors.blue.shade900 : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
            ),
          ),
          ...lines.map((l) {
            final isEnabled = enabledLineIds.contains(l.id);
            final isFocused = focusedLineId == l.id;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onLongPress: () => onLineToggled(l.id),
                child: FilterChip(
                  avatar: CircleAvatar(
                    backgroundColor: l.color,
                    radius: 9,
                  ),
                  label: Text(
                    'Línea ${l.number}',
                    style: TextStyle(
                      fontWeight: isFocused ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                  selected: isEnabled,
                  onSelected: (_) {
                    if (isFocused) {
                      onLineToggled(l.id);
                    } else {
                      onLineFocused(l.id);
                    }
                  },
                  selectedColor: isFocused ? l.color.withValues(alpha: 0.25) : Colors.grey.shade200,
                  labelStyle: TextStyle(
                    color: isFocused ? l.color.withValues(alpha: 0.95) : (isEnabled ? Colors.black87 : Colors.grey.shade600),
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.92),
                  side: BorderSide(
                    color: isFocused
                        ? l.color
                        : (isEnabled ? l.color.withValues(alpha: 0.4) : Colors.grey.shade300),
                    width: isFocused ? 2.0 : 1.2,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
