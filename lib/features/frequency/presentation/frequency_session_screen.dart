import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../database/database.dart';
import '../../../database/database_provider.dart';
import '../data/frequency_repository.dart';
import '../domain/frequency_models.dart';
import '../domain/frequency_analytics.dart';

class FrequencySessionScreen extends ConsumerStatefulWidget {
  final int sessionId;
  const FrequencySessionScreen({super.key, required this.sessionId});

  @override
  ConsumerState<FrequencySessionScreen> createState() => _FrequencySessionScreenState();
}

class _FrequencySessionScreenState extends ConsumerState<FrequencySessionScreen> {
  FrequencySessionEntry? _session;
  List<LineEntry> _lines = [];
  List<BranchEntry> _branches = [];
  LineEntry? _selectedLine;
  BranchEntry? _selectedBranch;
  String _selectedDirection = 'IDA';
  int _selectedLoad = 2; // 1: Baja, 2: Media, 3: Alta, 4: Colapso
  final TextEditingController _internalController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Timer? _stopwatchTimer;
  Duration _elapsed = Duration.zero;
  Position? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startStopwatch();
    _fetchLocation();
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _internalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _startStopwatch() {
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_session != null && mounted) {
        final now = DateTime.now();
        final start = _session!.startedAt;
        setState(() {
          _elapsed = now.difference(start);
        });
      }
    });
  }

  Future<void> _fetchLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 5));
      if (mounted) setState(() => _currentPosition = pos);
    } catch (_) {}
  }

  Future<void> _loadInitialData() async {
    final repo = ref.read(frequencyRepositoryProvider);
    final db = ref.read(databaseProvider);

    final session = await repo.getSession(widget.sessionId);
    final lines = await (db.select(db.lines)..where((l) => l.active.equals(true))).get();

    LineEntry? selectedLine;
    List<BranchEntry> branches = [];
    BranchEntry? selectedBranch;

    if (lines.isNotEmpty) {
      selectedLine = lines.first;
      branches = await (db.select(db.branches)..where((b) => b.lineId.equals(selectedLine!.id))).get();
      if (branches.isNotEmpty) selectedBranch = branches.first;
    }

    if (mounted) {
      setState(() {
        _session = session;
        _lines = lines;
        _selectedLine = selectedLine;
        _branches = branches;
        _selectedBranch = selectedBranch;
        _isLoading = false;
      });
    }
  }

  Future<void> _onLineChanged(LineEntry line) async {
    final db = ref.read(databaseProvider);
    final branches = await (db.select(db.branches)..where((b) => b.lineId.equals(line.id))).get();

    setState(() {
      _selectedLine = line;
      _branches = branches;
      _selectedBranch = branches.isNotEmpty ? branches.first : null;
    });
  }

  Future<void> _logBusPass() async {
    if (_selectedLine == null || _selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una línea y ramal')),
      );
      return;
    }

    final repo = ref.read(frequencyRepositoryProvider);
    final internal = _internalController.text.trim();
    final notes = _notesController.text.trim();

    await repo.logBusPass(
      sessionId: widget.sessionId,
      lineId: _selectedLine!.id,
      branchId: _selectedBranch!.id,
      direction: _selectedDirection,
      internalNumber: internal.isNotEmpty ? internal : null,
      passengerLoad: _selectedLoad,
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
      notes: notes.isNotEmpty ? notes : null,
    );

    _internalController.clear();
    _notesController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paso registrado: Línea ${_selectedLine!.number} ($_selectedDirection)'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF0284C7),
        ),
      );
    }
  }

  Future<void> _confirmFinishSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Finalizar Auditoría de Frecuencias'),
        content: const Text(
          '¿Deseas cerrar la toma de datos en este punto de control y generar el informe oficial de servicio?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CONTINUAR RELEVANDO')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('FINALIZAR E INFORMAR'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(frequencyRepositoryProvider);
      await repo.finishSession(widget.sessionId);
      if (mounted) {
        context.pushReplacement('/frequency/report/${widget.sessionId}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando aforo...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sesión no encontrada')),
        body: const Center(child: Text('No existe la sesión de aforo solicitada.')),
      );
    }

    final repo = ref.watch(frequencyRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_session!.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment_outlined),
            tooltip: 'Ver informe actual',
            onPressed: () => context.push('/frequency/report/${widget.sessionId}'),
          ),
        ],
      ),
      body: StreamBuilder<List<FrequencyRecordWithDetails>>(
        stream: repo.watchSessionRecords(widget.sessionId),
        builder: (context, snapshot) {
          final records = snapshot.data ?? [];

          return Column(
            children: [
              // HUD Header with Chronometer & Counts
              _buildHudHeader(records.length),

              // Recording Fast-Pad Card
              _buildRecordingPad(),

              // Live Sightings Section Header
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'PASOS REGISTRADOS EN VIVO (${records.length})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Records Timeline List
              Expanded(
                child: records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_bus_filled_outlined, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'Aún no hay unidades registradas',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Presiona "REGISTRAR PASO DE UNIDAD" al ver pasar un colectivo.',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: records.length,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemBuilder: (context, index) {
                          final item = records[index];
                          return _buildRecordItemCard(item, repo);
                        },
                      ),
              ),

              // Bottom Action Bar to Finish & Generate Report
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -1))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                        ),
                        onPressed: () => context.push('/frequency/report/${widget.sessionId}'),
                        icon: const Icon(Icons.insights, size: 18),
                        label: const Text('VER REPORTE EN VIVO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          backgroundColor: const Color(0xFF0369A1),
                        ),
                        onPressed: _confirmFinishSession,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('FINALIZAR AFORO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHudHeader(int totalCount) {
    final hours = _elapsed.inHours.toString().padLeft(2, '0');
    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final elapsedStr = '$hours:$minutes:$seconds';

    final durationHours = mathMax(1, _elapsed.inSeconds) / 3600.0;
    final vehPerHour = durationHours > 0 ? (totalCount / durationHours).toStringAsFixed(1) : '0.0';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: const Color(0xFF0F172A),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TIEMPO DE CONTROL', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                  Text(elapsedStr, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                ],
              ),
            ],
          ),
          Container(
            height: 28,
            width: 1,
            color: Colors.white24,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('UNIDADES VISTAS', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
              Text('$totalCount veh.', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
            ],
          ),
          Container(
            height: 28,
            width: 1,
            color: Colors.white24,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('FRECUENCIA REAL', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
              Text('$vehPerHour v/h', style: const TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  int mathMax(int a, int b) => a > b ? a : b;

  Widget _buildRecordingPad() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lines Horizontal Quick Bar
            Row(
              children: [
                const Icon(Icons.directions_bus, size: 16, color: Color(0xFF0284C7)),
                const SizedBox(width: 6),
                const Text('LÍNEA:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _lines.map((l) {
                        final isSel = _selectedLine?.id == l.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(l.number, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSel ? Colors.white : Colors.black87)),
                            selected: isSel,
                            selectedColor: const Color(0xFF0284C7),
                            visualDensity: VisualDensity.compact,
                            onSelected: (_) => _onLineChanged(l),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Branches Dropdown & Direction Toggle
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<BranchEntry>(
                    value: _selectedBranch,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'Ramal',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: _branches.map((b) {
                      return DropdownMenuItem(
                        value: b,
                        child: Text(b.name, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (b) => setState(() => _selectedBranch = b),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'IDA', label: Text('IDA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                      ButtonSegment(value: 'VTA', label: Text('VTA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                    ],
                    selected: {_selectedDirection == 'IDA' ? 'IDA' : 'VTA'},
                    onSelectionChanged: (set) {
                      setState(() {
                        _selectedDirection = set.first == 'IDA' ? 'IDA' : 'VUELTA';
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Passenger Load (Ocupación) & Internal (Coche)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      const Text('Carga:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(width: 4),
                      _buildLoadChip(1, 'Baja', Icons.person_outline),
                      _buildLoadChip(2, 'Media', Icons.people_outline),
                      _buildLoadChip(3, 'Alta', Icons.groups_outlined),
                      _buildLoadChip(4, 'Full', Icons.warning_amber_outlined),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _internalController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'Coche / Int.',
                      hintText: 'Ej. 42',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Primary Huge Action Button
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFF0284C7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _logBusPass,
              icon: const Icon(Icons.touch_app, size: 22),
              label: const Text(
                'REGISTRAR PASO DE UNIDAD (AHORA)',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadChip(int value, String label, IconData icon) {
    final isSel = _selectedLoad == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedLoad = value),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF0F172A) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSel ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isSel ? Colors.white : Colors.grey.shade800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordItemCard(FrequencyRecordWithDetails item, FrequencyRepository repo) {
    final rec = item.record;
    final isBunching = rec.isBunching;
    final isDelayed = rec.isDelayed;

    final badgeColor = isBunching
        ? Colors.amber.shade700
        : (isDelayed ? Colors.red.shade700 : const Color(0xFF059669));

    final timeStr = '${rec.observedAt.hour.toString().padLeft(2, '0')}:${rec.observedAt.minute.toString().padLeft(2, '0')}:${rec.observedAt.second.toString().padLeft(2, '0')}';

    return Card(
      elevation: 0.8,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.line.number,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
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
                          '${item.branch.name} · ${rec.direction}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (rec.internalNumber != null)
                        Text(
                          'Coche #${rec.internalNumber} · ',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                        ),
                      Text(
                        FrequencyAnalytics.formatLoad(rec.passengerLoad),
                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    FrequencyAnalytics.formatHeadway(rec.headwaySeconds),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: badgeColor),
                  ),
                  if (isBunching)
                    Text('Acolchonado', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: badgeColor)),
                  if (isDelayed)
                    Text('Demorado', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: badgeColor)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
              tooltip: 'Borrar registro',
              visualDensity: VisualDensity.compact,
              onPressed: () => repo.deleteRecord(rec.id),
            ),
          ],
        ),
      ),
    );
  }
}
