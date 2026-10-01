import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/transport_repository.dart';
import '../../trips/data/trips_repository.dart';
import '../../../database/database.dart';
import '../../../database/database_provider.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/utils/transport_utils.dart';

class TransportManagementScreen extends ConsumerStatefulWidget {
  const TransportManagementScreen({super.key});

  @override
  ConsumerState<TransportManagementScreen> createState() => _TransportManagementScreenState();
}

class _TransportManagementScreenState extends ConsumerState<TransportManagementScreen> {
  String _searchQuery = '';
  bool _isSyncing = false;

  void _showAddOrEditLineDialog({LineEntry? line}) {
    final numCtrl = TextEditingController(text: line?.number ?? '');
    final nameCtrl = TextEditingController(text: line?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(line == null ? 'Nueva Línea' : 'Editar Línea'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numCtrl,
              decoration: const InputDecoration(
                labelText: 'Número de Línea',
                hintText: 'Ej. 520, 526, 271',
                prefixIcon: Icon(Icons.pin),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre / Empresa',
                hintText: 'Ej. Micro Ómnibus Lanús',
                prefixIcon: Icon(Icons.directions_bus),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () async {
              final number = numCtrl.text.trim();
              final name = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Línea $number';
              if (number.isNotEmpty) {
                final repo = ref.read(transportRepositoryProvider);
                if (line == null) {
                  await repo.addLine(number: number, name: name);
                } else {
                  await repo.updateLine(lineId: line.id, number: number, name: name);
                }
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(line == null ? 'Línea agregada con éxito' : 'Línea actualizada')),
                  );
                }
              }
            },
            child: Text(line == null ? 'CREAR LÍNEA' : 'GUARDAR CAMBIOS'),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditBranchDialog({required int lineId, BranchEntry? branch}) {
    final nameCtrl = TextEditingController(text: branch?.name ?? '');
    final descCtrl = TextEditingController(text: branch?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(branch == null ? 'Nuevo Ramal' : 'Editar Ramal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del Ramal',
                hintText: 'Ej. Ramal A (Estación - Hospital)',
                prefixIcon: Icon(Icons.alt_route),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción / Destinos (Opcional)',
                hintText: 'Ej. Por Av. San Martín hasta Estación',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final desc = descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null;
              if (name.isNotEmpty) {
                final repo = ref.read(transportRepositoryProvider);
                if (branch == null) {
                  await repo.addBranch(lineId: lineId, name: name, description: desc);
                } else {
                  await repo.updateBranch(branchId: branch.id, name: name, description: desc);
                }
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(branch == null ? 'Ramal agregado' : 'Ramal actualizado')),
                  );
                }
              }
            },
            child: Text(branch == null ? 'AGREGAR RAMAL' : 'GUARDAR'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLine(LineEntry line) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text('Eliminar Línea ${line.number}'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas desactivar la Línea ${line.number} (${line.name})?\n\n'
          'Esta acción ocultará la línea y sus ramales del sistema.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(transportRepositoryProvider).deleteLine(line.id);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Línea ${line.number} eliminada')),
                );
              }
            },
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBranch(BranchEntry branch) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Eliminar Ramal'),
          ],
        ),
        content: Text('¿Deseas eliminar el ramal "${branch.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(transportRepositoryProvider).deleteBranch(branch.id);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ramal ${branch.name} eliminado')),
                );
              }
            },
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncLanusDigital() async {
    setState(() => _isSyncing = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sincronizando recorridos desde Lanús Digital...')),
    );
    try {
      final count = await SyncService.fetchBitacoraGpsSurveys(ref.read(databaseProvider));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sincronización completada ($count trazas sincronizadas)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al sincronizar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transportRepo = ref.watch(transportRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LÍNEAS Y RAMALES'),
        centerTitle: true,
        actions: [
          _isSyncing
              ? const Padding(
                  padding: EdgeInsets.all(14.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.cloud_sync_outlined),
                  tooltip: 'Sincronizar con Lanús Digital',
                  onPressed: _syncLanusDigital,
                ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Ver Mapa de Transporte',
            onPressed: () => context.go('/public-transit'),
          ),
          IconButton(
            icon: const Icon(Icons.timer_outlined),
            tooltip: 'Auditoría de Frecuencias',
            onPressed: () => context.push('/frequency'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditLineDialog(),
        icon: const Icon(Icons.add),
        label: const Text('NUEVA LÍNEA'),
      ),
      body: StreamBuilder<List<LineEntry>>(
        stream: transportRepo.watchAllLines(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rawLines = snapshot.data ?? [];
          final seenNumbers = <String>{};
          final allLines = rawLines.where((l) => seenNumbers.add(l.number.trim().toLowerCase())).toList();

          // Filter by search query
          final lines = allLines.where((l) {
            final query = _searchQuery.toLowerCase().trim();
            if (query.isEmpty) return true;
            return l.number.toLowerCase().contains(query) || l.name.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              // Compressed Search and Stats Bar
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
                        decoration: InputDecoration(
                          hintText: 'Buscar línea o ramal...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () => setState(() => _searchQuery = ''),
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
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Stats Summary row
                    Row(
                      children: [
                        _buildStatBadge(Icons.directions_bus, '${allLines.length} Líneas', Colors.blue),
                        const SizedBox(width: 6),
                        _buildStatBadge(Icons.alt_route, 'Red Activa', Colors.indigo),
                        const Spacer(),
                        Text(
                          '${lines.length} visibles',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content List (Compressed Spacing)
              Expanded(
                child: lines.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_bus_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty ? 'No hay líneas registradas' : 'No se encontraron resultados',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Pulsa en "+ NUEVA LÍNEA" o sincroniza con Lanús Digital'
                                    : 'Intenta con otro término de búsqueda',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                              if (_searchQuery.isEmpty) ...[
                                const SizedBox(height: 14),
                                OutlinedButton.icon(
                                  onPressed: _syncLanusDigital,
                                  icon: const Icon(Icons.cloud_sync, size: 18),
                                  label: const Text('SINCRONIZAR LANÚS DIGITAL'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 80),
                        itemCount: lines.length,
                        itemBuilder: (context, idx) {
                          final line = lines[idx];
                          return _buildLineCard(line, transportRepo);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildStatBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildLineCard(LineEntry line, TransportRepository transportRepo) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        dense: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 46,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TransportUtils.getLineColor(line.number),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            line.number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ),
        title: Text(
          line.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: StreamBuilder<List<BranchEntry>>(
          stream: transportRepo.watchBranchesForLineEntity(line),
          builder: (context, snap) {
            final count = snap.data?.length ?? 0;
            return Text(
              '$count ${count == 1 ? 'ramal' : 'ramales'}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            );
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'edit') {
                  _showAddOrEditLineDialog(line: line);
                } else if (val == 'add_branch') {
                  _showAddOrEditBranchDialog(lineId: line.id);
                } else if (val == 'delete') {
                  _confirmDeleteLine(line);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'add_branch',
                  child: Row(
                    children: [
                      Icon(Icons.add, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Text('Agregar Ramal'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Editar Línea'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Eliminar Línea', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          StreamBuilder<List<BranchEntry>>(
            stream: transportRepo.watchBranchesForLineEntity(line),
            builder: (context, bSnapshot) {
              final branches = bSnapshot.data ?? [];
              if (branches.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sin ramales para esta línea.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: () => _showAddOrEditBranchDialog(lineId: line.id),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('AGREGAR', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  ...branches.map((b) => _buildBranchTile(line, b, transportRepo)),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        icon: const Icon(Icons.add_circle_outline, size: 15),
                        label: const Text('Agregar otro ramal', style: TextStyle(fontSize: 11)),
                        onPressed: () => _showAddOrEditBranchDialog(lineId: line.id),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBranchTile(LineEntry line, BranchEntry branch, TransportRepository transportRepo) {
    return FutureBuilder<BranchDirectionStatus>(
      future: ref.read(tripsRepositoryProvider).getBranchDirectionStatus(line.id, branch.id),
      builder: (ctx, statusSnap) {
        final st = statusSnap.data;
        Color badgeColor = Colors.grey;
        String badgeText = 'Sin relevar';
        IconData badgeIcon = Icons.radio_button_unchecked;

        if (st != null) {
          if (st.isComplete) {
            badgeColor = const Color(0xFF16A34A);
            badgeText = 'Completo (Ida y Vuelta)';
            badgeIcon = Icons.check_circle;
          } else if (st.hasAny) {
            badgeColor = const Color(0xFFD97706);
            badgeText = st.hasIda ? 'Solo IDA' : 'Solo VUELTA';
            badgeIcon = Icons.timelapse;
          }
        }

        final hasRoutes = st != null && (st.hasIda || st.hasVuelta);

        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.08)),
            ),
          ),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            leading: Icon(badgeIcon, color: badgeColor, size: 16),
            title: Text(
              branch.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (branch.description != null && branch.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      branch.description!,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(fontSize: 9, color: badgeColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (st != null && st.isFromRemotePlatform) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_outlined, size: 9, color: Colors.blue),
                            SizedBox(width: 2),
                            Text('Lanús Digital', style: TextStyle(fontSize: 8, color: Colors.blue, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasRoutes)
                  IconButton(
                    icon: const Icon(Icons.map_outlined, color: Color(0xFF0284C7), size: 18),
                    tooltip: 'Ver recorrido',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      final routeId = st.referenceIdaRoute?.id ?? st.referenceVueltaRoute?.id;
                      if (routeId != null) {
                        context.push('/reference-routes/$routeId');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Recorrido disponible para ${line.number} - ${branch.name}')),
                        );
                      }
                    },
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showAddOrEditBranchDialog(lineId: line.id, branch: branch);
                    } else if (val == 'delete') {
                      _confirmDeleteBranch(branch);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
