import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/transport_repository.dart';
import '../../trips/data/trips_repository.dart';
import '../../../database/database.dart';

class TransportManagementScreen extends ConsumerStatefulWidget {
  const TransportManagementScreen({super.key});

  @override
  ConsumerState<TransportManagementScreen> createState() => _TransportManagementScreenState();
}

class _TransportManagementScreenState extends ConsumerState<TransportManagementScreen> {
  final _lineNumController = TextEditingController();
  final _lineNameController = TextEditingController();
  final _branchNameController = TextEditingController();

  void _showAddLineDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar Línea'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _lineNumController,
              decoration: const InputDecoration(labelText: 'Número (ej. 526)'),
            ),
            TextField(
              controller: _lineNameController,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          FilledButton(
            onPressed: () async {
              if (_lineNumController.text.isNotEmpty) {
                await ref.read(transportRepositoryProvider).addLine(
                      number: _lineNumController.text.trim(),
                      name: _lineNameController.text.trim().isNotEmpty
                          ? _lineNameController.text.trim()
                          : 'Línea ${_lineNumController.text.trim()}',
                    );
                _lineNumController.clear();
                _lineNameController.clear();
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  void _showAddBranchDialog(int lineId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar Ramal'),
        content: TextField(
          controller: _branchNameController,
          decoration: const InputDecoration(labelText: 'Nombre del ramal (ej. Hospital)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          FilledButton(
            onPressed: () async {
              if (_branchNameController.text.isNotEmpty) {
                await ref.read(transportRepositoryProvider).addBranch(
                      lineId: lineId,
                      name: _branchNameController.text.trim(),
                    );
                _branchNameController.clear();
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transportRepo = ref.watch(transportRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GESTIÓN DE LÍNEAS Y RAMALES'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLineDialog,
        icon: const Icon(Icons.add),
        label: const Text('NUEVA LÍNEA'),
      ),
      body: StreamBuilder<List<LineEntry>>(
        stream: transportRepo.watchAllLines(),
        builder: (context, snapshot) {
          final lines = snapshot.data ?? [];
          if (lines.isEmpty) {
            return const Center(child: Text('No hay líneas configuradas'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lines.length,
            itemBuilder: (context, idx) {
              final line = lines[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(
                    'Línea ${line.number} - ${line.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => transportRepo.deleteLine(line.id),
                  ),
                  children: [
                    StreamBuilder<List<BranchEntry>>(
                      stream: transportRepo.watchBranchesForLine(line.id),
                      builder: (context, bSnapshot) {
                        final branches = bSnapshot.data ?? [];
                        return Column(
                          children: [
                            ...branches.map((b) {
                              return FutureBuilder<BranchDirectionStatus>(
                                future: ref.read(tripsRepositoryProvider).getBranchDirectionStatus(line.id, b.id),
                                builder: (ctx, statusSnap) {
                                  final st = statusSnap.data;
                                  Color badgeColor = Colors.grey;
                                  String badgeText = 'Sin relevar';
                                  if (st != null) {
                                    if (st.isComplete) {
                                      badgeColor = Colors.green;
                                      badgeText = 'Completo (Ida y Vuelta)';
                                    } else if (st.hasAny) {
                                      badgeColor = Colors.orange;
                                      badgeText = st.hasIda ? 'Solo IDA' : 'Solo VUELTA';
                                    }
                                  }

                                  return ListTile(
                                    leading: Icon(
                                      Icons.circle,
                                      size: 12,
                                      color: badgeColor,
                                    ),
                                    title: Row(
                                      children: [
                                        Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: badgeColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            badgeText,
                                            style: TextStyle(fontSize: 10, color: badgeColor, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: b.description != null ? Text(b.description!) : null,
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () => transportRepo.deleteBranch(b.id),
                                    ),
                                  );
                                },
                              );
                            }),
                            ListTile(
                              leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
                              title: const Text('Agregar Ramal', style: TextStyle(color: Colors.blue)),
                              onTap: () => _showAddBranchDialog(line.id),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
