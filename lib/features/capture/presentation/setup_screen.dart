import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../database/database.dart';
import '../../transport/data/transport_repository.dart';
import '../../trips/data/trips_repository.dart';
import 'capture_notifier.dart';
import '../domain/capture_state.dart';
import '../../../core/permissions/permissions_handler.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  LineEntry? _selectedLine;
  BranchEntry? _selectedBranch;
  String _direction = 'IDA';

  final _internalController = TextEditingController();
  final _domainController = TextEditingController();
  final _driverController = TextEditingController();

  List<LineEntry> _lines = [];
  List<BranchEntry> _branches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransportData();
  }

  Future<void> _loadTransportData() async {
    final transportRepo = ref.read(transportRepositoryProvider);
    final lines = await transportRepo.getAllLines();
    if (lines.isNotEmpty) {
      final defaultLine = lines.first;
      final branches = await transportRepo.getBranchesForLine(defaultLine.id);
      setState(() {
        _lines = lines;
        _selectedLine = defaultLine;
        _branches = branches;
        _selectedBranch = branches.isNotEmpty ? branches.first : null;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }

    _loadLastTripConfig();
  }

  Future<void> _loadLastTripConfig() async {
    final tripsRepo = ref.read(tripsRepositoryProvider);
    final last = await tripsRepo.getLastTripConfig();
    if (last != null && mounted) {
      setState(() {
        _selectedLine = _lines.firstWhere((l) => l.id == last.line.id, orElse: () => _selectedLine ?? last.line);
        _direction = last.trip.direction;
        _internalController.text = last.trip.internalNumber ?? '';
        _domainController.text = last.trip.domain ?? '';
        _driverController.text = last.trip.driverName ?? '';
      });
      final branches = await ref.read(transportRepositoryProvider).getBranchesForLine(last.line.id);
      setState(() {
        _branches = branches;
        _selectedBranch = branches.firstWhere((b) => b.id == last.branch.id, orElse: () => _selectedBranch ?? last.branch);
      });
    }
  }

  Future<void> _onLineChanged(LineEntry? line) async {
    if (line == null) return;
    setState(() {
      _selectedLine = line;
      _isLoading = true;
    });
    final branches = await ref.read(transportRepositoryProvider).getBranchesForLine(line.id);
    setState(() {
      _branches = branches;
      _selectedBranch = branches.isNotEmpty ? branches.first : null;
      _isLoading = false;
    });
  }

  Future<void> _startCapture() async {
    if (_selectedLine == null || _selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione una Línea y Ramal')),
      );
      return;
    }

    final hasPerms = await AppPermissionsHandler.checkAndRequestLocationPermissions();
    if (!hasPerms) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se requiere permiso de ubicación en alta precisión')),
        );
      }
      return;
    }

    await AppPermissionsHandler.requestNotificationPermission();

    await ref.read(captureNotifierProvider.notifier).startCapture(
          line: _selectedLine!,
          branch: _selectedBranch!,
          direction: _direction,
          internalNumber: _internalController.text.trim().isNotEmpty ? _internalController.text.trim() : null,
          domain: _domainController.text.trim().isNotEmpty ? _domainController.text.trim() : null,
          driverName: _driverController.text.trim().isNotEmpty ? _driverController.text.trim() : null,
        );

    if (mounted) {
      context.go('/capture');
    }
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(captureNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus, size: 28),
            SizedBox(width: 8),
            Text('LANÚS DIGITAL', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'Ajustes',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Active trip recovery alert if applicable (Rule 20 & 87)
                  if (captureState.status == CaptureStatus.active || captureState.status == CaptureStatus.paused) ...[
                    Card(
                      color: Colors.amber.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning, color: Colors.amber),
                                SizedBox(width: 8),
                                Text(
                                  'SE ENCONTRÓ UNA CAPTURA EN CURSO',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${captureState.line?.number ?? ''} · ${captureState.branch?.name ?? ''} · ${captureState.direction}',
                              style: const TextStyle(color: Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                    onPressed: () => context.go('/capture'),
                                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                                    label: const Text('CONTINUAR', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      await ref.read(captureNotifierProvider.notifier).finishCapture();
                                    },
                                    icon: const Icon(Icons.stop, color: Colors.red),
                                    label: const Text('FINALIZAR', style: TextStyle(color: Colors.red)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Línea', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<LineEntry>(
                            value: _selectedLine,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: _lines.map((l) {
                              return DropdownMenuItem(value: l, child: Text(l.name));
                            }).toList(),
                            onChanged: _onLineChanged,
                          ),
                          const SizedBox(height: 16),

                          const Text('Ramal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<BranchEntry>(
                            value: _selectedBranch,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: _branches.map((b) {
                              return DropdownMenuItem(value: b, child: Text(b.name));
                            }).toList(),
                            onChanged: (b) => setState(() => _selectedBranch = b),
                          ),
                          const SizedBox(height: 20),

                          const Text('Sentido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(value: 'IDA', label: Text('IDA'), icon: Icon(Icons.east)),
                                    ButtonSegment(value: 'VUELTA', label: Text('VUELTA'), icon: Icon(Icons.west)),
                                  ],
                                  selected: {_direction},
                                  onSelectionChanged: (set) => setState(() => _direction = set.first),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _internalController,
                                  decoration: InputDecoration(
                                    labelText: 'Interno',
                                    hintText: 'Ej. 1234',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _domainController,
                                  decoration: InputDecoration(
                                    labelText: 'Dominio / Patente',
                                    hintText: 'Ej. AB123CD',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  textCapitalization: TextCapitalization.characters,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green.shade700,
                    ),
                    onPressed: _startCapture,
                    icon: const Icon(Icons.play_arrow, size: 28),
                    label: const Text('INICIAR CAPTURA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: _loadLastTripConfig,
                    icon: const Icon(Icons.history),
                    label: const Text('REPETIR ÚLTIMA CONFIGURACIÓN'),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (idx) {
          switch (idx) {
            case 0:
              break;
            case 1:
              context.push('/trips');
              break;
            case 2:
              context.push('/transport');
              break;
            case 3:
              context.push('/maps');
              break;
            case 4:
              context.push('/settings');
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.play_circle_outline), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Viajes'),
          NavigationDestination(icon: Icon(Icons.alt_route), label: 'Líneas'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Mapas'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
